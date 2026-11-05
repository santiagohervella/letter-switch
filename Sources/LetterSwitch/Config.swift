import Foundation
import Yams

struct Config: Decodable {
    static let directory = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config/letter-switch")
    static let file = directory.appending(path: "config.yaml")

    let modifier: Modifier
    let showNoAppsMessage: Bool
    let apps: [String: AppSettings]

    init(modifier: Modifier = .rightOption, showNoAppsMessage: Bool = false, apps: [String: AppSettings] = [:]) {
        self.modifier = modifier
        self.showNoAppsMessage = showNoAppsMessage
        self.apps = apps
    }

    init(from decoder: Decoder) throws {
        try decoder.rejectUnknownKeys(allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modifier = try container.decodeIfPresent(Modifier.self, forKey: .modifier) ?? .rightOption
        showNoAppsMessage = try container.decodeIfPresent(Bool.self, forKey: .showNoAppsMessage) ?? false
        apps = try container.decodeIfPresent([String: AppSettings].self, forKey: .apps) ?? [:]
    }

    static func load() -> Config? {
        guard let contents = try? String(contentsOf: file, encoding: .utf8) else {
            log.info("no config at \(file.path, privacy: .public), using defaults")
            return Config()
        }
        guard !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Config()
        }
        do {
            return try YAMLDecoder().decode(Config.self, from: contents)
        } catch {
            log.error("invalid config, keeping previous: \(describe(error), privacy: .public)")
            return nil
        }
    }

    private static func describe(_ error: Error) -> String {
        if case DecodingError.dataCorrupted(let context) = error, let configError = context.underlyingError as? ConfigError {
            return configError.description
        }
        return String(describing: error)
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case modifier
        case showNoAppsMessage = "show_no_apps_message"
        case apps
    }
}

struct AppSettings: Decodable {
    let keys: Set<Character>?
    let launch: Bool

    init(from decoder: Decoder) throws {
        try decoder.rejectUnknownKeys(allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decodeIfPresent([String].self, forKey: .keys).map { values in
            Set(try values.map { try Self.switchKey($0, decoder) })
        }
        launch = try container.decodeIfPresent(Bool.self, forKey: .launch) ?? false
    }

    private static func switchKey(_ value: String, _ decoder: Decoder) throws -> Character {
        guard value.count == 1, let key = value.lowercased().first, SwitchKey.isValid(key) else {
            throw ConfigError(decoder, "key \"\(value)\" must be a single letter or digit")
        }
        return key
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case keys
        case launch
    }
}

struct ConfigError: Error, CustomStringConvertible {
    let description: String

    init(_ decoder: Decoder, _ message: String) {
        let path = decoder.codingPath.map(\.stringValue).joined(separator: ".")
        description = path.isEmpty ? message : "\(path): \(message)"
    }
}

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}

private extension Decoder {
    func rejectUnknownKeys(allowed: [String]) throws {
        let unknown = try container(keyedBy: AnyCodingKey.self).allKeys
            .map(\.stringValue)
            .filter { !allowed.contains($0) }
            .sorted()
        guard unknown.isEmpty else {
            throw ConfigError(self, "unknown setting \(unknown.joined(separator: ", "))")
        }
    }
}

final class ConfigWatcher {
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func start() {
        watch()
    }

    private func watch() {
        source?.cancel()

        let fileExists = FileManager.default.fileExists(atPath: Config.file.path)
        let path = fileExists ? Config.file.path : Config.directory.path
        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else {
            log.info("not watching \(path, privacy: .public), it is missing")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self, unowned source] in
            if !fileExists || !source.data.isDisjoint(with: [.delete, .rename]) {
                self?.watch()
            }
            self?.onChange()
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
    }
}

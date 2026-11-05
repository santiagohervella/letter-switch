import Foundation
import TOMLKit

struct Config: Decodable {
    static let directory = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config/letter-switch")
    static let file = directory.appending(path: "config.toml")

    let modifier: Modifier
    let pins: [String: String]

    init(modifier: Modifier = .rightOption, pins: [String: String] = [:]) {
        self.modifier = modifier
        self.pins = pins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modifier = try container.decodeIfPresent(Modifier.self, forKey: .modifier) ?? .rightOption
        pins = try container.decodeIfPresent([String: String].self, forKey: .pins) ?? [:]
    }

    static func load() -> Config? {
        guard let contents = try? String(contentsOf: file, encoding: .utf8) else {
            log.info("no config at \(file.path, privacy: .public), using defaults")
            return Config()
        }
        do {
            return try TOMLDecoder().decode(Config.self, from: contents)
        } catch {
            log.error("invalid config, keeping previous: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case modifier
        case pins
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

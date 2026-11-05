import Foundation
import TOMLKit

struct Config: Decodable {
    static let directory = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config/letter-switch")
    static let file = directory.appending(path: "config.toml")

    let pins: [String: String]

    init(pins: [String: String] = [:]) {
        self.pins = pins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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

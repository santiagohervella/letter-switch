import AppKit

struct KeyAssignments {
    private let bundleIDByKey: [Character: String]
    private let keyByBundleID: [String: Character]

    var count: Int {
        bundleIDByKey.count
    }

    init(pins: [String: String] = [:]) {
        bundleIDByKey = pins.reduce(into: [:]) { pinned, pin in
            guard pin.key.count == 1, let key = pin.key.lowercased().first, Self.isSwitchKey(key) else {
                log.error("ignoring pin \(pin.key, privacy: .public): key must be a single letter or digit")
                return
            }
            pinned[key] = pin.value
        }
        keyByBundleID = Dictionary(bundleIDByKey.map { ($1, $0) }) { first, _ in first }
    }

    func key(for app: NSRunningApplication) -> Character? {
        if let bundleID = app.bundleIdentifier, let key = keyByBundleID[bundleID] {
            return key
        }
        guard let first = app.localizedName?.lowercased().first, Self.isSwitchKey(first) else { return nil }
        return first
    }

    func pinnedBundleID(for key: Character) -> String? {
        bundleIDByKey[key]
    }

    private static func isSwitchKey(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }
}

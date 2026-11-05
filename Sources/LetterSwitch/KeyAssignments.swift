import AppKit

struct KeyAssignments {
    private let keyByBundleID: [String: Character]

    var count: Int {
        keyByBundleID.count
    }

    init(pins: [String: String] = [:]) {
        keyByBundleID = pins.reduce(into: [:]) { keys, pin in
            guard pin.key.count == 1, let key = pin.key.lowercased().first, Self.isSwitchKey(key) else {
                log.error("ignoring pin \(pin.key, privacy: .public): key must be a single letter or digit")
                return
            }
            keys[pin.value] = key
        }
    }

    func key(for app: NSRunningApplication) -> Character? {
        if let bundleID = app.bundleIdentifier, let key = keyByBundleID[bundleID] {
            return key
        }
        guard let first = app.localizedName?.lowercased().first, Self.isSwitchKey(first) else { return nil }
        return first
    }

    private static func isSwitchKey(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }
}

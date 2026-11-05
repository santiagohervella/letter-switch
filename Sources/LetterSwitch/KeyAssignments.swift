import AppKit

struct KeyAssignments {
    private let keysByBundleID: [String: Set<Character>]
    private let launchBundleIDByKey: [Character: String]

    init(apps: [String: AppSettings] = [:]) {
        keysByBundleID = apps.compactMapValues(\.keys)

        let launchCandidates = apps
            .filter(\.value.launch)
            .flatMap { bundleID, settings in
                (settings.keys ?? Self.installedFirstLetter(bundleID)).map { (key: $0, bundleID: bundleID) }
            }

        launchBundleIDByKey = Dictionary(grouping: launchCandidates, by: \.key).compactMapValues { candidates in
            guard candidates.count == 1 else {
                let bundleIDs = candidates.map(\.bundleID).sorted().joined(separator: ", ")
                log.error("not launching on \(String(candidates[0].key), privacy: .public): \(bundleIDs, privacy: .public) all launch on it")
                return nil
            }
            return candidates[0].bundleID
        }
    }

    func keys(for app: NSRunningApplication) -> Set<Character> {
        if let bundleID = app.bundleIdentifier, let keys = keysByBundleID[bundleID] {
            return keys
        }
        return SwitchKey.firstLetter(of: app.localizedName).map { [$0] } ?? []
    }

    func launchBundleID(for key: Character) -> String? {
        launchBundleIDByKey[key]
    }

    private static func installedFirstLetter(_ bundleID: String) -> Set<Character> {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            log.error("not launching \(bundleID, privacy: .public): app not installed")
            return []
        }
        let bundle = Bundle(url: url)
        let name = ["CFBundleDisplayName", "CFBundleName"]
            .lazy
            .compactMap { bundle?.object(forInfoDictionaryKey: $0) as? String }
            .first ?? url.deletingPathExtension().lastPathComponent
        return SwitchKey.firstLetter(of: name).map { [$0] } ?? []
    }
}

enum SwitchKey {
    static func isValid(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }

    static func firstLetter(of name: String?) -> Character? {
        guard let first = name?.lowercased().first, isValid(first) else { return nil }
        return first
    }
}

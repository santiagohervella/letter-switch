import AppKit

protocol SwitchableApp {
    var processIdentifier: pid_t { get }
    var bundleIdentifier: String? { get }
    var localizedName: String? { get }
    var isTerminated: Bool { get }
}

extension NSRunningApplication: SwitchableApp {}

struct Cycle<App: SwitchableApp> {
    let key: Character
    let apps: [App]
    let target: App

    static func next(key: Character, recent: [App], previous: Cycle?, assignments: KeyAssignments) -> Cycle? {
        let current = recent.first
        let continued = previous.flatMap { $0.key == key && $0.target.processIdentifier == current?.processIdentifier ? $0 : nil }
        let apps = (continued?.apps ?? recent.filter { assignments.keys(for: $0).contains(key) })
            .filter { !$0.isTerminated }

        guard !apps.isEmpty else { return nil }

        let currentIndex = apps.firstIndex { $0.processIdentifier == current?.processIdentifier } ?? -1
        return Cycle(key: key, apps: apps, target: apps[(currentIndex + 1) % apps.count])
    }
}

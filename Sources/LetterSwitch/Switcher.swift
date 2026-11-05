import AppKit

final class Switcher {
    private struct Cycle {
        let key: Character
        let apps: [NSRunningApplication]
        let target: NSRunningApplication
    }

    private let tracker: AppTracker
    private let focuser = Focuser()
    private let launcher = Launcher()
    private let hud = HUD()
    private var assignments = KeyAssignments()
    private var showNoAppsMessage = false
    private var cycle: Cycle?

    init(tracker: AppTracker) {
        self.tracker = tracker
    }

    func apply(_ config: Config) {
        assignments = KeyAssignments(apps: config.apps)
        showNoAppsMessage = config.showNoAppsMessage
        cycle = nil
        log.info("applied config with \(config.apps.count) apps")
    }

    func switchTo(_ key: Character) {
        let current = tracker.recent.first
        let apps = (continuedCycle(key, current)?.apps ?? tracker.recent.filter { assignments.keys(for: $0).contains(key) })
            .filter { !$0.isTerminated }

        guard !apps.isEmpty else {
            launchApp(key)
            return
        }

        let currentIndex = apps.firstIndex { $0.processIdentifier == current?.processIdentifier } ?? -1
        let target = apps[(currentIndex + 1) % apps.count]

        log.debug("\(String(key), privacy: .public) -> \(target.localizedName ?? "?", privacy: .public)")
        cycle = Cycle(key: key, apps: apps, target: target)
        tracker.moveToFront(target)
        focuser.focus(target)
    }

    private func launchApp(_ key: Character) {
        guard let bundleID = assignments.launchBundleID(for: key) else {
            log.debug("no apps for \(String(key), privacy: .public)")
            if showNoAppsMessage {
                hud.show("No apps for '\(key.uppercased())'")
            }
            return
        }
        cycle = nil
        launcher.launch(bundleID)
    }

    private func continuedCycle(_ key: Character, _ current: NSRunningApplication?) -> Cycle? {
        guard let cycle, cycle.key == key, cycle.target.processIdentifier == current?.processIdentifier else { return nil }
        return cycle
    }
}

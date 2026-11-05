import AppKit

final class Switcher {
    private let tracker: AppTracker
    private let focuser = Focuser()
    private let launcher = Launcher()
    private let hud = HUD()
    private var assignments = KeyAssignments()
    private var showNoAppsMessage = false
    private var hideOtherApps = false
    private var cycle: Cycle<NSRunningApplication>?

    init(tracker: AppTracker) {
        self.tracker = tracker
    }

    func apply(_ config: Config) {
        assignments = KeyAssignments(apps: config.apps)
        showNoAppsMessage = config.showNoAppsMessage
        hideOtherApps = config.hideOtherApps
        cycle = nil
        log.info("applied config with \(config.apps.count) apps")
    }

    func switchTo(_ key: Character) {
        guard let next = Cycle.next(key: key, recent: tracker.recent, previous: cycle, assignments: assignments) else {
            launchApp(key)
            return
        }

        let target = next.target
        log.debug("\(String(key), privacy: .public) -> \(target.localizedName ?? "?", privacy: .public)")
        cycle = next
        tracker.moveToFront(target)
        focuser.focus(target)
        hideApps(except: target)
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
        launcher.launch(bundleID) { [weak self] app in self?.hideApps(except: app) }
    }

    private func hideApps(except target: NSRunningApplication) {
        guard hideOtherApps else { return }
        tracker.recent
            .filter { $0.processIdentifier != target.processIdentifier && !$0.isHidden }
            .forEach { $0.hide() }
    }
}

import AppKit

final class AppTracker {
    private(set) var recent: [NSRunningApplication] = []

    private let workspace = NSWorkspace.shared
    private var runningObservation: NSKeyValueObservation?
    private var policyObservations: [pid_t: NSKeyValueObservation] = [:]
    private var activationObserver: NSObjectProtocol?

    func start() {
        runningObservation = workspace.observe(\.runningApplications, options: [.initial]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.sync() }
        }
        activationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.sync()
            self?.moveToFront(app)
        }
        sync()
        workspace.frontmostApplication.map(moveToFront)
    }

    func moveToFront(_ app: NSRunningApplication) {
        guard isSwitchable(app) else { return }
        recent.removeAll { $0.processIdentifier == app.processIdentifier }
        recent.insert(app, at: 0)
    }

    private func sync() {
        let running = workspace.runningApplications
        observePolicies(of: running)

        let switchable = running.filter(isSwitchable)
        let switchablePIDs = Set(switchable.map(\.processIdentifier))
        recent.removeAll { !switchablePIDs.contains($0.processIdentifier) }

        let knownPIDs = Set(recent.map(\.processIdentifier))
        recent.append(contentsOf: switchable.filter { !knownPIDs.contains($0.processIdentifier) })
    }

    private func observePolicies(of running: [NSRunningApplication]) {
        let runningPIDs = Set(running.map(\.processIdentifier))
        policyObservations = policyObservations.filter { runningPIDs.contains($0.key) }

        running
            .filter { policyObservations[$0.processIdentifier] == nil }
            .forEach { app in
                policyObservations[app.processIdentifier] = app.observe(\.activationPolicy) { [weak self] _, _ in
                    DispatchQueue.main.async { self?.sync() }
                }
            }
    }

    private func isSwitchable(_ app: NSRunningApplication) -> Bool {
        app.activationPolicy == .regular && !app.isTerminated && app.processIdentifier != getpid()
    }
}

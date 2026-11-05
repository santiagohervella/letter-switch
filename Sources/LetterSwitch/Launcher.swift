import AppKit

final class Launcher {
    private var launching = Set<String>()

    func launch(_ bundleID: String) {
        guard !launching.contains(bundleID) else {
            log.debug("already launching \(bundleID, privacy: .public)")
            return
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            log.error("no app installed for pinned \(bundleID, privacy: .public)")
            return
        }

        log.debug("launching \(bundleID, privacy: .public)")
        launching.insert(bundleID)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.launching.remove(bundleID)
                if let error {
                    log.error("failed to launch \(bundleID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}

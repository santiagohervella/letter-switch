import AppKit
import Carbon.HIToolbox

enum SecureInput {
    static func owner() -> String? {
        guard IsSecureEventInputEnabled(),
              let session = CGSessionCopyCurrentDictionary() as? [String: Any],
              let pid = session["kCGSSessionSecureInputPID"] as? pid_t
        else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.localizedName ?? "process \(pid)"
    }
}

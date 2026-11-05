import Foundation

enum LoginItem {
    static let label = "com.santiagohervella.letter-switch"

    private static let agentURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/LaunchAgents/\(label).plist")
    private static let domain = "gui/\(getuid())"

    static var isRunningAsAgent: Bool {
        ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == label
    }

    static func install() {
        do {
            try FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try PropertyListSerialization.data(fromPropertyList: agent, format: .xml, options: 0).write(to: agentURL)
            launchctl("bootout", "\(domain)/\(label)")
            launchctl("bootstrap", domain, agentURL.path)
            log.info("installed login item at \(agentURL.path, privacy: .public)")
        } catch {
            log.error("failed to install login item: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static var agent: [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [Bundle.main.executablePath ?? CommandLine.arguments[0]],
            "RunAtLoad": true,
            "KeepAlive": ["SuccessfulExit": false],
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",
        ]
    }

    private static func launchctl(_ arguments: String...) {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/launchctl")
        process.arguments = arguments
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}

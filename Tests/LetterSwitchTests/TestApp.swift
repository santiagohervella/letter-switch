import Foundation
@testable import LetterSwitch

struct TestApp: SwitchableApp, Equatable {
    let processIdentifier: pid_t
    let localizedName: String?
    let bundleIdentifier: String?
    let isTerminated: Bool

    init(_ processIdentifier: pid_t, _ name: String, bundleIdentifier: String? = nil, isTerminated: Bool = false) {
        self.processIdentifier = processIdentifier
        self.localizedName = name
        self.bundleIdentifier = bundleIdentifier
        self.isTerminated = isTerminated
    }
}

func assignments(_ yaml: String) throws -> KeyAssignments {
    KeyAssignments(apps: try Config.parse(yaml).apps)
}

import Testing
@testable import LetterSwitch

struct KeyAssignmentsTests {
    @Test func unconfiguredAppsAnswerToTheirFirstLetter() {
        let assignments = KeyAssignments()
        #expect(assignments.keys(for: TestApp(1, "Ghostty")) == ["g"])
        #expect(assignments.keys(for: TestApp(2, "1Password")) == ["1"])
        #expect(assignments.keys(for: TestApp(3, "Éclair")).isEmpty)
    }

    @Test func configuredKeysReplaceTheFirstLetter() throws {
        let assignments = try assignments("apps:\n  com.example.ghostty:\n    keys: [i, t]")
        #expect(assignments.keys(for: TestApp(1, "Ghostty", bundleIdentifier: "com.example.ghostty")) == ["i", "t"])
    }

    @Test func appNamesResolveToBundleIDs() throws {
        let assignments = try assignments("apps:\n  Messages:\n    keys: [x]")
        #expect(assignments.keys(for: TestApp(1, "Messages", bundleIdentifier: "com.apple.MobileSMS")) == ["x"])
    }

    @Test func launchesFromConfiguredKeys() throws {
        let assignments = try assignments("apps:\n  com.example.ghostty:\n    keys: [g, i]\n    launch: true")
        #expect(assignments.launchBundleID(for: "g") == "com.example.ghostty")
        #expect(assignments.launchBundleID(for: "i") == "com.example.ghostty")
    }

    @Test func launchesFromTheInstalledAppsFirstLetter() throws {
        let assignments = try assignments("apps:\n  Messages:\n    launch: true")
        #expect(assignments.launchBundleID(for: "m") == "com.apple.MobileSMS")
    }

    @Test func switchingKeysAloneDoNotLaunch() throws {
        let assignments = try assignments("apps:\n  com.example.ghostty:\n    keys: [g]")
        #expect(assignments.launchBundleID(for: "g") == nil)
    }

    @Test func conflictingLaunchKeysLaunchNothing() throws {
        let assignments = try assignments("""
            apps:
              com.example.ghostty:
                keys: [g, i]
                launch: true
              com.example.glide:
                keys: [g]
                launch: true
            """)
        #expect(assignments.launchBundleID(for: "g") == nil)
        #expect(assignments.launchBundleID(for: "i") == "com.example.ghostty")
    }
}

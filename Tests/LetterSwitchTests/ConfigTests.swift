import Testing
@testable import LetterSwitch

struct ConfigTests {
    private func error(parsing yaml: String) -> String? {
        do {
            _ = try Config.parse(yaml)
            return nil
        } catch {
            return Config.describe(error)
        }
    }

    @Test func emptyFileUsesDefaults() throws {
        let config = try Config.parse("\n  \n")
        #expect(config.modifier == .rightOption)
        #expect(!config.showNoAppsMessage)
        #expect(!config.hideOtherApps)
        #expect(config.apps.isEmpty)
    }

    @Test func parsesEverySetting() throws {
        let config = try Config.parse("""
            modifier: left_command
            show_no_apps_message: true
            hide_other_apps: true

            apps:
              Ghostty:
                keys: [g, i]
                launch: true
              Arc:
                launch: true
            """)
        #expect(config.modifier == .leftCommand)
        #expect(config.showNoAppsMessage)
        #expect(config.hideOtherApps)
        #expect(config.apps["Ghostty"]?.keys == ["g", "i"])
        #expect(config.apps["Ghostty"]?.launch == true)
        #expect(config.apps["Arc"]?.keys == nil)
        #expect(config.apps["Arc"]?.launch == true)
    }

    @Test func lowercasesKeys() throws {
        let config = try Config.parse("apps:\n  Ghostty:\n    keys: [G]")
        #expect(config.apps["Ghostty"]?.keys == ["g"])
    }

    @Test func keepsYAMLBooleanLookalikesAsKeys() throws {
        let config = try Config.parse("apps:\n  Ghostty:\n    keys: [y, n, 1]")
        #expect(config.apps["Ghostty"]?.keys == ["y", "n", "1"])
    }

    @Test func rejectsUnknownSettings() {
        #expect(error(parsing: "hide_others: true") == "unknown setting hide_others")
        #expect(error(parsing: "apps:\n  Ghostty:\n    lanch: true") == "apps.Ghostty: unknown setting lanch")
    }

    @Test(arguments: ["gg", "-", "é"])
    func rejectsInvalidKeys(key: String) {
        #expect(error(parsing: "apps:\n  Ghostty:\n    keys: [\"\(key)\"]")?.contains("key \"\(key)\" must be a single letter or digit") == true)
    }

    @Test func rejectsUnknownModifiers() {
        #expect(error(parsing: "modifier: hyper") != nil)
    }
}

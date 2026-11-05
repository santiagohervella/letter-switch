import AppKit

let tracker = AppTracker()
let switcher = Switcher(tracker: tracker)
let keyTap = KeyTap { switcher.switchTo($0) }
let configWatcher = ConfigWatcher { Config.load().map(switcher.apply) }

func startKeyTapWhenTrusted() {
    guard AXIsProcessTrusted(), keyTap.start() else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: startKeyTapWhenTrusted)
        return
    }
    log.info("key tap started")
}

Config.load().map(switcher.apply)
configWatcher.start()
tracker.start()
AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
startKeyTapWhenTrusted()
log.info("started")
NSApplication.shared.run()

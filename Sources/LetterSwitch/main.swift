import AppKit

guard LoginItem.isRunningAsAgent else {
    LoginItem.install()
    exit(0)
}

let tracker = AppTracker()
let switcher = Switcher(tracker: tracker)
let keyTap = KeyTap(onKey: { switcher.switchTo($0) }, onHide: { switcher.hideFrontmost() })
let configWatcher = ConfigWatcher { Config.load().map(apply) }

func apply(_ config: Config) {
    keyTap.modifier = config.modifier
    keyTap.interceptsHide = config.hideOtherApps
    switcher.apply(config)
    log.info("modifier is \(config.modifier.rawValue, privacy: .public)")
}

func startKeyTapWhenTrusted() {
    guard AXIsProcessTrusted(), keyTap.start() else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: startKeyTapWhenTrusted)
        return
    }
    log.info("key tap started")
}

Config.load().map(apply)
configWatcher.start()
tracker.start()
AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
startKeyTapWhenTrusted()
log.info("started")
NSApplication.shared.run()

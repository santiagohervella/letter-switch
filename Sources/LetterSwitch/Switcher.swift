import AppKit

final class Switcher {
    private struct Cycle {
        let key: Character
        let apps: [NSRunningApplication]
        let target: NSRunningApplication
    }

    private let tracker: AppTracker
    private let focuser = Focuser()
    private var cycle: Cycle?

    init(tracker: AppTracker) {
        self.tracker = tracker
    }

    func switchTo(_ key: Character) {
        let current = tracker.recent.first
        let apps = (continuedCycle(key, current)?.apps ?? tracker.recent.filter { $0.switchKey == key })
            .filter { !$0.isTerminated }

        guard !apps.isEmpty else {
            log.debug("no apps for \(String(key))")
            return
        }

        let currentIndex = apps.firstIndex { $0.processIdentifier == current?.processIdentifier } ?? -1
        let target = apps[(currentIndex + 1) % apps.count]

        log.debug("\(String(key)) -> \(target.localizedName ?? "?", privacy: .public)")
        cycle = Cycle(key: key, apps: apps, target: target)
        tracker.moveToFront(target)
        focuser.focus(target)
    }

    private func continuedCycle(_ key: Character, _ current: NSRunningApplication?) -> Cycle? {
        guard let cycle, cycle.key == key, cycle.target.processIdentifier == current?.processIdentifier else { return nil }
        return cycle
    }
}

extension NSRunningApplication {
    var switchKey: Character? {
        guard let first = localizedName?.lowercased().first, first.isASCII, first.isLetter || first.isNumber else { return nil }
        return first
    }
}

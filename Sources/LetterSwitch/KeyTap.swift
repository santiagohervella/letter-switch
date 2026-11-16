import AppKit
import Carbon.HIToolbox
import os

final class KeyTap: NSObject {
    private static let doubleTapInterval: TimeInterval = 0.3

    private let onKey: (Character, Bool) -> Void
    private let onPress: () -> Void
    private let onHide: () -> Void
    private let currentModifier = OSAllocatedUnfairLock(initialState: Modifier.rightOption)
    private let hideInterception = OSAllocatedUnfairLock(initialState: false)
    private let characters = OSAllocatedUnfairLock(initialState: KeyLayout.characters())
    private var tap: CFMachPort?
    private var swallowedKeyCodes = Set<Int64>()
    private var pressedAt: TimeInterval?
    private var lastTapAt: TimeInterval?
    private var pressIsDoubleTap = false
    private var pressWasUsed = false

    var modifier: Modifier {
        get { currentModifier.withLock { $0 } }
        set { currentModifier.withLock { $0 = newValue } }
    }

    var interceptsHide: Bool {
        get { hideInterception.withLock { $0 } }
        set { hideInterception.withLock { $0 = newValue } }
    }

    init(onKey: @escaping (Character, Bool) -> Void, onPress: @escaping () -> Void, onHide: @escaping () -> Void) {
        self.onKey = onKey
        self.onPress = onPress
        self.onHide = onHide
        super.init()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(reloadLayout),
            name: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc private func reloadLayout() {
        let layout = KeyLayout.characters()
        characters.withLock { $0 = layout }
        log.info("keyboard layout changed, \(layout.count) keys mapped")
    }

    func start() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue | 1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                Unmanaged<KeyTap>.fromOpaque(refcon!).takeUnretainedValue().handle(type, event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        self.tap = tap
        let thread = Thread {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.qualityOfService = .userInteractive
        thread.start()
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            log.error("key tap disabled (\(type.rawValue)), re-enabling")
            tap.map { CGEvent.tapEnable(tap: $0, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            trackTaps(event.flags)
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if type == .keyUp {
            return swallowedKeyCodes.remove(keyCode) == nil ? Unmanaged.passUnretained(event) : nil
        }

        lastTapAt = nil
        pressWasUsed = pressedAt != nil

        let character = characters.withLock { $0[keyCode] }
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        if character == "h", isHideShortcut(event.flags), interceptsHide, Self.visibleAppCount() == 1 {
            swallowedKeyCodes.insert(keyCode)
            if !isRepeat {
                DispatchQueue.main.async { self.onHide() }
            }
            return nil
        }

        guard modifier.matches(event.flags), let character else {
            return Unmanaged.passUnretained(event)
        }

        swallowedKeyCodes.insert(keyCode)
        if !isRepeat {
            let togglesHiding = pressIsDoubleTap
            pressIsDoubleTap = false
            DispatchQueue.main.async { self.onKey(character, togglesHiding) }
        }
        return nil
    }

    private func trackTaps(_ flags: CGEventFlags) {
        let now = ProcessInfo.processInfo.systemUptime
        let held = modifier.isHeld(flags)

        if held, pressedAt == nil {
            pressIsDoubleTap = lastTapAt.map { now - $0 < Self.doubleTapInterval } ?? false
            pressedAt = now
            lastTapAt = nil
            DispatchQueue.main.async { self.onPress() }
        } else if !held, let pressedAt {
            lastTapAt = !pressWasUsed && now - pressedAt < Self.doubleTapInterval ? now : nil
            self.pressedAt = nil
            pressIsDoubleTap = false
            pressWasUsed = false
        }
    }

    private func isHideShortcut(_ flags: CGEventFlags) -> Bool {
        flags.intersection([.maskAlternate, .maskCommand, .maskControl, .maskShift]) == .maskCommand
    }

    private static func visibleAppCount() -> Int {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return Set(windows
            .filter { $0[kCGWindowLayer as String] as? Int == 0 }
            .compactMap { $0[kCGWindowOwnerPID as String] as? pid_t }
        ).count
    }
}

enum KeyLayout {
    static func characters() -> [Int64: Character] {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return [:] }

        let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue()
        let layout = UnsafeRawPointer(CFDataGetBytePtr(data)!).assumingMemoryBound(to: UCKeyboardLayout.self)

        return (0..<128).reduce(into: [:]) { characters, keyCode in
            var deadKeyState: UInt32 = 0
            var length = 0
            var output = [UniChar](repeating: 0, count: 4)
            UCKeyTranslate(
                layout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                output.count,
                &length,
                &output
            )
            guard let character = String(utf16CodeUnits: output, count: length).lowercased().first,
                  character.isASCII, character.isLetter || character.isNumber
            else { return }
            characters[Int64(keyCode)] = character
        }
    }
}

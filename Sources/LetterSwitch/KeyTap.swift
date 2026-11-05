import AppKit
import Carbon.HIToolbox
import os

final class KeyTap {
    private let onKey: (Character) -> Void
    private let currentModifier = OSAllocatedUnfairLock(initialState: Modifier.rightOption)
    private let characters = KeyLayout.characters()
    private var tap: CFMachPort?
    private var swallowedKeyCodes = Set<Int64>()

    var modifier: Modifier {
        get { currentModifier.withLock { $0 } }
        set { currentModifier.withLock { $0 = newValue } }
    }

    init(onKey: @escaping (Character) -> Void) {
        self.onKey = onKey
    }

    func start() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
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

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if type == .keyUp {
            return swallowedKeyCodes.remove(keyCode) == nil ? Unmanaged.passUnretained(event) : nil
        }

        guard modifier.matches(event.flags), let character = characters[keyCode] else {
            return Unmanaged.passUnretained(event)
        }

        swallowedKeyCodes.insert(keyCode)
        if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
            DispatchQueue.main.async { self.onKey(character) }
        }
        return nil
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

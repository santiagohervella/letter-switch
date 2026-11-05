import AppKit

struct Focuser {
    private static let messagingTimeout: Float = 0.5

    func focus(_ app: NSRunningApplication) {
        if app.isHidden {
            app.unhide()
        }

        var psn = ProcessSerialNumber()
        var windowID: CGWindowID = 0
        guard let window = visibleWindow(of: app),
              _AXUIElementGetWindow(window, &windowID) == .success,
              GetProcessForPID(app.processIdentifier, &psn) == noErr
        else {
            reopen(app)
            return
        }

        _SLPSSetFrontProcessWithOptions(&psn, windowID, SLPSMode.userGenerated)
        makeKeyWindow(windowID, &psn)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    private func visibleWindow(of app: NSRunningApplication) -> AXUIElement? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(element, Self.messagingTimeout)

        if let main: AXUIElement = attribute(kAXMainWindowAttribute, of: element), !isMinimized(main) {
            return main
        }
        let windows: [AXUIElement] = attribute(kAXWindowsAttribute, of: element) ?? []
        return windows.first { !isMinimized($0) }
    }

    private func isMinimized(_ window: AXUIElement) -> Bool {
        attribute(kAXMinimizedAttribute, of: window) ?? false
    }

    private func attribute<T>(_ name: String, of element: AXUIElement) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }

    private func reopen(_ app: NSRunningApplication) {
        guard let url = app.bundleURL else {
            app.activate()
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private func makeKeyWindow(_ windowID: CGWindowID, _ psn: inout ProcessSerialNumber) {
        var bytes = [UInt8](repeating: 0, count: 0xf8)
        bytes[0x04] = 0xf8
        bytes[0x3a] = 0x10
        withUnsafeBytes(of: windowID) { bytes.replaceSubrange(0x3c..<0x40, with: $0) }
        bytes.replaceSubrange(0x20..<0x30, with: repeatElement(0xff, count: 0x10))

        [UInt8(0x01), UInt8(0x02)].forEach { phase in
            bytes[0x08] = phase
            SLPSPostEventRecordTo(&psn, &bytes)
        }
    }
}

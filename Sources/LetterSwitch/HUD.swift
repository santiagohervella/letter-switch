import AppKit

final class HUD {
    private static let visibleDuration: TimeInterval = 0.5
    private static let fadeDuration: TimeInterval = 0.15
    private static let padding = NSSize(width: 24, height: 14)
    private static let cornerRadius: CGFloat = 14

    private let panel = NSPanel(
        contentRect: .zero,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: true
    )
    private let label = NSTextField(labelWithString: "")
    private var pendingFade: DispatchWorkItem?

    init() {
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.state = .active
        background.maskImage = Self.roundedMask(radius: Self.cornerRadius)
        background.wantsLayer = true
        background.layer?.cornerRadius = Self.cornerRadius
        background.layer?.borderWidth = 1.5
        background.layer?.borderColor = NSColor.white.withAlphaComponent(0.4).cgColor

        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: background.centerYAnchor),
        ])
        panel.contentView = background
    }

    func flash(_ message: String) {
        show(message)
        dismiss()
    }

    func show(_ message: String) {
        pendingFade?.cancel()
        label.stringValue = message

        let size = NSSize(
            width: label.intrinsicContentSize.width + Self.padding.width * 2,
            height: label.intrinsicContentSize.height + Self.padding.height * 2
        )
        let screen = (Self.focusedScreen() ?? NSScreen.main ?? NSScreen.screens[0]).frame
        panel.setFrame(
            NSRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2, width: size.width, height: size.height),
            display: true
        )
        panel.alphaValue = 1
        panel.orderFrontRegardless()
    }

    func dismiss() {
        pendingFade?.cancel()
        let fade = DispatchWorkItem { [weak self] in self?.fadeOut() }
        pendingFade = fade
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleDuration, execute: fade)
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self, self.panel.alphaValue == 0 else { return }
            self.panel.orderOut(nil)
        }
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    private static func focusedScreen() -> NSScreen? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
              let window = windows.first(where: {
                  $0[kCGWindowOwnerPID as String] as? pid_t == pid && $0[kCGWindowLayer as String] as? Int == 0
              }),
              let bounds = window[kCGWindowBounds as String] as? NSDictionary,
              let rect = CGRect(dictionaryRepresentation: bounds),
              let primaryHeight = NSScreen.screens.first?.frame.height
        else { return nil }

        let center = NSPoint(x: rect.midX, y: primaryHeight - rect.midY)
        return NSScreen.screens.first { $0.frame.contains(center) }
    }
}

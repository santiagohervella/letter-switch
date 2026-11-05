import AppKit

let size: CGFloat = 1024
let output = URL(filePath: CommandLine.arguments[1])

func color(_ hex: Int) -> NSColor {
    NSColor(
        calibratedRed: CGFloat(hex >> 16 & 0xff) / 255,
        green: CGFloat(hex >> 8 & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

func withShadow(opacity: CGFloat, offset: CGFloat, blur: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(opacity)
    shadow.shadowOffset = NSSize(width: 0, height: -offset)
    shadow.shadowBlurRadius = blur
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func drawText(_ string: String, size: CGFloat, centeredIn rect: NSRect) {
    let text = NSAttributedString(string: string, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: .black),
        .foregroundColor: color(0x2a1e12),
    ])
    let textSize = text.size()
    text.draw(at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2))
}

let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    let board = NSRect(x: 100, y: 100, width: 824, height: 824)
    let boardPath = NSBezierPath(roundedRect: board, xRadius: 185, yRadius: 185)

    withShadow(opacity: 0.35, offset: 12, blur: 24) {
        color(0x1f6f5c).setFill()
        boardPath.fill()
    }

    NSGraphicsContext.saveGraphicsState()
    boardPath.addClip()
    color(0x2b8a72).setStroke()
    for position in stride(from: board.minX, through: board.maxX, by: 103) {
        let lines = NSBezierPath()
        lines.move(to: NSPoint(x: position, y: board.minY))
        lines.line(to: NSPoint(x: position, y: board.maxY))
        lines.move(to: NSPoint(x: board.minX, y: position))
        lines.line(to: NSPoint(x: board.maxX, y: position))
        lines.lineWidth = 4
        lines.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()

    let tile = NSRect(x: 252, y: 240, width: 520, height: 540)
    withShadow(opacity: 0.5, offset: 24, blur: 30) {
        color(0xb98a4e).setFill()
        NSBezierPath(roundedRect: tile, xRadius: 48, yRadius: 48).fill()
    }

    let face = NSBezierPath(roundedRect: tile.insetBy(dx: 10, dy: 10).offsetBy(dx: 0, dy: 8), xRadius: 40, yRadius: 40)
    NSGradient(starting: color(0xf6dfb0), ending: color(0xdcb57a))?.draw(in: face, angle: -90)

    drawText("L", size: 380, centeredIn: tile)
    drawText("1", size: 96, centeredIn: NSRect(x: tile.maxX - 130, y: tile.minY + 40, width: 90, height: 110))
    return true
}

let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! bitmap.representation(using: .png, properties: [:])!.write(to: output)

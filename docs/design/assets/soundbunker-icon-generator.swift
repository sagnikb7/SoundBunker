import AppKit

// SoundBunker: a protective headphone arch surrounding a compact sound wave.
// This deterministic, original vector source keeps the icon crisp and editable.
// Rendering happens only when preparing assets; the app loads a static PNG.
// Usage: swift scripts/generate_icon.swift <destination.png>
let destination = CommandLine.arguments[1]
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: 1)
}
func gradient(_ colors: [CGColor], from: CGPoint, to: CGPoint) {
    let value = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray, locations: nil)!
    context.drawLinearGradient(value, start: from, end: to,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

// Full opaque square. iOS supplies the rounded mask, never baked into the art.
gradient([color(0.025, 0.045, 0.11), color(0.07, 0.14, 0.25)],
    from: CGPoint(x: 870, y: 0), to: CGPoint(x: 140, y: 1024))
let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
    CGColor(red: 0.10, green: 0.36, blue: 0.43, alpha: 0.55),
    CGColor(red: 0.10, green: 0.36, blue: 0.43, alpha: 0)
] as CFArray, locations: [0, 1])!
context.drawRadialGradient(glow, startCenter: CGPoint(x: 300, y: 800), startRadius: 0,
    endCenter: CGPoint(x: 300, y: 800), endRadius: 750, options: [])

let arch = CGMutablePath()
arch.move(to: CGPoint(x: 246, y: 410))
arch.addLine(to: CGPoint(x: 246, y: 520))
arch.addCurve(to: CGPoint(x: 778, y: 520),
    control1: CGPoint(x: 246, y: 868), control2: CGPoint(x: 778, y: 868))
arch.addLine(to: CGPoint(x: 778, y: 410))
let archOutline = arch.copy(strokingWithWidth: 82, lineCap: .round,
    lineJoin: .round, miterLimit: 0)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -16), blur: 28,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))
context.addPath(archOutline)
context.setFillColor(color(0.40, 0.89, 0.87))
context.fillPath()
context.restoreGState()
context.saveGState()
context.addPath(archOutline)
context.clip()
gradient([color(0.29, 0.67, 0.90), color(0.70, 0.98, 0.88)],
    from: CGPoint(x: 720, y: 330), to: CGPoint(x: 340, y: 820))
context.restoreGState()

// Three solid capsules remain legible even at notification/home-screen sizes.
for (x, y, height, isCenter) in [
    (343.0, 322.0, 208.0, false),
    (465.0, 258.0, 336.0, true),
    (587.0, 322.0, 208.0, false)
] {
    let path = CGPath(roundedRect: CGRect(x: x, y: y, width: 94, height: height),
        cornerWidth: 47, cornerHeight: 47, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 24,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.24))
    context.addPath(path)
    context.setFillColor(isCenter ? color(0.98, 0.60, 0.35) : color(0.64, 0.89, 0.95))
    context.fillPath()
    context.restoreGState()
    context.saveGState()
    context.addPath(path)
    context.clip()
    let colors = isCenter
        ? [color(0.98, 0.43, 0.32), color(1.0, 0.77, 0.44)]
        : [color(0.34, 0.70, 0.88), color(0.80, 0.99, 0.94)]
    gradient(colors, from: CGPoint(x: x + 94, y: y), to: CGPoint(x: x, y: y + height))
    context.restoreGState()
}

NSGraphicsContext.restoreGraphicsState()
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))

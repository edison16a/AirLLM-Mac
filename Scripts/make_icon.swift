import AppKit

// Builds the app icon: the rocket from the official AirLLM logo on a white squircle.
// Usage: swift make_icon.swift <logo.png> <output.iconset>

let arguments = CommandLine.arguments
guard arguments.count == 3, let logo = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write("usage: make_icon.swift <logo.png> <output.iconset>\n".data(using: .utf8)!)
    exit(1)
}
let output = arguments[2]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

// The logo is the rocket above the "AirLLM" wordmark. The wordmark is unreadable at
// icon sizes, so only the rocket (the top 72%) is kept.
let crop = NSRect(x: 0, y: logo.size.height * 0.28, width: logo.size.width, height: logo.size.height * 0.72)

func render(_ pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high

    // Apple's icon grid leaves a 10% margin around the squircle.
    let size = CGFloat(pixels)
    let inset = size * 0.1
    let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = size * 0.025
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
    shadow.set()
    NSColor.white.setFill()
    squircle.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    squircle.addClip()
    let width = rect.width * 0.86
    let height = width * crop.height / crop.width
    let target = NSRect(x: (size - width) / 2, y: (size - height) / 2, width: width, height: height)
    logo.draw(in: target, from: crop, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: URL(fileURLWithPath: "\(output)/icon_\(base)x\(base).png"))
    try render(base * 2).write(to: URL(fileURLWithPath: "\(output)/icon_\(base)x\(base)@2x.png"))
}

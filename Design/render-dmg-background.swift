import AppKit
import CoreGraphics
import Foundation

// DMG 安装窗口背景（660x420）。由 GitHub Actions 的 create-dmg 使用。
let width: CGFloat = 660
let height: CGFloat = 420
let url = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Design/dmg-background.png")

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let graphics = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("Unable to create bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
let context = graphics.cgContext
context.setShouldAntialias(true)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let space = CGColorSpaceCreateDeviceRGB()
let background = CGGradient(
    colorsSpace: space,
    colors: [color(0x191C27), color(0x0B0D13), color(0x06070B)] as CFArray,
    locations: [0, 0.55, 1]
)!
context.drawLinearGradient(
    background,
    start: CGPoint(x: 0, y: height),
    end: CGPoint(x: width, y: 0),
    options: []
)

let glow = CGGradient(
    colorsSpace: space,
    colors: [color(0xFF6B1A, 0.20), color(0xFF6B1A, 0)] as CFArray,
    locations: [0, 1]
)!
context.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: 150, y: 310),
    startRadius: 0,
    endCenter: CGPoint(x: 150, y: 310),
    endRadius: 330,
    options: [.drawsAfterEndLocation]
)

// A very light orbit to suggest playback.
context.setStrokeColor(color(0xFFFFFF, 0.06))
context.setLineWidth(1)
context.strokeEllipse(in: CGRect(x: 225, y: 52, width: 210, height: 210))

// Arrow between the app icon and Applications.
context.setStrokeColor(color(0xFFFFFF, 0.34))
context.setLineWidth(2)
context.setLineCap(.round)
context.move(to: CGPoint(x: 282, y: 218))
context.addLine(to: CGPoint(x: 382, y: 218))
context.addLine(to: CGPoint(x: 362, y: 238))
context.move(to: CGPoint(x: 382, y: 218))
context.addLine(to: CGPoint(x: 362, y: 198))
context.strokePath()

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 31, weight: .bold),
    .foregroundColor: NSColor.white
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .medium),
    .foregroundColor: NSColor.white.withAlphaComponent(0.52)
]
let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.62)
]

("PlayerX" as NSString).draw(at: NSPoint(x: 36, y: height - 78), withAttributes: titleAttributes)
("Apple 原生短剧播放器" as NSString).draw(at: NSPoint(x: 38, y: height - 102), withAttributes: subtitleAttributes)
("拖动 PlayerX 到 Applications 安装" as NSString).draw(
    at: NSPoint(x: 36, y: 28),
    withAttributes: hintAttributes
)
("A native Apple player for iPhone, iPad and Mac" as NSString).draw(
    at: NSPoint(x: 36, y: height - 128),
    withAttributes: subtitleAttributes
)

NSGraphicsContext.restoreGraphicsState()
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("PNG encode failed") }
try! data.write(to: url)
print("Rendered \(url.path)")

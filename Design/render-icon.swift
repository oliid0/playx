import AppKit
import CoreGraphics
import Foundation

// PlayerX app icon renderer.
//
// 设计：深墨色底 + 双色（橙 -> 玫红）播放三角，三角被一条深色斜切线分成两半，
// 既像播放键，也保留 PlayerX 的 X 记忆点。背景有一层很轻的暖色/紫色氛围光。
// 运行：swift Design/render-icon.swift Design

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Design", isDirectory: true)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func add(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
func sub(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
func mul(_ a: CGPoint, _ s: CGFloat) -> CGPoint { CGPoint(x: a.x * s, y: a.y * s) }
func len(_ a: CGPoint) -> CGFloat { max(0.0001, sqrt(a.x * a.x + a.y * a.y)) }
func normalize(_ a: CGPoint) -> CGPoint { mul(a, 1 / len(a)) }

func roundedTriangle(points: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    for index in points.indices {
        let previous = points[(index + points.count - 1) % points.count]
        let current = points[index]
        let next = points[(index + 1) % points.count]
        let start = add(current, mul(normalize(sub(previous, current)), radius))
        let end = add(current, mul(normalize(sub(next, current)), radius))
        if index == 0 {
            path.move(to: start)
        } else {
            path.addLine(to: start)
        }
        path.addQuadCurve(to: end, control: current)
    }
    path.closeSubpath()
    return path
}

func drawGradient(_ context: CGContext, rect: CGRect, colors: [CGColor], locations: [CGFloat], start: CGPoint, end: CGPoint) {
    let space = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations) else { return }
    context.saveGState()
    context.clip(to: rect)
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

func drawRadial(_ context: CGContext, center: CGPoint, radius: CGFloat, color: CGColor) {
    let space = CGColorSpaceCreateDeviceRGB()
    let colors = [color, color.copy(alpha: 0) ?? color] as CFArray
    guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: [.drawsAfterEndLocation]
    )
}

func render(size: CGFloat, macOSStyle: Bool, transparentBackground: Bool, to url: URL) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
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
    context.clear(CGRect(x: 0, y: 0, width: size, height: size))

    let scale = size / 1024
    if !transparentBackground {
        let inset: CGFloat = macOSStyle ? 68 * scale : 0
        let backgroundRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        let backgroundPath = CGPath(
            roundedRect: backgroundRect,
            cornerWidth: macOSStyle ? 190 * scale : 0,
            cornerHeight: macOSStyle ? 190 * scale : 0,
            transform: nil
        )

        context.saveGState()
        if macOSStyle {
            context.setShadow(offset: CGSize(width: 0, height: -14 * scale), blur: 36 * scale, color: color(0x000000, 0.55))
        }
        context.addPath(backgroundPath)
        context.setFillColor(color(0x090B10))
        context.fillPath()
        context.restoreGState()

        context.saveGState()
        context.addPath(backgroundPath)
        context.clip()

        drawGradient(
            context,
            rect: backgroundRect,
            colors: [color(0x1A1D2A), color(0x0C0E15), color(0x06070B)],
            locations: [0, 0.55, 1],
            start: CGPoint(x: backgroundRect.minX, y: backgroundRect.maxY),
            end: CGPoint(x: backgroundRect.maxX, y: backgroundRect.minY)
        )
        drawRadial(context, center: CGPoint(x: 330 * scale, y: 790 * scale), radius: 640 * scale, color: color(0xFF6B1A, 0.18))
        drawRadial(context, center: CGPoint(x: 790 * scale, y: 230 * scale), radius: 580 * scale, color: color(0x9B5CF6, 0.16))

        // Very subtle inner border.
        context.addPath(backgroundPath)
        context.setStrokeColor(color(0xFFFFFF, 0.06))
        context.setLineWidth(1.5 * scale)
        context.strokePath()
        context.restoreGState()
    }

    let triangle = roundedTriangle(
        points: [
            CGPoint(x: 326 * scale, y: 258 * scale),
            CGPoint(x: 326 * scale, y: 766 * scale),
            CGPoint(x: 804 * scale, y: 512 * scale)
        ],
        radius: 58 * scale
    )

    context.saveGState()
    context.setShadow(offset: .zero, blur: 52 * scale, color: color(0xFF3B30, 0.40))
    context.addPath(triangle)
    context.clip()
    drawGradient(
        context,
        rect: CGRect(x: 0, y: 0, width: size, height: size),
        colors: [color(0xFFB000), color(0xFF6A00), color(0xFF2D55)],
        locations: [0, 0.48, 1],
        start: CGPoint(x: 330 * scale, y: 780 * scale),
        end: CGPoint(x: 820 * scale, y: 240 * scale)
    )
    // The diagonal crease that keeps the X in PlayerX.
    context.setLineCap(.round)
    context.setStrokeColor(color(0x090B10, 0.42))
    context.setLineWidth(5 * scale)
    context.move(to: CGPoint(x: 265 * scale, y: 815 * scale))
    context.addLine(to: CGPoint(x: 825 * scale, y: 225 * scale))
    context.strokePath()
    context.setStrokeColor(color(0xFFFFFF, 0.10))
    context.setLineWidth(1.5 * scale)
    context.move(to: CGPoint(x: 278 * scale, y: 804 * scale))
    context.addLine(to: CGPoint(x: 812 * scale, y: 238 * scale))
    context.strokePath()
    context.restoreGState()

    // A hairline highlight around the mark.
    context.addPath(triangle)
    context.setStrokeColor(color(0xFFFFFF, 0.22))
    context.setLineWidth(1.5 * scale)
    context.strokePath()

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try! data.write(to: url)
}

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

render(size: 1024, macOSStyle: false, transparentBackground: false, to: outputDirectory.appendingPathComponent("AppIcon-1024.png"))
render(size: 1024, macOSStyle: true, transparentBackground: false, to: outputDirectory.appendingPathComponent("AppIcon-mac-1024.png"))
render(size: 1024, macOSStyle: false, transparentBackground: true, to: outputDirectory.appendingPathComponent("LaunchLogo-1024.png"))
print("Rendered icons to \(outputDirectory.path)")

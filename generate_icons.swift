#!/usr/bin/env swift
import Foundation
import AppKit

let size = CGSize(width: 1024, height: 1024)
let center = CGPoint(x: size.width / 2, y: size.height / 2)

let background = NSColor(calibratedRed: 13/255, green: 13/255, blue: 26/255, alpha: 1)
let north = NSColor(calibratedRed: 129/255, green: 199/255, blue: 132/255, alpha: 1)
let east = NSColor(calibratedRed: 255/255, green: 200/255, blue: 87/255, alpha: 1)
let south = NSColor(calibratedRed: 229/255, green: 115/255, blue: 115/255, alpha: 1)
let west = NSColor(calibratedRed: 124/255, green: 77/255, blue: 255/255, alpha: 1)
let cyan = NSColor(calibratedRed: 0/255, green: 229/255, blue: 255/255, alpha: 1)

let outerRadius: CGFloat = 88
let centerRadius: CGFloat = 54
let reach: CGFloat = 308

func drawGlow(at point: CGPoint, radius: CGFloat, color: NSColor) {
    for layer in stride(from: 7, through: 1, by: -1) {
        let alpha = CGFloat(0.06 * Double(layer))
        color.withAlphaComponent(alpha).setFill()
        let glowRadius = radius + CGFloat(layer) * 14
        let rect = CGRect(
            x: point.x - glowRadius,
            y: point.y - glowRadius,
            width: glowRadius * 2,
            height: glowRadius * 2
        )
        NSBezierPath(ovalIn: rect).fill()
    }
}

func drawDot(at point: CGPoint, radius: CGFloat, color: NSColor) {
    drawGlow(at: point, radius: radius, color: color)
    color.setFill()
    let rect = CGRect(
        x: point.x - radius,
        y: point.y - radius,
        width: radius * 2,
        height: radius * 2
    )
    NSBezierPath(ovalIn: rect).fill()
}

func drawIcon(transparentBackground: Bool) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    if !transparentBackground {
        background.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
    }

    drawDot(at: CGPoint(x: center.x, y: center.y + reach), radius: outerRadius, color: north)
    drawDot(at: CGPoint(x: center.x + reach, y: center.y), radius: outerRadius, color: east)
    drawDot(at: CGPoint(x: center.x, y: center.y - reach), radius: outerRadius, color: south)
    drawDot(at: CGPoint(x: center.x - reach, y: center.y), radius: outerRadius, color: west)
    drawDot(at: center, radius: centerRadius, color: cyan)

    image.unlockFocus()
    return image
}

func drawOpaqueIOSBitmap() throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(
            domain: "IconGenerator",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Failed to create opaque iOS bitmap"]
        )
    }

    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    background.setFill()
    NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

    drawDot(at: CGPoint(x: center.x, y: center.y + reach), radius: outerRadius, color: north)
    drawDot(at: CGPoint(x: center.x + reach, y: center.y), radius: outerRadius, color: east)
    drawDot(at: CGPoint(x: center.x, y: center.y - reach), radius: outerRadius, color: south)
    drawDot(at: CGPoint(x: center.x - reach, y: center.y), radius: outerRadius, color: west)
    drawDot(at: center, radius: centerRadius, color: cyan)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ image: NSImage, to path: String) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"]) 
    }
    try pngData.write(to: URL(fileURLWithPath: path))
}

let fileManager = FileManager.default
let outputDir = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("assets/images")
try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)

let fullPath = outputDir.appendingPathComponent("icon.png").path
let foregroundPath = outputDir.appendingPathComponent("icon_foreground.png").path
let iosPath = outputDir.appendingPathComponent("icon_ios.png").path

try writePNG(drawIcon(transparentBackground: false), to: fullPath)
print("✓ assets/images/icon.png")
try writePNG(drawIcon(transparentBackground: true), to: foregroundPath)
print("✓ assets/images/icon_foreground.png")
let iosBitmap = try drawOpaqueIOSBitmap()
guard let iosPngData = iosBitmap.representation(using: .png, properties: [:]) else {
    throw NSError(
        domain: "IconGenerator",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create opaque iOS PNG data"]
    )
}
try iosPngData.write(to: URL(fileURLWithPath: iosPath))
print("✓ assets/images/icon_ios.png")
print("\nNow run:")
print("  dart run flutter_launcher_icons")

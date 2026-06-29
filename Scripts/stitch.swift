#!/usr/bin/env swift
//
// Горизонтально склеивает PNG-скриншоты в одно фото.
// Использование: swift stitch.swift <out.png> <in1.png> <in2.png> ...
//
import AppKit
import Foundation

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: stitch.swift <out.png> <in...>\n".utf8))
    exit(1)
}
let outPath = args[0]
let inputs = Array(args.dropFirst())

let gap: CGFloat = 28
let bg = NSColor(red: 0xF3 / 255.0, green: 0xF1 / 255.0, blue: 0xEC / 255.0, alpha: 1)

func pixelSize(_ image: NSImage) -> CGSize {
    if let rep = image.representations.first {
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }
    return image.size
}

let images: [(img: NSImage, size: CGSize)] = inputs.map { path in
    guard let image = NSImage(contentsOfFile: path) else {
        FileHandle.standardError.write(Data("cannot read \(path)\n".utf8))
        exit(1)
    }
    let size = pixelSize(image)
    image.size = size   // points == pixels, чтобы рисовать без масштабирования
    return (image, size)
}

let height = images.map { $0.size.height }.max() ?? 0
let totalWidth = images.reduce(0) { $0 + $1.size.width } + gap * CGFloat(images.count - 1)
let outW = Int(totalWidth.rounded())
let outH = Int(height.rounded())

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: outW, pixelsHigh: outH,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

bg.setFill()
NSRect(x: 0, y: 0, width: outW, height: outH).fill()

var x: CGFloat = 0
for item in images {
    let dest = NSRect(x: x, y: height - item.size.height, width: item.size.width, height: item.size.height)
    item.img.draw(in: dest, from: NSRect(origin: .zero, size: item.size), operation: .sourceOver, fraction: 1)
    x += item.size.width + gap
}

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath): \(outW)x\(outH)")

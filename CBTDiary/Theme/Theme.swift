import SwiftUI

/// Палитра приложения, перенесённая из CSS-макета.
enum Palette {
    static let canvas = Color(hex: 0xF3F1EC)
    static let canvasEdge = Color(hex: 0xE7E3DB)
    static let card = Color(hex: 0xFBFAF7)

    static let ink = Color(hex: 0x262320)
    static let inkSoft = Color(hex: 0x6E695F)
    static let inkFaint = Color(hex: 0x9A9488)
    static let line = Color(hex: 0xE4E0D7)

    static let event = Color(hex: 0x2E5F5B)
    static let thought = Color(hex: 0xAE7A2C)
    static let feeling = Color(hex: 0xBB5D4C)

    static let eventTint = Color(hex: 0xE3ECEA)
    static let thoughtTint = Color(hex: 0xF2E8D6)
    static let feelingTint = Color(hex: 0xF4E2DD)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension Font {
    /// Засечный шрифт для заголовков (аналог Lora из макета).
    static func serif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Основной гротеск (аналог Manrope).
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

import SwiftUI

// MARK: - Color Palette (Ink & Amber)

enum DS {
    // Core backgrounds
    static let ink = Color(hex: 0x0D1B2A)
    static let inkMid = Color(hex: 0x1B2D45)

    // Text hierarchy
    static let slate = Color(hex: 0x415A77)
    static let slateLight = Color(hex: 0x778DA9)

    // Action colors
    static let amber = Color(hex: 0xE8A838)
    static let amberGlow = Color(hex: 0xF0C060)
    static let recording = Color(hex: 0xE85454)
    static let success = Color(hex: 0x4CAF82)

    // Surface
    static let paper = Color(hex: 0xF0EDE6)

    // MARK: - Spacing tokens

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
    }

    // MARK: - Radius tokens

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // MARK: - Typography

    enum Font {
        /// DM Serif Display — hero/display text
        static func display(size: CGFloat) -> SwiftUI.Font {
            .custom("DMSerifDisplay-Regular", size: size)
        }

        /// DM Sans SemiBold (600) — headings
        static func heading(size: CGFloat) -> SwiftUI.Font {
            .custom("DMSans-SemiBold", size: size)
        }

        /// DM Sans Light (300) — body text
        static func body(size: CGFloat) -> SwiftUI.Font {
            .custom("DMSans-Light", size: size)
        }

        /// JetBrains Mono — timestamps, filenames, code
        static func mono(size: CGFloat) -> SwiftUI.Font {
            .custom("JetBrainsMono-Regular", size: size)
        }
    }
}

// MARK: - Hex color initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

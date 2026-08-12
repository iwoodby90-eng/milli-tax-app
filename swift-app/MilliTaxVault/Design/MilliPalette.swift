import SwiftUI

// MARK: - Milli Design Token Palette (Single Source of Truth)
// Color(hex:) initializer lives in Colors.swift — do not redeclare here.

enum MilliPalette {
    // Core surfaces
    static let background    = Color(hex: "14141E")
    static let card          = Color(hex: "1A1A28")
    static let cardBorder    = Color(hex: "1E1E2E")

    // Accent
    static let accent        = Color(hex: "00E5FF")
    static let accentGlow    = Color(hex: "00E5FF").opacity(0.3)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.5)

    // Status
    static let positive      = Color(hex: "00E676")
    static let negative      = Color(hex: "FF5252")
    static let warning       = Color(hex: "FFB800")

    // Chrome / Metal
    static let chrome1       = Color(hex: "E8E8E8")
    static let chrome2       = Color(hex: "AAAAAA")
    static let chrome3       = Color(hex: "666666")
    static let titanium      = Color(hex: "B8BCC0")

    // Radii
    static let radius: CGFloat = 16
    static let radiusSmall: CGFloat = 12
}

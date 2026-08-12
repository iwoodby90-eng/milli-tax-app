import SwiftUI

// MARK: - Milli Design Token Palette
// Color(hex:) initializer lives in Colors.swift — do not redeclare here.

enum MilliPalette {
    static let background    = Color(hex: "080810")
    static let card          = Color(hex: "0D0D1A")
    static let cardBorder    = Color(white: 1, opacity: 0.08)
    static let accent        = Color(hex: "00B4FF")
    static let accentGlow    = Color(hex: "00B4FF").opacity(0.3)
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 1, opacity: 0.5)
    static let positive      = Color(hex: "00E676")
    static let negative      = Color(hex: "FF5252")
    static let radius: CGFloat = 14
}

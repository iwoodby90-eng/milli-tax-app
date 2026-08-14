import SwiftUI

// MARK: - Milli Design Tokens — Authoritative Color Palette
// Matches the approved production reference exactly.
// All UI components reference these tokens.

enum MilliColors {
    // Foundations
    static let obsidian = Color(hex: "07090B")
    static let carbon = Color(hex: "0E1114")
    static let elevated = Color(hex: "12191F")
    static let elevatedHigh = Color(hex: "172028")
    
    // Accent — PRECISION ONLY, never everywhere
    static let cyan = Color(hex: "00E5FF")
    static let teal = Color(hex: "00B4C2")
    
    // Metal
    static let silver = Color(hex: "C0C0C0")
    static let silverBright = Color(hex: "EEF2F4")
    static let titanium = Color(hex: "2A2E33")
    static let gunmetal = Color(hex: "1C1F24")
    
    // Text hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E9AA4")
    static let textMuted = Color(hex: "65717A")
    
    // States
    static let positive = Color(hex: "22DB83")
    static let warning = Color(hex: "F4B73B")
    static let negative = Color(hex: "FF5661")
    static let green = Color(hex: "22DB83")
    static let amber = Color(hex: "F4B73B")
    static let red = Color(hex: "FF5661")
    
    // Borders
    static let border = Color.white.opacity(0.07)
    static let borderCyan = Color(hex: "00E5FF").opacity(0.16)
    
    // Component aliases (backward compat)
    static let cardBackground = LinearGradient(
        colors: [Color.white.opacity(0.035), Color(hex: "12191F").opacity(0.98), Color(hex: "0E1114")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardStroke = Color.white.opacity(0.07)
    static let cardShadow = Color.black.opacity(0.32)
    static let secondaryText = Color(hex: "8E9AA4")
    static let inactiveTab = Color(hex: "8E9AA4")
}

// MARK: - Milli Gradients

enum MilliGradients {
    // Center M Button — angular chrome multi-stop (Bel Air bezel)
    static let chromeRing = AngularGradient(
        colors: [
            Color(hex: "767C80"),
            Color(hex: "F4F7F8"),
            Color(hex: "8D9397"),
            Color(hex: "E8ECEE"),
            Color(hex: "62686D"),
            Color(hex: "F5F7F8"),
            Color(hex: "767C80")
        ],
        center: .center
    )
    
    // Nav bar body — brushed titanium
    static let brushedTitanium = LinearGradient(
        colors: [
            Color(hex: "2A2E33"),
            Color(hex: "1C1F24"),
            Color(hex: "111417"),
            Color(hex: "0A0C0F")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Nav bar specular edge
    static let specularEdge = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.white.opacity(0.35),
            Color(hex: "EEF2F4").opacity(0.5),
            Color.white.opacity(0.35),
            Color.white.opacity(0.05)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // M button legacy compat
    static let mButton = LinearGradient(
        colors: [Color(hex: "1A1F2E"), Color(hex: "0D1117")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let mButtonText = LinearGradient(
        colors: [.white, Color(hex: "C0C0C0")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let mButtonStroke = LinearGradient(
        colors: [Color(hex: "767C80"), Color(hex: "F4F7F8"), Color(hex: "62686D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

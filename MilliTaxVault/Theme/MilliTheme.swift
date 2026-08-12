import SwiftUI

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Milli Color Palette

enum MilliColors {
    static let background = Color(hex: "080B12")
    static let backgroundGradientCenter = Color(hex: "0D1528")
    static let cyan = Color(hex: "00B4FF")
    static let green = Color(hex: "00D87E")
    static let amber = Color(hex: "FFB800")
    static let red = Color(hex: "FF4B6E")
    static let primaryText = Color.white
    static let secondaryText = Color(white: 0.55)
    static let sectionHeader = Color(white: 0.35)
    static let cardBackground = Color(white: 1, opacity: 0.04)
    static let cardStroke = Color(hex: "00B4FF").opacity(0.12)
    static let cardShadow = Color(hex: "00B4FF").opacity(0.08)
    static let inactiveTab = Color(white: 0.35)
    static let ringBackground = Color(white: 0.12)
}

// MARK: - Milli Typography

enum MilliFont {
    static let heroNumber = Font.system(size: 44, weight: .bold, design: .rounded)
    static let subHeroNumber = Font.system(size: 28, weight: .semibold)
    static let cardTitle = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12, weight: .medium)
}

// MARK: - Milli Gradients

enum MilliGradients {
    static let backgroundRadial = RadialGradient(
        colors: [MilliColors.backgroundGradientCenter, MilliColors.background],
        center: .top,
        startRadius: 0,
        endRadius: 600
    )
    
    static let cyanGlow = LinearGradient(
        colors: [MilliColors.cyan.opacity(0.3), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let aiButton = LinearGradient(
        colors: [Color(hex: "00B4FF"), Color(hex: "0066FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let mButton = LinearGradient(
        colors: [Color(white: 0.7), Color(white: 0.25), Color(white: 0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let mButtonText = LinearGradient(
        colors: [.white, Color(white: 0.6)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let mButtonStroke = LinearGradient(
        colors: [Color(white: 0.9), Color(white: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Section Header Style

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.medium)
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundColor(MilliColors.sectionHeader)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}

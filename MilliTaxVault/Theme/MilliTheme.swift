import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Milli Design Tokens
enum MilliColor {
    // Foundations
    static let obsidian = Color(hex: "07090B")
    static let carbon = Color(hex: "0E1114")
    static let elevated = Color(hex: "12191F")
    static let elevatedHigh = Color(hex: "172028")
    static let cardSurface = Color(hex: "101820")
    
    // Accent
    static let cyan = Color(hex: "00E5FF")
    static let teal = Color(hex: "00B4C2")
    static let cyanGlow = Color(hex: "00E5FF").opacity(0.15)
    
    // Metal
    static let silver = Color(hex: "C0C0C0")
    static let silverBright = Color(hex: "EEF2F4")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E9AA4")
    static let textMuted = Color(hex: "65717A")
    
    // States
    static let positive = Color(hex: "22DB83")
    static let warning = Color(hex: "F4B73B")
    static let negative = Color(hex: "FF5661")
    
    // Borders
    static let border = Color.white.opacity(0.07)
    static let borderStrong = Color(hex: "00E5FF").opacity(0.18)
}

enum MilliRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let card: CGFloat = 16
    static let large: CGFloat = 20
    static let pill: CGFloat = 999
}

enum MilliSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let huge: CGFloat = 32
}

// MARK: - Reusable Card Modifier
struct MilliCardStyle: ViewModifier {
    var padding: CGFloat = MilliSpacing.xl
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(LinearGradient(
                        colors: [Color(hex: "10171D"), Color(hex: "0C1217")],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(MilliColor.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            )
    }
}

struct MilliCardStrongBorder: ViewModifier {
    var padding: CGFloat = MilliSpacing.xl
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(LinearGradient(
                        colors: [Color(hex: "10171D"), Color(hex: "0C1217")],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(MilliColor.borderStrong, lineWidth: 1)
                    )
                    .shadow(color: MilliColor.cyan.opacity(0.08), radius: 12, x: 0, y: 4)
            )
    }
}

// MARK: - Section Header Style
struct SectionHeaderStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(MilliColor.textSecondary)
            .tracking(1.2)
            .textCase(.uppercase)
    }
}

// MARK: - View Extensions
extension View {
    func milliCard(padding: CGFloat = MilliSpacing.xl) -> some View {
        self.modifier(MilliCardStyle(padding: padding))
    }
    func milliCardCyan(padding: CGFloat = MilliSpacing.xl) -> some View {
        self.modifier(MilliCardStrongBorder(padding: padding))
    }
    func sectionHeaderStyle() -> some View {
        self.modifier(SectionHeaderStyleModifier())
    }
}

// MARK: - Currency Formatting Utility
enum MilliFormat {
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()
    
    private static let currencyFormatterFixed: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()
    
    /// Formats dollar values: $1,234 (no cents) or $1,234.56 (with cents)
    static func currency(_ value: Double, showCents: Bool = false) -> String {
        let formatter = showCents ? currencyFormatterFixed : currencyFormatter
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    /// Formats with +/- prefix: +$1,234.56
    static func signedCurrency(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + currencyFormatterFixed.string(from: NSNumber(value: abs(value)))!
    }
    
    /// Formats large numbers with abbreviations: $12.4K, $1.2M
    static func abbreviated(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            let k = value / 1_000
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "$%.0fK", k)
                : String(format: "$%.1fK", k)
        } else {
            return currency(value)
        }
    }
    
    /// Formats mileage: 1,234.5 mi
    static func miles(_ value: Double) -> String {
        String(format: "%,.1f mi", value)
    }
    
    /// Formats percentage: 67%
    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }
}

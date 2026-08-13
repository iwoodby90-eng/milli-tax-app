import SwiftUI

// MARK: - Milli Typography System
// Sora: financial values, large balances, major headings
// Inter: labels, metadata, navigation text, supporting copy
// Falls back to system fonts if custom fonts not bundled.

enum MilliFont {
    // MARK: - Sora (financial display)
    static let heroBalance = Font.custom("Sora-Bold", size: 32, relativeTo: .largeTitle)
    static let heroNumber = Font.custom("Sora-Bold", size: 28, relativeTo: .title)
    static let subHeroNumber = Font.custom("Sora-SemiBold", size: 20, relativeTo: .title2)
    static let cardValue = Font.custom("Sora-SemiBold", size: 18, relativeTo: .title3)
    static let metricValue = Font.custom("Sora-Bold", size: 22, relativeTo: .title2)
    static let scoreValue = Font.custom("Sora-Bold", size: 36, relativeTo: .largeTitle)
    
    // MARK: - Inter (labels & metadata)
    static let sectionLabel = Font.custom("Inter-SemiBold", size: 10, relativeTo: .caption2)
    static let cardTitle = Font.custom("Inter-SemiBold", size: 11, relativeTo: .caption)
    static let caption = Font.custom("Inter-Regular", size: 12, relativeTo: .caption)
    static let body = Font.custom("Inter-Regular", size: 14, relativeTo: .body)
    static let bodyMedium = Font.custom("Inter-Medium", size: 14, relativeTo: .body)
    static let navLabel = Font.custom("Inter-Medium", size: 10, relativeTo: .caption2)
    static let metadata = Font.custom("Inter-Regular", size: 11, relativeTo: .caption)
    static let insightBody = Font.custom("Inter-Regular", size: 13, relativeTo: .subheadline)
    
    // MARK: - System fallback variants (guaranteed render)
    static func soraBold(_ size: CGFloat) -> Font {
        .custom("Sora-Bold", size: size, relativeTo: .body)
    }
    
    static func soraSemiBold(_ size: CGFloat) -> Font {
        .custom("Sora-SemiBold", size: size, relativeTo: .body)
    }
    
    static func interRegular(_ size: CGFloat) -> Font {
        .custom("Inter-Regular", size: size, relativeTo: .body)
    }
    
    static func interMedium(_ size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size, relativeTo: .body)
    }
    
    static func interSemiBold(_ size: CGFloat) -> Font {
        .custom("Inter-SemiBold", size: size, relativeTo: .body)
    }
}

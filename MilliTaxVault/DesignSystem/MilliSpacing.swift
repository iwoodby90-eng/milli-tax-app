import SwiftUI

// MARK: - MilliSpacing — Consistent spatial rhythm (4pt grid)

enum MilliSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    // Screen edge insets
    static let screenHorizontal: CGFloat = 20
    static let screenVertical: CGFloat = 16

    // Card internal padding
    static let cardPadding: CGFloat = 16
    static let cardPaddingLarge: CGFloat = 20

    // Grid gap
    static let gridGap: CGFloat = 12

    // Corner radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 20
    static let radiusFull: CGFloat = 100
}

// MARK: - MilliLayout — Legacy layout constants (backward compat)
// New code should use MilliSpacing directly.

enum MilliLayout {
    static let screenMargin: CGFloat = MilliSpacing.screenHorizontal
    static let cardPaddingH: CGFloat = MilliSpacing.cardPadding
    static let cardPaddingV: CGFloat = MilliSpacing.cardPadding
    static let sectionGap: CGFloat = MilliSpacing.xxl
    static let cardRadius: CGFloat = MilliSpacing.radiusLg
    static let metadataGap: CGFloat = MilliSpacing.sm
}

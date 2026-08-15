import SwiftUI

// MARK: - Milli Spacing System
// Dense, disciplined spacing matched to the reference UI density.
// All sections visible without aggressive scrolling.

enum MilliLayout {
    // Screen margins
    static let screenMargin: CGFloat = 20
    
    // Major section gaps (between cards/sections)
    static let sectionGap: CGFloat = 12
    
    // Grid gap (between 2x2 metric cards)
    static let gridGap: CGFloat = 9
    
    // Card internal padding
    static let cardPadding: CGFloat = 12
    static let cardPaddingH: CGFloat = 14
    static let cardPaddingV: CGFloat = 12
    
    // Metadata spacing (line-to-line inside cards)
    static let metadataGap: CGFloat = 3
    
    // Bottom nav height for safe area offsets
    // Accounts for sculpted BelAir shape + safe area
    static let bottomNavHeight: CGFloat = 90
    
    // Center M button diameter (spec: 74–82pt)
    static let mButtonSize: CGFloat = 78
    
    // Segmented tick ring outer diameter
    static let mButtonRingSize: CGFloat = 92
    
    // Card corner radius
    static let cardRadius: CGFloat = 15
    
    // Small internal spacings
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
}

import SwiftUI

// MARK: - Canonical nav wiring (production)
//
// The canonical bottom navigation is MilliTaxVault/Components/MilliNavBar.swift
// (approved implementation, Image 40). MilliScreens v3.1 renders navigation only
// through the MilliScreensNavBar seam; this file injects the canonical renderer
// once at app start so every applicable screen uses the approved nav.
//
// Tab mapping (MilliScreensTab -> MilliTab):
//   .payouts -> .activity (Payouts)   .mileage -> .activity? no — see map below.
//   Canonical MilliTab cases: vault(Payouts), activity(Mileage), wealth, cockpit(More), home.
//
// NOTE: MilliScreensTab has 4 cases (payouts, mileage, wealth, more) and no center
// home case; the canonical MilliTab has 5 including home (center M dial).
// The mapping below keeps the 4 side tabs aligned; the center M dial (home) is
// owned by the canonical bar itself.

enum MilliScreensNavWiring {
    /// Call once at app launch (e.g. in App.init) before any MilliScreens view renders.
    static func install() {
        MilliScreensNavBar.canonicalRenderer = { $tab in
            AnyView(MilliNavBar(selectedTab: $tab.canonical, onHomeTap: {}))
        }
    }
}

extension Binding where Value == MilliScreensTab {
    /// Bridges the screens-layer tab binding to the canonical MilliTab binding.
    /// The canonical bar owns the center M (home) dial; side tabs map 1:1.
    var canonical: Binding<MilliTab> {
        Binding<MilliTab>(
            get: {
                switch wrappedValue {
                case .payouts: return .vault       // canonical "vault" displays as Payouts
                case .mileage: return .activity    // canonical "activity" displays as Mileage
                case .wealth:  return .wealth
                case .more:    return .cockpit     // canonical "cockpit" displays as More
                }
            },
            set: { newValue in
                switch newValue {
                case .vault:    wrappedValue = .payouts
                case .activity:  wrappedValue = .mileage
                case .wealth:   wrappedValue = .wealth
                case .cockpit:  wrappedValue = .more
                case .home:     break             // center M dial: canonical bar handles Home
                }
            }
        )
    }
}
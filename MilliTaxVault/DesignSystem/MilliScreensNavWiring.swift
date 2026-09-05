import SwiftUI

// MARK: - Canonical nav wiring (production) — SEAM ONLY, NOT YET BOUND
//
// ⚠️ STATUS (Ian, Aug 31, 2026): MilliTaxVault/Components/MilliNavBar.swift on
// main @ db94a253 is the OLD REJECTED floating-pill implementation (elevated
// center M, capsule chassis). It is NOT the approved canonical navigation.
//
// The only allowed final nav is the approved sculpted chrome chassis reference
// supplied by Ian: Payouts | Mileage | center M/Home | Wealth | More.
// No screenshot-derived substitute and no alternate design.
//
// MilliScreens v3.1 renders navigation ONLY through the
// MilliScreensNavBar.canonicalRenderer seam. Until the canonical nav
// reconstruction (full-width sculpted metallic chassis, integrated center M,
// four recessed upper details, segmented cyan illumination ring) passes its
// own runtime gate, the seam stays UNBOUND in production builds.
//
// INTEGRATION (Julian): once the reconstructed canonical nav lands as a view
// (e.g. MilliCanonicalNavBar), bind it here — and ONLY here:
//
//   enum MilliScreensNavWiring {
//       static func install() {
//           MilliScreensNavBar.canonicalRenderer = { $tab in
//               AnyView(MilliCanonicalNavBar(selectedTab: $tab.canonical))
//           }
//       }
//   }
//
// Do NOT bind the current MilliNavBar.swift. Do NOT render nav from
// MilliNavReferencePreview (quarantined, design-preview only, DO NOT SHIP).

enum MilliScreensNavWiring {
    /// Intentionally a no-op until the canonical nav reconstruction passes its
    /// runtime gate. Kept so the call site in the app root never changes.
    static func install() {
        // Seam deliberately left unbound: no approved canonical renderer exists
        // on main yet. See header note above before binding anything here.
    }
}

extension Binding where Value == MilliScreensTab {
    /// Bridges the screens-layer tab binding to the future canonical tab model.
    /// Side tabs map 1:1; the center M (Home) dial is owned by the canonical bar
    /// itself and does not round-trip through the screens layer.
    var canonical: Binding<MilliCanonicalTabPlaceholder> {
        Binding<MilliCanonicalTabPlaceholder>(
            get: {
                switch wrappedValue {
                case .payouts: return .payouts
                case .mileage: return .mileage
                case .wealth:  return .wealth
                case .more:    return .more
                }
            },
            set: { newValue in
                switch newValue {
                case .payouts: wrappedValue = .payouts
                case .mileage: wrappedValue = .mileage
                case .wealth:  wrappedValue = .wealth
                case .more:    wrappedValue = .more
                case .home:    break // center M dial: canonical bar handles Home
                }
            }
        )
    }
}

/// Placeholder tab model for the future canonical nav. Mirrors the approved
/// reference: Payouts | Mileage | center M/Home | Wealth | More. The canonical
/// nav reconstruction owns the real type; this keeps the bridge compiling
/// without referencing the rejected MilliTab.
enum MilliCanonicalTabPlaceholder: String, CaseIterable {
    case payouts = "Payouts"
    case mileage = "Mileage"
    case home    = "Home"
    case wealth  = "Wealth"
    case more    = "More"
}

import SwiftUI

// MARK: - FilterChipRow
// Status/filter chips with selected cyan state — Payouts (09), Expenses (15),
// Reports & Exports (26). Cyan only for the selected chip.

struct FilterChipRow: View {
    struct Chip: Identifiable, Hashable {
        let id: String
        var count: Int?

        init(_ id: String, count: Int? = nil) {
            self.id = id
            self.count = count
        }

        var label: String {
            count.map { "\(id) (\($0))" } ?? id
        }
    }

    let chips: [Chip]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.id) { chip in
                    let isSelected = chip.id == selection
                    Button {
                        selection = chip.id
                    } label: {
                        Text(chip.label)
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(isSelected ? MilliColors.blackGlass : MilliColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(isSelected ? MilliColors.cyanGlow : Color.white.opacity(0.045))
                            )
                            .overlay(
                                Capsule().stroke(
                                    isSelected ? MilliColors.cyanGlow : MilliColors.borderSubtle,
                                    lineWidth: 0.7
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filter by \(chip.id)")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
    }
}
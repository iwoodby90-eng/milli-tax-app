import SwiftUI

struct LifeEventsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: EventFilter = .upcoming

    enum EventFilter: String, CaseIterable, Hashable {
        case upcoming = "Upcoming"
        case planned = "Planned"
        case completed = "Completed"
    }

    enum ImpactLevel: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return MilliPalette.negative
            case .medium: return Color(red: 1.0, green: 0.72, blue: 0.0)
            case .low: return MilliPalette.positive
            }
        }
    }

    struct LifeEvent: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let date: String
        let cost: String
        let impact: ImpactLevel
        let filter: EventFilter
    }

    private let events: [LifeEvent] = [
        LifeEvent(icon: "heart.fill", name: "Marriage", date: "Jun 2027", cost: "$25,000", impact: .medium, filter: .upcoming),
        LifeEvent(icon: "house.fill", name: "House Purchase", date: "Dec 2028", cost: "$120,000", impact: .high, filter: .planned),
        LifeEvent(icon: "figure.and.child.holdinghands", name: "Child", date: "2029", cost: "$35,000", impact: .high, filter: .planned),
        LifeEvent(icon: "briefcase.fill", name: "Career Change", date: "TBD", cost: "Variable", impact: .medium, filter: .upcoming),
        LifeEvent(icon: "shield.fill", name: "Emergency Fund", date: "Ongoing", cost: "$15,000", impact: .low, filter: .upcoming),
    ]

    private var filteredEvents: [LifeEvent] {
        events.filter { $0.filter == selectedFilter }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                MilliSegmentedPicker(
                    options: EventFilter.allCases,
                    label: { $0.rawValue },
                    selection: $selectedFilter
                )

                if filteredEvents.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredEvents) { event in
                        eventCard(event)
                    }
                }

                // Add Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                        Text("Add Life Event").font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: MilliPalette.radius).fill(MilliPalette.accent))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Life Events")
    }

    private func eventCard(_ event: LifeEvent) -> some View {
        DKCard {
            HStack(spacing: 12) {
                Image(systemName: event.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(MilliPalette.accent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(MilliPalette.accent.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MilliPalette.textPrimary)
                    HStack(spacing: 6) {
                        Text(event.date)
                            .font(.caption2)
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text("\u{2022}")
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text(event.cost)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(MilliPalette.textPrimary)
                    }
                }

                Spacer()

                Text(event.impact.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(event.impact.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(event.impact.color.opacity(0.12)))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "calendar")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(MilliPalette.textSecondary)
            Text("No \(selectedFilter.rawValue.lowercased()) events.")
                .font(.subheadline)
                .foregroundStyle(MilliPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

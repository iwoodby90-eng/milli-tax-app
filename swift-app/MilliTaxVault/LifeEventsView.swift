import SwiftUI

struct LifeEvent: Identifiable {
    let id = UUID()
    let title: String
    let year: String
    let icon: String
    let color: Color
    let subtitle: String
    let progress: Double
    let isCompleted: Bool
}

struct LifeEventsView: View {
    @State private var selectedTab = "Timeline"
    private let tabs = ["Timeline", "Goals", "Achieved"]

    private let events: [LifeEvent] = [
        LifeEvent(title: "Buy a Home", year: "2025", icon: "house.fill", color: Color(hex: "00B4FF"), subtitle: "Saving $1,330/mo", progress: 0.35, isCompleted: false),
        LifeEvent(title: "Emergency Fund Complete", year: "2024", icon: "checkmark.shield.fill", color: Color(hex: "00C853"), subtitle: "Completed!", progress: 1.0, isCompleted: true),
        LifeEvent(title: "Kids' College Fund", year: "2030", icon: "graduationcap.fill", color: .purple, subtitle: "Saving $500/mo", progress: 0.12, isCompleted: false),
        LifeEvent(title: "Pay Off Student Loans", year: "2024", icon: "checkmark.circle.fill", color: Color(hex: "00C853"), subtitle: "Completed!", progress: 1.0, isCompleted: true),
        LifeEvent(title: "New Vehicle", year: "2026", icon: "car.fill", color: Color(hex: "FFAB00"), subtitle: "Saving $800/mo", progress: 0.60, isCompleted: false),
        LifeEvent(title: "Start Business", year: "2027", icon: "briefcase.fill", color: Color(hex: "00B4FF"), subtitle: "Planning phase", progress: 0.05, isCompleted: false),
        LifeEvent(title: "Retirement", year: "2047", icon: "sun.max.fill", color: Color(hex: "FFD700"), subtitle: "23 years away", progress: 0.02, isCompleted: false)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Life Events")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Text("+ Add Event")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00B4FF"))
                    }
                }
                .padding(.horizontal)

                // Segmented Picker
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == tab ? .white : Color(hex: "8B8BA0"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == tab
                                        ? Color(hex: "00B4FF").opacity(0.2)
                                        : Color.clear
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(4)
                .background(Color(hex: "12121A"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // Timeline
                VStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        HStack(alignment: .top, spacing: 16) {
                            // Timeline indicator
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(event.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        event.isCompleted
                                            ? Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                            : nil
                                    )

                                if index < events.count - 1 {
                                    Rectangle()
                                        .fill(Color(hex: "8B8BA0").opacity(0.3))
                                        .frame(width: 2)
                                        .frame(minHeight: 80)
                                }
                            }

                            // Event Card
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: event.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(event.color)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        Text(event.year)
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "8B8BA0"))
                                    }
                                    Spacer()
                                    if event.isCompleted {
                                        Text("Completed")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(hex: "00C853"))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(hex: "00C853").opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(event.subtitle)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "8B8BA0"))

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.white.opacity(0.08))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(event.isCompleted ? Color(hex: "00C853") : event.color)
                                            .frame(width: geo.size.width * event.progress, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text("\(Int(event.progress * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(event.color)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "12121A"))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(Color(hex: "0A0A0F"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LifeEventsView()
    }
}

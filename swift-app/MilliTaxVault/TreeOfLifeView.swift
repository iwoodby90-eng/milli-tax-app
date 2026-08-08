import SwiftUI

struct TreeOfLifeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Tree of Life")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Your Financial Journey")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "8B8BA0"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Hero Card with Tree
                VStack(spacing: 20) {
                    TreeSVGView()
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        Text("Growing Strong")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00C853"))
                        Text("Est. Net Worth: $224,560")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D1A12"), Color(hex: "0A0A0F")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // 3 Stat Pills
                HStack(spacing: 12) {
                    StatPillView(value: "7", label: "Life Events", icon: "calendar.badge.clock", color: Color(hex: "00B4FF"))
                    StatPillView(value: "85%", label: "Goal Progress", icon: "target", color: Color(hex: "00C853"))
                    StatPillView(value: "2047", label: "Retire", icon: "person.fill", color: .purple)
                }
                .padding(.horizontal)

                // Upcoming Milestones
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upcoming Milestones")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        MilestoneCardView(
                            icon: "house",
                            iconColor: Color(hex: "00B4FF"),
                            title: "Buy a Home",
                            timeline: "2025 - In 8 months",
                            estimate: "Est. $380,000",
                            progress: 0.35
                        )
                        MilestoneCardView(
                            icon: "graduationcap",
                            iconColor: Color(hex: "00C853"),
                            title: "Kids' College Fund",
                            timeline: "2030 - 6 years",
                            estimate: "Est. $120,000",
                            progress: 0.12
                        )
                        MilestoneCardView(
                            icon: "car.fill",
                            iconColor: .purple,
                            title: "New Vehicle",
                            timeline: "2026 - 18 months",
                            estimate: "Est. $45,000",
                            progress: 0.60
                        )
                    }
                    .padding(.horizontal)
                }

                // Navigation Link Button
                NavigationLink(destination: LifeEventsView()) {
                    Text("View Life Events →")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "00B4FF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "00B4FF").opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00B4FF").opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(Color(hex: "0A0A0F"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stat Pill
struct StatPillView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(hex: "8B8BA0"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "12121A"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Milestone Card
struct MilestoneCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let timeline: String
    let estimate: String
    let progress: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(timeline)
                    .font(.caption)
                    .foregroundColor(Color(hex: "8B8BA0"))
                Text(estimate)
                    .font(.caption)
                    .foregroundColor(Color(hex: "8B8BA0"))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(iconColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(iconColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "12121A"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        TreeOfLifeView()
    }
}

import SwiftUI

struct YourFutureView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Future")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("In the year 2047...")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00B4FF"), .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Hero Projection Card
                VStack(spacing: 16) {
                    Spacer().frame(height: 20)

                    Text("2047")
                        .font(.system(size: 80, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00B4FF"), .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Age 62")
                        .font(.title3)
                        .foregroundColor(Color(hex: "8B8BA0"))

                    Text("$1,623,587")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "00C853"))

                    Text("Projected Net Worth")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8B8BA0"))

                    Spacer().frame(height: 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D1520"), Color(hex: "0A0A0F")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // Milestone Achievement Cards
                HStack(spacing: 12) {
                    AchievementBadgeView(
                        title: "Debt Free",
                        subtitle: "Since 2026",
                        icon: "checkmark.circle.fill",
                        color: Color(hex: "00C853")
                    )
                    AchievementBadgeView(
                        title: "Home Owner",
                        subtitle: "Since 2025",
                        icon: "house.circle.fill",
                        color: Color(hex: "00B4FF")
                    )
                    AchievementBadgeView(
                        title: "College Funded",
                        subtitle: "2 kids",
                        icon: "graduationcap.circle.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Path to 2047
                VStack(alignment: .leading, spacing: 16) {
                    Text("Path to 2047")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        FutureStepView(
                            year: "2025",
                            title: "Buy Home",
                            icon: "house.fill",
                            color: Color(hex: "00B4FF"),
                            status: "In progress",
                            isLast: false
                        )
                        FutureStepView(
                            year: "2026",
                            title: "Debt Free",
                            icon: "checkmark",
                            color: Color(hex: "00C853"),
                            status: "On track",
                            isLast: false
                        )
                        FutureStepView(
                            year: "2030",
                            title: "$100K invested",
                            icon: "chart.bar.fill",
                            color: Color(hex: "00B4FF"),
                            status: "On track",
                            isLast: false
                        )
                        FutureStepView(
                            year: "2035",
                            title: "Max 401(k)",
                            icon: "banknote.fill",
                            color: .purple,
                            status: "Projected",
                            isLast: false
                        )
                        FutureStepView(
                            year: "2047",
                            title: "Retirement",
                            icon: "sun.max.fill",
                            color: Color(hex: "FFD700"),
                            status: "The Goal",
                            isLast: true
                        )
                    }
                    .padding(.horizontal)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // Share button - ghost style
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Your Future")
                        }
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "00B4FF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00B4FF"), lineWidth: 1.5)
                        )
                    }

                    // Adjust Plan - filled
                    NavigationLink(destination: PlanningAdjustmentsView()) {
                        Text("Adjust Plan")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "00B4FF"))
                            .cornerRadius(12)
                    }
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

// MARK: - Achievement Badge
struct AchievementBadgeView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Color(hex: "8B8BA0"))
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

// MARK: - Future Step
struct FutureStepView: View {
    let year: String
    let title: String
    let icon: String
    let color: Color
    let status: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Stepper indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "8B8BA0").opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(year)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    Text("—")
                        .foregroundColor(Color(hex: "8B8BA0"))
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                Text(status)
                    .font(.caption)
                    .foregroundColor(Color(hex: "8B8BA0"))
            }
            .padding(.top, 6)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        YourFutureView()
    }
}

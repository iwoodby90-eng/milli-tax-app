import SwiftUI

struct PlanningAdjustmentsView: View {
    @State private var monthlyBudget: Double = 7500
    @State private var housingPercent: Double = 30
    @State private var investingPercent: Double = 20
    @State private var savingsPercent: Double = 15
    @State private var lifestylePercent: Double = 20
    @State private var emergencyMonths: Int = 6
    @State private var emergencyTarget: Double = 25000

    private var allocatedPercent: Double {
        housingPercent + investingPercent + savingsPercent + lifestylePercent
    }

    private var allocatedAmount: Double {
        monthlyBudget * (allocatedPercent / 100.0)
    }

    private var remainingAmount: Double {
        monthlyBudget - allocatedAmount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Planning")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Adjust Your Plan")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "8B8BA0"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Monthly Budget Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Budget")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("$\(Int(monthlyBudget).formatted())/month")
                        .font(.headline)
                        .foregroundColor(Color(hex: "00B4FF"))

                    Slider(value: $monthlyBudget, in: 1000...20000, step: 100)
                        .tint(Color(hex: "00B4FF"))
                }
                .padding(16)
                .background(Color(hex: "12121A"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // Allocation Sliders
                VStack(spacing: 16) {
                    AllocationSliderView(
                        category: "Housing",
                        icon: "house.fill",
                        color: Color(hex: "00B4FF"),
                        percent: $housingPercent,
                        maxPercent: 50,
                        budget: monthlyBudget
                    )
                    AllocationSliderView(
                        category: "Investing",
                        icon: "chart.line.uptrend.xyaxis",
                        color: Color(hex: "00C853"),
                        percent: $investingPercent,
                        maxPercent: 40,
                        budget: monthlyBudget
                    )
                    AllocationSliderView(
                        category: "Savings",
                        icon: "banknote.fill",
                        color: .purple,
                        percent: $savingsPercent,
                        maxPercent: 30,
                        budget: monthlyBudget
                    )
                    AllocationSliderView(
                        category: "Lifestyle",
                        icon: "person.fill",
                        color: Color(hex: "FFAB00"),
                        percent: $lifestylePercent,
                        maxPercent: 30,
                        budget: monthlyBudget
                    )
                }
                .padding(.horizontal)

                // Computed Totals Card
                VStack(spacing: 14) {
                    HStack {
                        Text("Allocated")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "8B8BA0"))
                        Spacer()
                        Text("$\(Int(allocatedAmount).formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    // Allocation bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    allocatedPercent > 100
                                        ? Color(hex: "FF3D57")
                                        : Color(hex: "00B4FF")
                                )
                                .frame(width: geo.size.width * min(allocatedPercent / 100.0, 1.0), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(allocatedPercent))% allocated")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8B8BA0"))

                    Divider()
                        .background(Color.white.opacity(0.08))

                    HStack {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "8B8BA0"))
                        Spacer()
                        Text("$\(Int(remainingAmount).formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00C853"))
                    }
                }
                .padding(16)
                .background(Color(hex: "12121A"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // Emergency Fund Goal
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Fund Goal")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Amount")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8B8BA0"))
                            Text("$\(Int(emergencyTarget).formatted())")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8B8BA0"))
                            Picker("Months", selection: $emergencyMonths) {
                                ForEach(3...12, id: \.self) { month in
                                    Text("\(month) months")
                                        .tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "00B4FF"))
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "12121A"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                // Save Plan Button
                Button(action: {}) {
                    Text("Save Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "00B4FF"))
                        .cornerRadius(12)
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

// MARK: - Allocation Slider
struct AllocationSliderView: View {
    let category: String
    let icon: String
    let color: Color
    @Binding var percent: Double
    let maxPercent: Double
    let budget: Double

    private var amount: Double {
        budget * (percent / 100.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Text("$\(Int(amount).formatted())")
                    .font(.subheadline)
                    .foregroundColor(color)
                Text("(\(Int(percent))%)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "8B8BA0"))
            }

            Slider(value: $percent, in: 0...maxPercent, step: 1)
                .tint(color)
        }
        .padding(14)
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
        PlanningAdjustmentsView()
    }
}

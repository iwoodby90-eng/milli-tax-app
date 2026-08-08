//
//  MilliCentsView.swift
//  MilliTaxVault
//
//  Savings Goals / Round-ups tracker with circular progress ring
//

import SwiftUI

struct MilliCentsView: View {
    private let goals: [SavingsGoal] = [
        SavingsGoal(
            name: "Emergency Fund",
            icon: "shield.fill",
            iconColor: MilliColors.accent,
            current: 4500,
            target: 10000,
            percentage: 0.45
        ),
        SavingsGoal(
            name: "Vacation",
            icon: "airplane",
            iconColor: Color(hex: "A855F7"),
            current: 1200,
            target: 3000,
            percentage: 0.40
        ),
        SavingsGoal(
            name: "New Equipment",
            icon: "wrench.and.screwdriver.fill",
            iconColor: Color(hex: "F59E0B"),
            current: 380,
            target: 2500,
            percentage: 0.15
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                progressRing
                savingsGoalsSection
                roundUpSummaryCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .background(MilliColors.background)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Milli Cents")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text("Automatic Savings")
                .font(.system(size: 15))
                .foregroundColor(MilliColors.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Circular Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(MilliColors.muted.opacity(0.2), lineWidth: 16)
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0, to: 0.70)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "00B4FF"),
                            Color(hex: "00D4AA"),
                            Color(hex: "00B4FF")
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(252)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("$1,847")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text("saved this year")
                    .font(.caption)
                    .foregroundColor(MilliColors.muted)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Savings Goals

    private var savingsGoalsSection: some View {
        VStack(spacing: 12) {
            ForEach(goals) { goal in
                savingsGoalCard(goal: goal)
            }
        }
    }

    private func savingsGoalCard(goal: SavingsGoal) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: goal.icon)
                    .font(.system(size: 16))
                    .foregroundColor(goal.iconColor)
                    .frame(width: 32, height: 32)
                    .background(goal.iconColor.opacity(0.15))
                    .cornerRadius(8)

                Text(goal.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(goal.percentage * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(goal.iconColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MilliColors.muted.opacity(0.2))
                        .frame(height: 6)

                    Capsule()
                        .fill(goal.iconColor)
                        .frame(width: geo.size.width * goal.percentage, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("$\(goal.current, specifier: "%.0f") of $\(goal.target, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(MilliColors.muted)
                Spacer()
            }
        }
        .padding(16)
        .milliCard()
    }

    // MARK: - Round-Up Summary

    private var roundUpSummaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("This Week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            roundUpRow(label: "89 transactions rounded up", amount: "+$47.32", color: .white)
            roundUpRow(label: "Matched contributions", amount: "+$47.32", color: MilliColors.green)

            Divider()
                .background(Color.white.opacity(0.08))

            HStack {
                Text("Total saved this week")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text("+$94.64")
                    .font(.headline)
                    .foregroundColor(MilliColors.green)
            }
        }
        .padding(16)
        .milliCard()
    }

    private func roundUpRow(label: String, amount: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(MilliColors.muted)
            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Savings Goal Model

struct SavingsGoal: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let iconColor: Color
    let current: Double
    let target: Double
    let percentage: Double
}

// MARK: - Preview

#Preview {
    MilliCentsView()
}

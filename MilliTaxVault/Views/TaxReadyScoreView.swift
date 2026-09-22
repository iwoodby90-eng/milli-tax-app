import SwiftUI

// MARK: - TaxReadyScoreView
// Readiness instrument in the approved Milli language. Every factor reflects
// state Milli can actually observe on this account — a connected bank, a saved
// tax profile, recorded expenses and trips, and reserve pace against the
// year. Nothing is seeded, so a fresh account reads zero rather than a score.

struct TaxReadyScoreView: View {
    var onBack: () -> Void = {}

    private var showsReferenceData: Bool { ReferenceDataPolicy.allowsDemoReferenceData }

    private var score: Int {
        guard !factors.isEmpty else { return 0 }
        return Int((Double(completedCount) / Double(factors.count) * 100).rounded())
    }

    private var readiness: ReadinessState {
        ReadinessState(score: score)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                if showsReferenceData {
                    scoreGauge
                    factorList
                    history
                } else {
                    unavailableState
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background { MilliAmbientBackground() }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Tax Ready Score™")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            ProvenanceTag(label: ReferenceDataPolicy.provenance)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 10)
                    .frame(width: 126, height: 126)
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text("Tax Ready Score is awaiting verified data")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                "Connect income, expenses, mileage, tax payments, and documents. Milli will " +
                "calculate your score from those records rather than seeded reference factors."
            )
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .milliCard(padding: 18)
    }

    private var scoreGauge: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 11)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [MilliColors.deepCyan, MilliColors.cyanGlow, readiness.color],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 8)

                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.custom("Sora-Bold", size: 42, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(readiness.title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(readiness.color)
                }
            }
            .frame(width: 176, height: 176)

            Text(readiness.message)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tax Ready Score \(score) out of 100. \(readiness.title). \(readiness.message)")
    }

    private var factorList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SCORE FACTORS")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(completedCount) of \(factors.count) complete")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(factors.enumerated()), id: \.element.id) { index, factor in
                    HStack(spacing: 9) {
                        Image(systemName: factor.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(factor.state.color)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(factor.state.color.opacity(0.09)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(factor.name)
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text(factor.detail)
                                .font(MilliFont.caption)
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Spacer()

                        Text(factor.state.label)
                            .font(MilliFont.caption)
                            .foregroundStyle(factor.state.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if index < factors.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 46)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private var methodology: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(MilliColors.deepCyan)

            Text("Your score is the share of readiness factors Milli can verify on this account. History appears once your score has been tracked across a full tax season.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .milliCard(padding: 14)
    }
}

private struct ReadinessFactor: Identifiable {
    enum State: Equatable {
        case complete
        case attention
        case pending

        var label: String {
            switch self {
            case .complete: return "Complete"
            case .attention: return "Needs Attention"
            case .pending: return "Not Set Up"
            }
        }

        var color: Color {
            switch self {
            case .complete: return MilliColors.positive
            case .attention: return MilliColors.warning
            case .pending: return MilliColors.textTertiary
            }
        }
    }

    let id = UUID()
    let name: String
    let icon: String
    let state: State
    let detail: String
}

private struct ReadinessState {
    let score: Int

    var title: String {
        switch score {
        case 100: return "Complete"
        case 80..<100: return "Great"
        case 60..<80: return "Good"
        case 1..<60: return "Getting Started"
        default: return "Not Started"
        }
    }

    var message: String {
        switch score {
        case 100: return "Every readiness factor is in place"
        case 60..<100: return "Finish the remaining factors to be fully tax ready"
        case 1..<60: return "Complete the factors below to build your readiness"
        default: return "Connect a bank and add your tax profile to begin"
        }
    }

    var color: Color {
        switch score {
        case 80...: return MilliColors.positive
        case 40..<80: return MilliColors.warning
        default: return MilliColors.textTertiary
        }
    }
}

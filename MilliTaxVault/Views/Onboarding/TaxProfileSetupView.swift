import SwiftUI

// MARK: - TaxProfileSetupView — Onboarding Step 3
// Collects the minimum planning inputs required for Milli's tax estimates.

struct TaxProfileSetupView: View {
    @Binding var taxProfile: TaxProfile
    var onNext: () -> Void
    var onBack: () -> Void

    @FocusState private var incomeFocused: Bool

    private let states: [(code: String, name: String)] = [
        ("AL", "Alabama"), ("AK", "Alaska"), ("AZ", "Arizona"), ("AR", "Arkansas"),
        ("CA", "California"), ("CO", "Colorado"), ("CT", "Connecticut"), ("DE", "Delaware"),
        ("FL", "Florida"), ("GA", "Georgia"), ("HI", "Hawaii"), ("ID", "Idaho"),
        ("IL", "Illinois"), ("IN", "Indiana"), ("IA", "Iowa"), ("KS", "Kansas"),
        ("KY", "Kentucky"), ("LA", "Louisiana"), ("ME", "Maine"), ("MD", "Maryland"),
        ("MA", "Massachusetts"), ("MI", "Michigan"), ("MN", "Minnesota"), ("MS", "Mississippi"),
        ("MO", "Missouri"), ("MT", "Montana"), ("NE", "Nebraska"), ("NV", "Nevada"),
        ("NH", "New Hampshire"), ("NJ", "New Jersey"), ("NM", "New Mexico"), ("NY", "New York"),
        ("NC", "North Carolina"), ("ND", "North Dakota"), ("OH", "Ohio"), ("OK", "Oklahoma"),
        ("OR", "Oregon"), ("PA", "Pennsylvania"), ("RI", "Rhode Island"), ("SC", "South Carolina"),
        ("SD", "South Dakota"), ("TN", "Tennessee"), ("TX", "Texas"), ("UT", "Utah"),
        ("VT", "Vermont"), ("VA", "Virginia"), ("WA", "Washington"), ("WV", "West Virginia"),
        ("WI", "Wisconsin"), ("WY", "Wyoming"), ("DC", "District of Columbia")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                taxProfileSummary
                stateSelector
                filingStatusSelector
                incomeField
                workProfile
                navigation
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, 22)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TAX PROFILE")
                .font(MilliFont.sectionLabel)
                .tracking(1.0)
                .foregroundStyle(MilliColors.cyanGlow)

            Text("Build your tax baseline.")
                .font(.custom("Sora-Bold", size: 29, relativeTo: .largeTitle))
                .foregroundStyle(MilliColors.textPrimary)

            Text("Your state, filing status, and estimated annual income give Milli the starting context for tax-reserve and quarterly planning.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var taxProfileSummary: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 50, height: 50)
                Circle()
                    .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 0.8)
                    .frame(width: 50, height: 50)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(taxProfile.isValid ? "Tax profile ready" : "Complete your baseline")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)

                Text(summaryLine)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: taxProfile.isValid ? "checkmark.seal.fill" : "circle.dotted")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(taxProfile.isValid ? MilliColors.positive : MilliColors.textTertiary)
        }
        .milliCard(padding: 12)
    }

    private var summaryLine: String {
        let state = taxProfile.state.isEmpty ? "State needed" : taxProfile.state
        let income: String
        if let amount = taxProfile.annualIncomeAmount {
            income = amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        } else {
            income = "Income needed"
        }
        return "\(state) • \(taxProfile.filingStatus.shortLabel) • \(income)"
    }

    private var stateSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STATE")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            Menu {
                ForEach(states, id: \.code) { state in
                    Button {
                        taxProfile.state = state.code
                    } label: {
                        if taxProfile.state == state.code {
                            Label("\(state.name) (\(state.code))", systemImage: "checkmark")
                        } else {
                            Text("\(state.name) (\(state.code))")
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(taxProfile.state.isEmpty ? MilliColors.textTertiary : MilliColors.cyanGlow)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedStateName)
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(taxProfile.state.isEmpty ? MilliColors.textTertiary : MilliColors.textPrimary)
                        if !taxProfile.state.isEmpty {
                            Text("Used for state-tax planning")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MilliColors.textTertiary)
                }
                .padding(.horizontal, 12)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.white.opacity(0.032))
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(taxProfile.state.isEmpty ? Color.white.opacity(0.07) : MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.75)
                        }
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedStateName: String {
        guard let match = states.first(where: { $0.code == taxProfile.state }) else {
            return "Select your state"
        }
        return "\(match.name) (\(match.code))"
    }

    private var filingStatusSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("FILING STATUS")
                .sectionHeaderStyle()

            VStack(spacing: 6) {
                ForEach(TaxProfile.FilingStatus.allCases, id: \.self) { status in
                    let selected = taxProfile.filingStatus == status

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            taxProfile.filingStatus = status
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .stroke(selected ? MilliColors.cyanGlow : Color.white.opacity(0.15), lineWidth: 1.4)
                                    .frame(width: 20, height: 20)
                                if selected {
                                    Circle()
                                        .fill(MilliColors.cyanGlow)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 3)
                                }
                            }

                            Text(status.rawValue)
                                .font(MilliFont.bodyMedium)
                                .foregroundStyle(selected ? MilliColors.textPrimary : MilliColors.textSecondary)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 43)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? MilliColors.cyanGlow.opacity(0.055) : Color.white.opacity(0.02))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(selected ? MilliColors.cyanGlow.opacity(0.22) : Color.white.opacity(0.055), lineWidth: 0.7)
                                }
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var incomeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ESTIMATED ANNUAL GIG INCOME")
                .font(MilliFont.sectionLabel)
                .tracking(0.65)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 8) {
                Text("$")
                    .font(MilliFont.numericSmall)
                    .foregroundStyle(MilliColors.cyanGlow)

                TextField("75,000", text: $taxProfile.estimatedAnnualIncome)
                    .font(MilliFont.bodyMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($incomeFocused)
                    .tint(MilliColors.cyanGlow)

                if taxProfile.annualIncomeAmount != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MilliColors.positive)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.032))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(incomeFocused ? MilliColors.cyanGlow.opacity(0.42) : Color.white.opacity(0.07), lineWidth: incomeFocused ? 0.9 : 0.7)
                    }
            )

            Text("Use a reasonable annual estimate. You can update this as your income changes.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
    }

    private var workProfile: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("WORK PROFILE")
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                profileToggle(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Self-Employed / 1099",
                    subtitle: "Include self-employment tax planning",
                    isOn: $taxProfile.isSelfEmployed
                )

                Divider().overlay(Color.white.opacity(0.055)).padding(.leading, 52)

                profileToggle(
                    icon: "car.2.fill",
                    title: "Multiple Vehicles",
                    subtitle: "Prepare the mileage profile for more than one vehicle",
                    isOn: $taxProfile.hasMultipleVehicles
                )
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private func profileToggle(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(MilliColors.cyanGlow.opacity(0.07)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(MilliColors.cyanGlow)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
    }

    private var navigation: some View {
        HStack(spacing: 12) {
            OnboardingBackButton(action: onBack)

            Button(action: submit) {
                HStack(spacing: 7) {
                    Text("CONTINUE")
                        .font(.custom("Sora-SemiBold", size: 14, relativeTo: .headline))
                        .tracking(0.55)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(taxProfile.isValid ? MilliColors.blackGlass : MilliColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(taxProfile.isValid ? MilliColors.cyanGlow : Color.white.opacity(0.05))
                        .shadow(color: taxProfile.isValid ? MilliColors.cyanGlow.opacity(0.20) : .clear, radius: 8)
                )
            }
            .buttonStyle(.plain)
            .disabled(!taxProfile.isValid)
        }
        .padding(.top, 2)
    }

    private func submit() {
        incomeFocused = false
        guard taxProfile.isValid else { return }
        onNext()
    }
}

#Preview {
    TaxProfileSetupView(
        taxProfile: .constant(TaxProfile()),
        onNext: {},
        onBack: {}
    )
    .background(MilliColors.obsidian.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

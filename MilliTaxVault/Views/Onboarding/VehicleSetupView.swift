import SwiftUI

// MARK: - VehicleSetupView — Onboarding Step 2
// Collects the vehicle identity Milli uses to organize mileage records.

struct VehicleSetupView: View {
    @Binding var vehicle: VehicleProfile
    var onNext: () -> Void
    var onBack: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case year, make, model, odometer
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                vehiclePreview
                identityFields
                vehicleUseSelector
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
            Text("VEHICLE PROFILE")
                .font(MilliFont.sectionLabel)
                .tracking(1.0)
                .foregroundStyle(MilliColors.cyanGlow)

            Text("What are you driving?")
                .font(.custom("Sora-Bold", size: 29, relativeTo: .largeTitle))
                .foregroundStyle(MilliColors.textPrimary)

            Text("Milli associates tracked business miles and deduction records with this vehicle. You can add additional vehicles later.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var vehiclePreview: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.cardBackground, MilliColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 66, height: 66)
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 0.8)
                    }

                Image(systemName: "car.side.fill")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.silverBright, MilliColors.chromeMid],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vehicle.displayName)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(vehicle.odometerReading.isEmpty ? "Odometer not entered" : "Odometer • \(vehicle.odometerReading) mi")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(vehicle.isValid ? MilliColors.positive : MilliColors.warning)
                        .frame(width: 5, height: 5)
                    Text(vehicle.isValid ? "Vehicle ready" : "Complete year, make, and model")
                        .font(MilliFont.caption)
                        .foregroundStyle(vehicle.isValid ? MilliColors.positive : MilliColors.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .milliCard(padding: 12)
    }

    private var identityFields: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("VEHICLE DETAILS")
                .sectionHeaderStyle()

            HStack(spacing: 9) {
                field(
                    label: "YEAR",
                    placeholder: "2024",
                    text: $vehicle.year,
                    field: .year,
                    keyboard: .numberPad
                )
                .frame(maxWidth: 104)

                field(
                    label: "MAKE",
                    placeholder: "Honda",
                    text: $vehicle.make,
                    field: .make
                )
            }

            field(
                label: "MODEL",
                placeholder: "Accord",
                text: $vehicle.model,
                field: .model
            )

            field(
                label: "CURRENT ODOMETER",
                placeholder: "45,000",
                text: $vehicle.odometerReading,
                field: .odometer,
                keyboard: .numberPad,
                suffix: "MI"
            )
        }
    }

    private func field(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType = .default,
        suffix: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(MilliFont.sectionLabel)
                .tracking(0.65)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 8) {
                TextField(placeholder, text: text)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(field == .year || field == .odometer ? .never : .words)
                    .autocorrectionDisabled(field == .year || field == .odometer)
                    .focused($focusedField, equals: field)
                    .tint(MilliColors.cyanGlow)

                if let suffix, !text.wrappedValue.isEmpty {
                    Text(suffix)
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.032))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(
                                focusedField == field ? MilliColors.cyanGlow.opacity(0.42) : Color.white.opacity(0.07),
                                lineWidth: focusedField == field ? 0.9 : 0.7
                            )
                    }
                    .shadow(color: focusedField == field ? MilliColors.cyanGlow.opacity(0.08) : .clear, radius: 6)
            )
        }
    }

    private var vehicleUseSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VEHICLE USE")
                .sectionHeaderStyle()

            HStack(spacing: 7) {
                ForEach(VehicleProfile.VehicleUse.allCases, id: \.self) { use in
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            vehicle.vehicleUse = use
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: use.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(use.rawValue)
                                .font(.custom("Inter-Medium", size: 10, relativeTo: .caption))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(vehicle.vehicleUse == use ? MilliColors.blackGlass : MilliColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(vehicle.vehicleUse == use ? MilliColors.cyanGlow : Color.white.opacity(0.025))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .stroke(
                                            vehicle.vehicleUse == use ? MilliColors.cyanGlow : Color.white.opacity(0.065),
                                            lineWidth: 0.75
                                        )
                                }
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(vehicle.vehicleUse == use ? .isSelected : [])
                }
            }

            Text("Use describes how this vehicle is normally used. Individual trips can still be classified separately.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                .foregroundStyle(vehicle.isValid ? MilliColors.blackGlass : MilliColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(vehicle.isValid ? MilliColors.cyanGlow : Color.white.opacity(0.05))
                        .shadow(color: vehicle.isValid ? MilliColors.cyanGlow.opacity(0.20) : .clear, radius: 8)
                )
            }
            .buttonStyle(.plain)
            .disabled(!vehicle.isValid)
        }
        .padding(.top, 2)
    }

    private func submit() {
        focusedField = nil
        guard vehicle.isValid else { return }
        onNext()
    }
}

#Preview {
    VehicleSetupView(
        vehicle: .constant(VehicleProfile()),
        onNext: {},
        onBack: {}
    )
    .background(MilliColors.obsidian.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

import SwiftUI
import MapKit

// MARK: - MileageView — Screen 3: Active mileage tracking
// Header + status | Big stat | Map | Trip stats | Net profit | GO button

struct MileageView: View {
    var onBack: () -> Void = {}
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                trackingStatusChip
                currentTripHero
                tripStatsRow
                mapSection
                tripDetailRows
                netProfitCard
                goButton
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.textSecondary)
            }
            .buttonStyle(.plain)

            Text("Mileage Tracking")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Tracking Active Chip

    private var trackingStatusChip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MilliColors.positive)
                .frame(width: 8, height: 8)
            Text("Tracking Active")
                .font(MilliFont.labelLarge)
                .foregroundColor(MilliColors.positive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(MilliColors.positive.opacity(0.12))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Current Trip Hero

    private var currentTripHero: some View {
        VStack(spacing: 4) {
            Text("18.64 mi")
                .font(MilliFont.heroNumber)
                .foregroundColor(MilliColors.cyanGlow)
            Text("Current Trip")
                .font(MilliFont.bodySmall)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trip Stats Row

    private var tripStatsRow: some View {
        HStack {
            VStack(spacing: 4) {
                Text("00:48:26")
                    .font(MilliFont.numericSmall)
                    .foregroundColor(MilliColors.textPrimary)
                Text("Duration")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(MilliColors.border)
                .frame(width: 1, height: 36)

            VStack(spacing: 4) {
                Text("$9.82")
                    .font(MilliFont.numericSmall)
                    .foregroundColor(MilliColors.cyanGlow)
                Text("Est. Deduction")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .milliCard()
    }

    // MARK: - Map

    private var mapSection: some View {
        Map(coordinateRegion: .constant(region))
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .stroke(MilliColors.cardBorderGlow, lineWidth: 1)
            )
            .colorScheme(.dark)
    }

    // MARK: - Trip Detail Rows

    private var tripDetailRows: some View {
        VStack(spacing: MilliSpacing.sm) {
            tripDetailRow(label: "THIS TRIP", miles: "18.64 mi", deduction: "$9.82")
            tripDetailRow(label: "TODAY", miles: "126.37 mi", deduction: "$66.41")
        }
    }

    private func tripDetailRow(label: String, miles: String, deduction: String) -> some View {
        HStack {
            Text(label)
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(0.8)

            Spacer()

            Text(miles)
                .font(MilliFont.numericSmall)
                .foregroundColor(MilliColors.textPrimary)

            Text("|")
                .foregroundColor(MilliColors.textTertiary)
                .padding(.horizontal, 6)

            Text(deduction)
                .font(MilliFont.numericSmall)
                .foregroundColor(MilliColors.cyanGlow)
        }
        .padding(MilliSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                .fill(MilliColors.cardBackground)
        )
    }

    // MARK: - Net Profit Card

    private var netProfitCard: some View {
        VStack(spacing: 6) {
            Text("NET PROFIT")
                .font(MilliFont.label)
                .foregroundColor(MilliColors.textLabel)
                .tracking(1)

            Text("$21.56")
                .font(MilliFont.numericLarge)
                .foregroundColor(MilliColors.positive)

            Text("$0.56 per mile")
                .font(MilliFont.bodySmall)
                .foregroundColor(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: MilliSpacing.cardPaddingLarge)
    }

    // MARK: - GO Button

    private var goButton: some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                VStack(spacing: 2) {
                    Text("GO")
                        .font(MilliFont.headline)
                    Text("Profitable Offer")
                        .font(MilliFont.caption)
                }
            }
            .foregroundColor(MilliColors.blackGlass)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.positive, Color(hex: "00D68F")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

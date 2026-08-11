import SwiftUI
import Combine

struct MileageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MileageViewModel()

    private let recentTrips: [(date: String, miles: Double, earnings: Double, deduction: Double)] = [
        ("Aug 10, 2026", 42.3, 68.50, 27.94),
        ("Aug 9, 2026", 38.1, 52.00, 25.17),
        ("Aug 8, 2026", 55.8, 84.20, 36.83),
        ("Aug 7, 2026", 29.4, 41.00, 19.42),
        ("Aug 6, 2026", 61.2, 92.75, 40.39),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                activeTripCard
                weekSummaryGrid
                recentTripsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Mileage")
        .task { await viewModel.loadMileage() }
    }

    // MARK: - Active Trip

    private var activeTripCard: some View {
        DKCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Active Trip")
                                .font(.headline)
                                .foregroundStyle(MilliPalette.textPrimary)
                            if viewModel.isTracking {
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(MilliPalette.positive)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(MilliPalette.positive.opacity(0.15)))
                            }
                        }
                        Text(viewModel.activeTripMiles)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(MilliPalette.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("00:48:26")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundStyle(MilliPalette.textSecondary)
                    }
                }

                Button(action: {
                    Task {
                        if viewModel.isTracking { await viewModel.stopTracking() }
                        else { await viewModel.startTracking() }
                    }
                }) {
                    Text(viewModel.isTracking ? "Stop Tracking" : "Start Tracking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isTracking ? MilliPalette.negative : MilliPalette.accent)
                        )
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                .stroke(viewModel.isTracking ? MilliPalette.accent : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Week Summary

    private var weekSummaryGrid: some View {
        HStack(spacing: 10) {
            MilliStatTile(title: "Miles", value: "226.8 mi", accent: MilliPalette.textPrimary)
            MilliStatTile(title: "Deduction", value: "$149.75", accent: MilliPalette.positive)
            MilliStatTile(title: "Trips", value: "12", accent: MilliPalette.accent)
        }
    }

    // MARK: - Recent Trips

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trips")
                .font(.headline)
                .foregroundStyle(MilliPalette.textPrimary)

            ForEach(Array(recentTrips.enumerated()), id: \.offset) { _, trip in
                DKCard {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(trip.date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text(String(format: "%.1f miles", trip.miles))
                                .font(.caption)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(milliCurrency(trip.earnings))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text("-\(milliCurrency(trip.deduction))")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(MilliPalette.positive)
                        }
                    }
                }
            }
        }
    }
}

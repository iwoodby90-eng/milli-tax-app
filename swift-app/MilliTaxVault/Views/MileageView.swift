import SwiftUI

struct MileageView: View {
    @State private var isTracking = false
    @State private var totalMiles: Double = 1_247.6
    @State private var totalDeduction: Double = 831.77
    @State private var todayMiles: Double = 24.8
    @State private var trips: [MileageTrip] = [
        MileageTrip(startTime: "2:14 PM", endTime: "3:42 PM", miles: 24.8, deduction: 16.55, status: "completed"),
        MileageTrip(startTime: "10:30 AM", endTime: "11:15 AM", miles: 12.2, deduction: 8.14, status: "completed"),
        MileageTrip(startTime: "8:00 AM", endTime: "9:22 AM", miles: 18.6, deduction: 12.41, status: "completed"),
    ]

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    MilliPageHeader(title: "Mileage")

                    // Track button
                    trackingCard

                    // Stats
                    statsRow

                    // Recent trips
                    tripsSection

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Tracking Card

    private var trackingCard: some View {
        DKCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isTracking ? "Tracking..." : "Ready to Drive")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(isTracking ? "\(String(format: "%.1f", todayMiles)) mi today" : "Tap to start tracking")
                            .font(.system(size: 12))
                            .foregroundColor(MilliPalette.textSecondary)
                    }
                    Spacer()
                    if isTracking {
                        Circle()
                            .fill(MilliPalette.positive)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(MilliPalette.positive.opacity(0.3), lineWidth: 4)
                            )
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isTracking.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isTracking ? "stop.fill" : "location.fill")
                            .font(.system(size: 14))
                        Text(isTracking ? "Stop Tracking" : "Start Tracking")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(isTracking ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isTracking ? MilliPalette.negative : MilliPalette.accent)
                    )
                    .shadow(color: (isTracking ? MilliPalette.negative : MilliPalette.accent).opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            MilliStatTile(title: "Total Miles", value: String(format: "%.0f mi", totalMiles), accent: .white)
            MilliStatTile(title: "Deduction", value: milliCurrency(totalDeduction), accent: MilliPalette.positive)
        }
    }

    // MARK: - Trips

    private var tripsSection: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Trips")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                ForEach(trips) { trip in
                    tripRow(trip)
                    if trip.id != trips.last?.id {
                        Divider().background(MilliPalette.cardBorder)
                    }
                }
            }
        }
    }

    private func tripRow(_ trip: MileageTrip) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliPalette.accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "car.fill")
                    .font(.system(size: 14))
                    .foregroundColor(MilliPalette.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(trip.startTime) - \(trip.endTime ?? "...")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(String(format: "%.1f mi", trip.miles))
                    .font(.system(size: 11))
                    .foregroundColor(MilliPalette.textSecondary)
            }
            Spacer()
            Text(milliCurrency(trip.deduction, fraction: 2))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(MilliPalette.positive)
        }
        .padding(.vertical, 4)
    }
}

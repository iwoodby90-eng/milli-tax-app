import SwiftUI

struct MileageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MileageViewModel()

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with LIVE badge
                HStack {
                    Spacer()
                    Text("Mileage Tracking")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    // LIVE badge
                    if viewModel.isTracking {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.3)
                            .foregroundColor(.milliGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.milliGreen.opacity(0.15))
                            .cornerRadius(4)
                            .padding(.leading, 6)
                    }

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        trackingStatus
                        activeTripCard
                        mapPlaceholder
                        todayStatsRow
                        trackingButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .task { await viewModel.loadMileage() }
    }

    // MARK: - Tracking Status

    private var trackingStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isTracking ? Color.milliGreen : Color.milliTextTertiary)
                .frame(width: 8, height: 8)
            Text(viewModel.trackingStatus)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.isTracking ? .milliGreen : .milliTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Active Trip Card

    private var activeTripCard: some View {
        MilliCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE TRIP MILES")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.5)
                            .foregroundColor(.milliTextSecondary)
                        Text(viewModel.activeTripMiles)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DURATION")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.3)
                            .foregroundColor(.milliTextSecondary)
                        Text("00:48:26")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEDUCTIONS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.3)
                            .foregroundColor(.milliTextSecondary)
                        Text(viewModel.activeTripDeduction)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.milliGreen)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Map Placeholder

    private var mapPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.milliCard)
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                )

            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.7))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.85, y: size.height * 0.3),
                    control1: CGPoint(x: size.width * 0.35, y: size.height * 0.2),
                    control2: CGPoint(x: size.width * 0.65, y: size.height * 0.8)
                )
                context.stroke(
                    path,
                    with: .color(.milliCyan.opacity(0.6)),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )

                let startPoint = CGPoint(x: size.width * 0.15, y: size.height * 0.7)
                context.fill(
                    Circle().path(in: CGRect(x: startPoint.x - 4, y: startPoint.y - 4, width: 8, height: 8)),
                    with: .color(.milliCyan)
                )

                let endPoint = CGPoint(x: size.width * 0.85, y: size.height * 0.3)
                context.fill(
                    Circle().path(in: CGRect(x: endPoint.x - 4, y: endPoint.y - 4, width: 8, height: 8)),
                    with: .color(.milliGreen)
                )
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Today Stats

    private var todayStatsRow: some View {
        HStack(spacing: 12) {
            MilliCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THIS TRIP")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.3)
                        .foregroundColor(.milliTextSecondary)
                    Text(viewModel.activeTripMiles)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.activeTripDeduction)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliGreen)
                }
            }

            MilliCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.3)
                        .foregroundColor(.milliTextSecondary)
                    Text(viewModel.todayMiles)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.todayDeduction)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.milliGreen)
                }
            }
        }
    }

    // MARK: - Tracking Button

    private var trackingButton: some View {
        Button(action: {
            Task {
                if viewModel.isTracking {
                    await viewModel.stopTracking()
                } else {
                    await viewModel.startTracking()
                }
            }
        }) {
            Text(viewModel.isTracking ? "Stop Tracking" : "Start Tracking")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(viewModel.isTracking ? Color(hex: "FF3D57") : Color.milliCyan)
                .cornerRadius(12)
        }
    }
}

import SwiftUI
import Charts

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReportTab = .deductions
    @State private var showExportAlert = false

    enum ReportTab: String, CaseIterable, Hashable {
        case overview = "Overview"
        case deductions = "Deductions"
        case trips = "Trips"
    }

    private let monthlyDeductions: [(month: String, amount: Double)] = [
        ("Jan", 420), ("Feb", 510), ("Mar", 680), ("Apr", 590), ("May", 720), ("Jun", 840)
    ]

    private let mockTrips: [(date: String, miles: Double, earnings: Double)] = [
        ("Aug 9, 2026", 42.3, 68.50),
        ("Aug 8, 2026", 38.1, 52.00),
        ("Aug 7, 2026", 55.8, 84.20),
        ("Aug 6, 2026", 29.4, 41.00),
        ("Aug 5, 2026", 61.2, 92.75),
    ]

    private var totalDeductionsYTD: Double { monthlyDeductions.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                MilliSegmentedPicker(
                    options: ReportTab.allCases,
                    label: { $0.rawValue },
                    selection: $selectedTab
                )

                switch selectedTab {
                case .overview: overviewContent
                case .deductions: deductionsContent
                case .trips: tripsContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .alert("Coming Soon", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PDF and CSV export will be available in a future update.")
        }
    }

    // MARK: - Overview

    private var overviewContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                MilliStatTile(title: "Net Earnings", value: "$12,480", accent: MilliPalette.textPrimary)
                MilliStatTile(title: "Tax Saved", value: "$3,390", accent: MilliPalette.positive)
                MilliStatTile(title: "Miles YTD", value: "8,420", accent: MilliPalette.accent)
            }

            DKCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gross Income")
                            .font(.caption)
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text("$18,640")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(MilliPalette.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Effective Tax Rate")
                            .font(.caption)
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text("18.2%")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(MilliPalette.accent)
                    }
                }
            }
        }
    }

    // MARK: - Deductions

    private var deductionsContent: some View {
        VStack(spacing: 16) {
            DKCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Deductions YTD")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(milliCurrency(totalDeductionsYTD))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(MilliPalette.textPrimary)
                }
            }

            // Bar Chart
            DKCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Deductions")
                        .font(.headline)
                        .foregroundStyle(MilliPalette.textPrimary)

                    Chart(monthlyDeductions, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(MilliPalette.accent.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("$\(Int(v))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(MilliPalette.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }

            // Export
            HStack(spacing: 12) {
                ghostButton("Export PDF", icon: "doc.fill") { showExportAlert = true }
                ghostButton("Export CSV", icon: "tablecells") { showExportAlert = true }
            }
        }
    }

    // MARK: - Trips

    private var tripsContent: some View {
        VStack(spacing: 10) {
            ForEach(Array(mockTrips.enumerated()), id: \.offset) { _, trip in
                DKCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(trip.date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text(String(format: "%.1f miles", trip.miles))
                                .font(.caption)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        Spacer()
                        Text("+\(milliCurrency(trip.earnings, fraction: 2))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MilliPalette.positive)
                    }
                }
            }
        }
    }

    // MARK: - Ghost Button

    private func ghostButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14))
                Text(text).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(MilliPalette.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MilliPalette.accent.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

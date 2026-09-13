import SwiftUI
import Charts
import UIKit

struct ReportsView: View {
    var onBack: () -> Void = {}
    @State private var tab: ReportTab = .overview
    @State private var shareURL: URL?
    private let report = ReportData.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                header
                tabBar
                switch tab {
                case .overview: overview
                case .deductions: deductions
                case .trips: trips
                }
                HStack(spacing: 10) {
                    exportButton("Export PDF", "doc.richtext") { exportPDF() }
                    exportButton("Export CSV", "tablecells") { exportCSV() }
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 10)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 16)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
            if let shareURL { ReportShareSheet(items: [shareURL]).ignoresSafeArea() }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.04)))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reports").font(MilliFont.screenTitle).foregroundStyle(MilliColors.textPrimary)
                Text("Cash flow, deductions, and mileage").font(MilliFont.caption).foregroundStyle(MilliColors.textTertiary)
            }
            Spacer()
            Button(action: exportPDF) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(ReportTab.allCases, id: \.self) { item in
                Button { withAnimation(.easeInOut(duration: 0.18)) { tab = item } } label: {
                    Text(item.title)
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(tab == item ? MilliColors.blackGlass : MilliColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(RoundedRectangle(cornerRadius: 11).fill(tab == item ? MilliColors.cyanGlow : Color.white.opacity(0.025)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.28)))
    }

    private var overview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                metric("GROSS INCOME", money(report.gross), MilliColors.textPrimary)
                metric("DEDUCTIONS", money(report.deductions), MilliColors.warning)
            }
            HStack(spacing: 10) {
                metric("BUSINESS MILES", "\(Int(report.miles).formatted()) mi", MilliColors.textPrimary)
                metric("EST. TAX SAVED", money(report.taxSaved), MilliColors.positive)
            }
            cashFlowCard
        }
    }

    private var cashFlowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MONTHLY CASH FLOW").sectionHeaderStyle()
                    Text("Income, expenses, and protected tax reserves")
                        .font(MilliFont.caption).foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text(report.year).font(MilliFont.labelLarge).foregroundStyle(MilliColors.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                legend("Payouts", MilliColors.cyanGlow, "Gig-platform deposits")
                legend("Cash In", MilliColors.silverBright, "Other income")
                legend("Expenses", MilliColors.warning, "Business spend")
                legend("Tax Reserved", MilliColors.positive, "Protected for taxes")
            }

            Chart {
                ForEach(report.months) { p in
                    LineMark(x: .value("Month", p.month), y: .value("Payouts", p.payouts), series: .value("Series", "Payouts"))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Month", p.month), y: .value("Payouts", p.payouts)).foregroundStyle(MilliColors.cyanGlow).symbolSize(30)

                    LineMark(x: .value("Month", p.month), y: .value("Cash In", p.cash), series: .value("Series", "Cash In"))
                        .foregroundStyle(MilliColors.silverBright)
                        .lineStyle(StrokeStyle(lineWidth: 1.8, dash: [6, 4]))
                    PointMark(x: .value("Month", p.month), y: .value("Cash In", p.cash)).foregroundStyle(MilliColors.silverBright).symbolSize(22)

                    LineMark(x: .value("Month", p.month), y: .value("Expenses", p.expenses), series: .value("Series", "Expenses"))
                        .foregroundStyle(MilliColors.warning)
                        .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Month", p.month), y: .value("Expenses", p.expenses)).foregroundStyle(MilliColors.warning).symbolSize(25)

                    LineMark(x: .value("Month", p.month), y: .value("Tax", p.tax), series: .value("Series", "Tax Reserved"))
                        .foregroundStyle(MilliColors.positive)
                        .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Month", p.month), y: .value("Tax", p.tax)).foregroundStyle(MilliColors.positive).symbolSize(25)
                }
            }
            .chartYScale(domain: 0...2600)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 500.0, 1000.0, 1500.0, 2000.0, 2500.0]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7, dash: [3, 5])).foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel {
                        if let n = v.as(Double.self) {
                            Text(n.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: report.months.map(\.month)) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 6])).foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel {
                        if let month = v.as(String.self) { Text(month).font(.system(size: 11, weight: .semibold)).foregroundStyle(MilliColors.textSecondary) }
                    }
                }
            }
            .frame(height: 238)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: [Color(hex: "0D171C"), Color(hex: "071013")], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 0.8))
    }

    private var deductions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                metric("TOTAL DEDUCTIONS", money(report.deductions), MilliColors.warning)
                metric("DEDUCTION RATE", (report.deductions / report.gross).formatted(.percent.precision(.fractionLength(1))), MilliColors.cyanGlow)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("BUSINESS EXPENSES BY MONTH").sectionHeaderStyle()
                Chart(report.months) { p in
                    BarMark(x: .value("Month", p.month), y: .value("Expenses", p.expenses))
                        .foregroundStyle(LinearGradient(colors: [MilliColors.warning, MilliColors.warning.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                        .cornerRadius(4)
                }
                .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine().foregroundStyle(Color.white.opacity(0.06)); AxisValueLabel().foregroundStyle(MilliColors.textTertiary) } }
                .frame(height: 210)
            }
            .milliCard(padding: 16)
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP DEDUCTION CATEGORIES").sectionHeaderStyle()
                ForEach(report.categories) { c in
                    HStack { Image(systemName: c.icon).foregroundStyle(c.color).frame(width: 26); Text(c.name).font(MilliFont.bodySmall); Spacer(); Text(money(c.amount)).font(MilliFont.numericSmall).monospacedDigit() }
                        .foregroundStyle(MilliColors.textPrimary).padding(.vertical, 6)
                }
            }
            .milliCard(padding: 14)
        }
    }

    private var trips: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                metric("BUSINESS MILES", "\(Int(report.miles).formatted()) mi", MilliColors.textPrimary)
                metric("MILEAGE VALUE", money(report.mileageValue), MilliColors.positive)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT BUSINESS TRIPS").sectionHeaderStyle()
                ForEach(report.trips) { t in
                    HStack(spacing: 10) {
                        Image(systemName: "car.side.fill").foregroundStyle(MilliColors.cyanGlow).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) { Text(t.platform).font(MilliFont.headlineSmall); Text(t.date).font(MilliFont.caption).foregroundStyle(MilliColors.textTertiary) }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) { Text("\(t.miles, specifier: "%.1f") mi").font(MilliFont.numericSmall); Text(money(t.deduction)).font(MilliFont.caption).foregroundStyle(MilliColors.positive) }
                    }
                    .foregroundStyle(MilliColors.textPrimary).padding(.vertical, 7)
                }
            }
            .milliCard(padding: 14)
        }
    }

    private func metric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(title).font(MilliFont.sectionLabel).foregroundStyle(MilliColors.textSecondary); Text(value).font(MilliFont.numericMedium).monospacedDigit().foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.72) }
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading).milliCard(padding: 13)
    }

    private func legend(_ title: String, _ color: Color, _ detail: String) -> some View {
        HStack(spacing: 8) { Circle().fill(color).frame(width: 8, height: 8); VStack(alignment: .leading, spacing: 1) { Text(title).font(.system(size: 11, weight: .semibold)); Text(detail).font(.system(size: 9)).foregroundStyle(MilliColors.textTertiary).lineLimit(1) } }
            .foregroundStyle(MilliColors.textPrimary)
    }

    private func exportButton(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { HStack(spacing: 7) { Image(systemName: icon); Text(title).font(MilliFont.labelLarge) }.foregroundStyle(MilliColors.cyanGlow).frame(maxWidth: .infinity, minHeight: 50).background(RoundedRectangle(cornerRadius: 14).fill(MilliColors.cardBackground)) }.buttonStyle(.plain)
    }

    private func exportCSV() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Milli-Report.csv")
        let rows = ["Month,Payouts,Cash In,Expenses,Tax Reserved"] + report.months.map { "\($0.month),\($0.payouts),\($0.cash),\($0.expenses),\($0.tax)" }
        try? rows.joined(separator: "\n").data(using: .utf8)?.write(to: url)
        shareURL = url
    }

    private func exportPDF() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Milli-Report.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { context in
            context.beginPage()
            NSString(string: "MILLI — Reports").draw(at: CGPoint(x: 42, y: 42), withAttributes: [.font: UIFont.systemFont(ofSize: 24, weight: .bold)])
            var y: CGFloat = 90
            for p in report.months { NSString(string: "\(p.month): payouts \(money(p.payouts)), cash \(money(p.cash)), expenses \(money(p.expenses)), tax \(money(p.tax))").draw(at: CGPoint(x: 42, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11)]); y += 22 }
        }
        try? data.write(to: url)
        shareURL = url
    }

    private func money(_ value: Double) -> String { value.formatted(.currency(code: "USD")) }
}

private enum ReportTab: CaseIterable { case overview, deductions, trips; var title: String { switch self { case .overview: "Overview"; case .deductions: "Deductions"; case .trips: "Trips" } } }
private struct ReportMonth: Identifiable { let id = UUID(); let month: String; let payouts, cash, expenses, tax: Double }
private struct ReportCategory: Identifiable { let id = UUID(); let name: String; let amount: Double; let color: Color; let icon: String }
private struct ReportTrip: Identifiable { let id = UUID(); let platform, date: String; let miles, deduction: Double }
private struct ReportData {
    let gross, deductions, miles, mileageValue, taxSaved: Double
    let months: [ReportMonth]; let categories: [ReportCategory]; let trips: [ReportTrip]
    var year: String { String(Calendar.current.component(.year, from: Date())) }
    static let reference = ReportData(
        gross: 10_011.16, deductions: 2_843.17, miles: 4_112, mileageValue: 2_218.42, taxSaved: 894.73,
        months: [.init(month:"Jan",payouts:1120,cash:300,expenses:410,tax:355),.init(month:"Feb",payouts:1485,cash:400,expenses:575,tax:471),.init(month:"Mar",payouts:1840,cash:420,expenses:720,tax:565),.init(month:"Apr",payouts:2265,cash:450,expenses:940,tax:679),.init(month:"May",payouts:1511.16,cash:220,expenses:198.17,tax:433)],
        categories: [.init(name:"Fuel",amount:1286.45,color:MilliColors.cyanGlow,icon:"fuelpump.fill"),.init(name:"Car Maintenance",amount:642.17,color:MilliColors.deepCyan,icon:"wrench.and.screwdriver.fill"),.init(name:"Insurance",amount:389.45,color:MilliColors.deepCyan,icon:"shield.fill")],
        trips: [.init(platform:"Spark Driver",date:"Today • 7:18 AM",miles:12.4,deduction:6.55),.init(platform:"DoorDash",date:"Yesterday • 6:42 PM",miles:8.7,deduction:4.59),.init(platform:"Uber",date:"Yesterday • 1:10 PM",miles:18.2,deduction:9.61)]
    )
}
private struct ReportShareSheet: UIViewControllerRepresentable { let items: [Any]; func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }; func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {} }

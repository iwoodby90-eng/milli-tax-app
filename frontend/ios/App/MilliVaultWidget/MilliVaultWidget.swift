//
//  MilliVaultWidget.swift
//  MilliVaultWidget
//
//  Home-screen widget that shows the driver's current Milli Tax Vault™
//  balance and progress toward the annual tax goal.
//
//  Setup:
//    1. In Xcode: File → New → Target → Widget Extension.
//       Product Name: MilliVaultWidget
//       Bundle ID:    app.milli.tax.MilliVaultWidget
//       ☐ Include Configuration Intent (leave unchecked for now)
//    2. Replace the auto-generated .swift file with THIS file.
//    3. Add BOTH the main "App" target and the "MilliVaultWidget" target
//       to an App Group (e.g. group.app.milli.tax).
//       - Signing & Capabilities → + Capability → App Groups → +group.app.milli.tax
//    4. In the main iOS app, after every /api/tax/summary fetch, write to
//       UserDefaults(suiteName: "group.app.milli.tax") with keys:
//         - vault_balance   (Double)
//         - vault_goal      (Double)
//         - vault_month     (Double)
//         - vault_updated   (Double, epoch seconds)
//       (Do this via a small Capacitor plugin call or Preferences bridge.)
//    5. Build & run. Long-press the home screen → +Widget → search "Milli".
//

import WidgetKit
import SwiftUI

// MARK: - Data

struct VaultEntry: TimelineEntry {
    let date: Date
    let balance: Double
    let goal: Double
    let thisMonth: Double
}

struct VaultProvider: TimelineProvider {
    static let appGroup = "group.app.milli.tax"

    static func read() -> VaultEntry {
        let d = UserDefaults(suiteName: appGroup)
        return VaultEntry(
            date: Date(),
            balance:   d?.double(forKey: "vault_balance") ?? 0,
            goal:      d?.double(forKey: "vault_goal")    ?? 20000,
            thisMonth: d?.double(forKey: "vault_month")   ?? 0
        )
    }

    func placeholder(in context: Context) -> VaultEntry {
        VaultEntry(date: Date(), balance: 1480.42, goal: 20000, thisMonth: 7.38)
    }

    func getSnapshot(in context: Context, completion: @escaping (VaultEntry) -> Void) {
        completion(VaultProvider.read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaultEntry>) -> Void) {
        let now = Date()
        let entry = VaultProvider.read()
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views

struct MilliCyanBg: View {
    var body: some View {
        ZStack {
            Color(red: 5/255, green: 7/255, blue: 10/255)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.25),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 4, endRadius: 180
            )
        }
    }
}

struct MilliProgressBar: View {
    let pct: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0/255,   green: 180/255, blue: 208/255),
                            Color(red: 0/255,   green: 229/255, blue: 255/255),
                            Color(red: 123/255, green: 243/255, blue: 255/255)
                        ],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, g.size.width * CGFloat(pct)))
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.8), radius: 6)
            }
        }
        .frame(height: 6)
    }
}

struct SmallView: View {
    let entry: VaultEntry
    private var pct: Double { min(1.0, entry.balance / max(1, entry.goal)) }

    var body: some View {
        ZStack {
            MilliCyanBg()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("MILLI VAULT")
                        .font(.system(size: 9, weight: .bold, design: .default))
                        .kerning(2.6)
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                    Spacer()
                }
                Text(fmtMoney(entry.balance))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text("+\(fmtMoney(entry.thisMonth)) this month")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.85))
                Spacer()
                MilliProgressBar(pct: pct)
                Text("\(Int(pct * 100))% of \(fmtMoneyShort(entry.goal))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
        }
    }
}

struct MediumView: View {
    let entry: VaultEntry
    private var pct: Double { min(1.0, entry.balance / max(1, entry.goal)) }

    var body: some View {
        ZStack {
            MilliCyanBg()
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MILLI TAX VAULT™")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(2.6)
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                    Text(fmtMoney(entry.balance))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text("+\(fmtMoney(entry.thisMonth)) this month")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.85))
                    Spacer()
                    MilliProgressBar(pct: pct)
                    Text("\(Int(pct * 100))% to \(fmtMoneyShort(entry.goal)) goal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Big polished M
                Text("M")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.white.opacity(0.4)],
                                       startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.7), radius: 8)
                    .padding(.top, 4)
            }
            .padding(14)
        }
    }
}

@main
struct MilliVaultWidget: Widget {
    let kind = "MilliVaultWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaultProvider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    Group {
                        SmallView(entry: entry)
                    }.containerBackground(.clear, for: .widget)
                } else {
                    SmallView(entry: entry)
                }
            }
        }
        .configurationDisplayName("Milli Tax Vault")
        .description("See how much you've protected this year, on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Helpers

private func fmtMoney(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "USD"
    f.maximumFractionDigits = 2
    return f.string(from: NSNumber(value: v)) ?? "$0.00"
}
private func fmtMoneyShort(_ v: Double) -> String {
    if v >= 1_000_000 { return String(format: "$%.1fM", v / 1_000_000) }
    if v >= 1_000     { return String(format: "$%.0fK", v / 1_000) }
    return String(format: "$%.0f", v)
}

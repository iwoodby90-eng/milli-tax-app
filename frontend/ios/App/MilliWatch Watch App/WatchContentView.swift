//
//  WatchContentView.swift
//  MilliWatch Watch App
//
//  Main SwiftUI view — big Vault balance + streak flame, cyan progress ring,
//  and a subtle chrome "M" background. Reads live data from the shared
//  App Group UserDefaults that the iPhone app writes on every /api/tax/summary.
//

import SwiftUI
import WidgetKit

struct WatchContentView: View {
    @State private var snapshot: WatchSnapshot = WatchSnapshot.placeholder
    private static let appGroup = "group.app.milli.tax"

    var body: some View {
        ZStack {
            // Deep obsidian background with a cyan halo
            Color(red: 5/255, green: 7/255, blue: 10/255).ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.22),
                    Color.clear
                ]),
                center: .top,
                startRadius: 6, endRadius: 140
            )
            .ignoresSafeArea()

            VStack(alignment: .center, spacing: 6) {
                // Header
                HStack(spacing: 4) {
                    Text("MILLI VAULT")
                        .font(.system(size: 8, weight: .heavy))
                        .kerning(2.4)
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                    Spacer()
                    if snapshot.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                            Text("\(snapshot.streak)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer(minLength: 2)

                // Balance — big chrome number
                Text(fmtMoney(snapshot.balance))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.55)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.35), radius: 6)

                // + this month
                if snapshot.thisMonth > 0 {
                    Text("+\(fmtMoney(snapshot.thisMonth)) this month")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.9))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Cyan progress ring
                CyanProgressRing(pct: snapshot.pct)
                    .frame(height: 8)

                // % → goal caption
                HStack {
                    Text("\(Int(snapshot.pct * 100))%")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                    Text("of \(fmtMoneyShort(snapshot.goal)) goal")
                        .foregroundColor(.white.opacity(0.55))
                        .font(.system(size: 9))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear(perform: reload)
        // Refresh when the wrist raises again
        .onReceive(NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)) { _ in
            reload()
        }
    }

    private func reload() {
        snapshot = WatchSnapshot.read(from: Self.appGroup)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Shared model

struct WatchSnapshot {
    let balance:   Double
    let goal:      Double
    let thisMonth: Double
    let streak:    Int
    let firstName: String
    let updated:   Date

    var pct: Double { min(1.0, balance / max(1, goal)) }

    static let placeholder = WatchSnapshot(
        balance: 1_364.80, goal: 20_000, thisMonth: 210.55,
        streak: 6, firstName: "Jordan", updated: Date()
    )

    static func read(from appGroup: String) -> WatchSnapshot {
        guard let d = UserDefaults(suiteName: appGroup) else { return .placeholder }
        return WatchSnapshot(
            balance:   d.double(forKey: "vault_balance"),
            goal:      max(1, d.double(forKey: "vault_goal")),
            thisMonth: d.double(forKey: "vault_month"),
            streak:    d.integer(forKey: "vault_streak"),
            firstName: d.string(forKey: "vault_firstname") ?? "",
            updated:   Date(timeIntervalSince1970: d.double(forKey: "vault_updated"))
        )
    }
}

// MARK: - Ring

struct CyanProgressRing: View {
    let pct: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0/255,   green: 180/255, blue: 208/255),
                            Color(red: 0/255,   green: 229/255, blue: 255/255),
                            Color(red: 123/255, green: 243/255, blue: 255/255)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(6, g.size.width * CGFloat(pct)))
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.9),
                            radius: 5)
            }
        }
    }
}

// MARK: - Helpers

func fmtMoney(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "USD"
    f.maximumFractionDigits = 2
    return f.string(from: NSNumber(value: v)) ?? "$0.00"
}

func fmtMoneyShort(_ v: Double) -> String {
    if v >= 1_000_000 { return String(format: "$%.1fM", v / 1_000_000) }
    if v >= 1_000     { return String(format: "$%.0fK", v / 1_000) }
    return String(format: "$%.0f", v)
}

#Preview {
    WatchContentView()
}

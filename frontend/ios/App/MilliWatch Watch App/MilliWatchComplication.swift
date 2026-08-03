//
//  MilliWatchComplication.swift
//  MilliWatch Watch App
//
//  WidgetKit complications so Jordan sees the Vault balance and streak
//  directly on the watch face (accessoryCircular / accessoryInline /
//  accessoryRectangular / accessoryCorner).
//
//  Add this in Xcode as a second target:
//    File → New → Target → watchOS → Widget Extension
//      Product Name: MilliWatchComplication
//      Include Configuration Intent: OFF
//      Include Live Activity: OFF
//    Add the App Group group.app.milli.tax to this target too.
//    Then paste this file over the auto-generated one.
//

import WidgetKit
import SwiftUI

struct VaultEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchSnapshot
}

struct VaultProvider: TimelineProvider {
    static let appGroup = "group.app.milli.tax"

    func placeholder(in context: Context) -> VaultEntry {
        VaultEntry(date: Date(), snapshot: WatchSnapshot.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VaultEntry) -> Void) {
        completion(VaultEntry(date: Date(), snapshot: WatchSnapshot.read(from: Self.appGroup)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaultEntry>) -> Void) {
        let entry = VaultEntry(date: Date(), snapshot: WatchSnapshot.read(from: Self.appGroup))
        // Refresh every 15 minutes on the wrist
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Complication Views

struct CircularComplication: View {
    let s: WatchSnapshot
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(s.pct))
                .stroke(
                    Color(red: 0/255, green: 229/255, blue: 255/255),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.9), radius: 3)
            Text("M")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct InlineComplication: View {
    let s: WatchSnapshot
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 10, weight: .bold))
            Text(fmtMoneyShort(s.balance))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
            if s.streak > 0 {
                Text("· \(s.streak)🔥")
                    .font(.system(size: 11))
            }
        }
    }
}

struct RectangularComplication: View {
    let s: WatchSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text("MILLI VAULT")
                    .font(.system(size: 8, weight: .heavy))
                    .kerning(1.6)
                    .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                Spacer()
                if s.streak > 0 {
                    Text("🔥\(s.streak)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Text(fmtMoney(s.balance))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            CyanProgressRing(pct: s.pct)
                .frame(height: 3)
        }
    }
}

struct CornerComplication: View {
    let s: WatchSnapshot
    var body: some View {
        Text(fmtMoneyShort(s.balance))
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .widgetLabel {
                CyanProgressRing(pct: s.pct)
                    .frame(height: 3)
            }
    }
}

// MARK: - Widget

struct MilliWatchComplicationEntryView: View {
    var entry: VaultEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .accessoryCircular:    CircularComplication(s: entry.snapshot)
        case .accessoryInline:      InlineComplication(s: entry.snapshot)
        case .accessoryRectangular: RectangularComplication(s: entry.snapshot)
        case .accessoryCorner:      CornerComplication(s: entry.snapshot)
        default:                    CircularComplication(s: entry.snapshot)
        }
    }
}

@main
struct MilliWatchComplication: Widget {
    let kind = "MilliWatchComplication"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaultProvider()) { entry in
            MilliWatchComplicationEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Milli Vault")
        .description("See how much you've protected — and your earning streak — from your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

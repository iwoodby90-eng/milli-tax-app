//
//  TaxReadyComplication.swift
//  MilliWatch
//
//  Provides a WidgetKit complication that shows the user's Tax Ready
//  Score on the watch face. Supports:
//     • Circular    — CircularGauge with cyan tint
//     • Corner      — GraphicCorner with score in the label
//     • Inline      — small text ("Milli 92%")
//
//  Requires watchOS 9+ WidgetKit APIs.
//

import WidgetKit
import SwiftUI

// MARK: - Entry model
struct TaxReadyEntry: TimelineEntry {
    let date: Date
    let score: Int              // 0–100
    let vault: Double
    let dueInDays: Int
}

// MARK: - Provider
struct TaxReadyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaxReadyEntry {
        TaxReadyEntry(date: Date(), score: 92, vault: 1842.50, dueInDays: 14)
    }
    func getSnapshot(in context: Context,
                     completion: @escaping (TaxReadyEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TaxReadyEntry>) -> Void) {
        // In production, read from shared UserDefaults or WatchConnectivity.
        let now = Date()
        let entries = [ TaxReadyEntry(date: now, score: 92, vault: 1842.50, dueInDays: 14) ]
        completion(Timeline(entries: entries,
                              policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

// MARK: - Views
struct TaxReadyCircularView: View {
    let entry: TaxReadyEntry
    var body: some View {
        Gauge(value: Double(entry.score), in: 0...100) {
            Text("Milli")
        } currentValueLabel: {
            Text("\(entry.score)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Color(red: 0.00, green: 0.90, blue: 1.00))
    }
}

struct TaxReadyInlineView: View {
    let entry: TaxReadyEntry
    var body: some View {
        Text("Milli \(entry.score)%")
    }
}

struct TaxReadyCornerView: View {
    let entry: TaxReadyEntry
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(entry.score) / 100.0)
                .stroke(Color(red: 0.00, green: 0.90, blue: 1.00),
                         style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(entry.score)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        }
        .widgetLabel {
            Text("Tax Ready · \(entry.dueInDays)d")
        }
    }
}

// MARK: - Widget
struct TaxReadyComplication: Widget {
    let kind: String = "TaxReadyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaxReadyProvider()) { entry in
            switch WidgetFamilyResolver.family {
            case .accessoryCircular: TaxReadyCircularView(entry: entry)
            case .accessoryCorner:   TaxReadyCornerView(entry: entry)
            case .accessoryInline:   TaxReadyInlineView(entry: entry)
            default:                 TaxReadyCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Milli Tax Ready")
        .description("Your Milli Tax Ready Score on the watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

enum WidgetFamilyResolver {
    // Simple helper — real family comes from the environment in production.
    static var family: WidgetFamily = .accessoryCircular
}

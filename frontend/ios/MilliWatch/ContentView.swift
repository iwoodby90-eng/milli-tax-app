//
//  ContentView.swift
//  MilliWatch
//
//  Three-tab watch UI:
//     1. Live Trip    — big Start/Stop, distance + elapsed time
//     2. Tax Ready    — score ring + today's earnings / tax set-aside
//     3. Autopilot    — the latest Autopilot Receipt in miniature
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LiveTripView()
                .tag(0)
            TaxReadyView()
                .tag(1)
            AutopilotView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .background(Color.black.ignoresSafeArea())
        .accentColor(Milli.cyan)
        .tint(Milli.cyan)
    }
}

// MARK: - Milli brand tokens
struct Milli {
    static let cyan   = Color(red: 0.00, green: 0.90, blue: 1.00)     // #00E5FF
    static let noir   = Color(red: 0.02, green: 0.02, blue: 0.03)     // #050607
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)     // #C0C0C0
    static let muted  = Color(red: 0.545, green: 0.616, blue: 0.686)  // #8B9DAF
}

// MARK: - Live Trip
struct LiveTripView: View {
    @EnvironmentObject var trip: TripState

    var body: some View {
        VStack(spacing: 12) {
            Text(trip.isRunning ? "TRIP LIVE" : "READY TO DRIVE")
                .font(.system(size: 10, weight: .bold))
                .kerning(2)
                .foregroundColor(trip.isRunning ? Milli.cyan : Milli.silver)

            Text(String(format: "%.2f mi", trip.miles))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: Milli.cyan.opacity(trip.isRunning ? 0.6 : 0), radius: 8)

            Text(trip.formattedElapsed)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Milli.muted)

            Button(action: toggle) {
                Text(trip.isRunning ? "END TRIP" : "START TRIP")
                    .font(.system(size: 13, weight: .heavy))
                    .kerning(1.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(trip.isRunning ? Color.red.opacity(0.85) : Milli.cyan)
                    .foregroundColor(trip.isRunning ? .white : .black)
                    .cornerRadius(12)
                    .shadow(color: trip.isRunning ? Color.red : Milli.cyan,
                             radius: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }

    private func toggle() {
        WKInterfaceDevice.current().play(trip.isRunning ? .stop : .start)
        if trip.isRunning {
            WatchSession.shared.send(command: "stop_trip")
            trip.stop()
        } else {
            WatchSession.shared.send(command: "start_trip")
            trip.start()
        }
    }
}

// MARK: - Tax Ready
struct TaxReadyView: View {
    @EnvironmentObject var session: WatchSession
    var body: some View {
        VStack(spacing: 8) {
            Text("TAX READY").font(.system(size: 10, weight: .bold)).kerning(2)
                .foregroundColor(Milli.cyan)
            ZStack {
                Circle()
                    .stroke(Milli.silver.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(session.taxReadyScore) / 100.0)
                    .stroke(
                        AngularGradient(colors: [Milli.cyan, Color.white, Milli.cyan],
                                          center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Milli.cyan.opacity(0.7), radius: 6)
                VStack(spacing: 0) {
                    Text("\(session.taxReadyScore)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    Text("SCORE").font(.system(size: 8, weight: .bold)).kerning(1.5)
                        .foregroundColor(Milli.muted)
                }
            }
            .frame(width: 96, height: 96)

            HStack(spacing: 10) {
                stat("EARNED", session.formatted(session.earnedToday))
                stat("VAULT", session.formatted(session.vaultToday))
            }
        }
        .padding(.horizontal, 6)
    }
    @ViewBuilder private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 8, weight: .bold)).kerning(1.5)
                .foregroundColor(Milli.muted)
            Text(value).font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Autopilot glance
struct AutopilotView: View {
    @EnvironmentObject var session: WatchSession
    var body: some View {
        VStack(spacing: 8) {
            Text("MILLI AUTOPILOT")
                .font(.system(size: 10, weight: .bold)).kerning(2)
                .foregroundColor(Milli.cyan)
            Text(session.latestReceiptAmount).font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(session.latestReceiptSource).font(.system(size: 11)).foregroundColor(Milli.muted)
            Divider().background(Milli.silver.opacity(0.2))
            row("Taxes",     session.formatted(session.latestTax))
            row("Retire",    session.formatted(session.latestRetire))
            row("Investing", session.formatted(session.latestInvest))
            row("Available", session.formatted(session.latestAvailable), highlight: true)
        }
        .padding(.horizontal, 6)
    }
    @ViewBuilder private func row(_ k: String, _ v: String, highlight: Bool = false) -> some View {
        HStack {
            Text(k).font(.system(size: 11)).foregroundColor(Milli.muted)
            Spacer()
            Text(v).font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(highlight ? Milli.cyan : .white)
        }
    }
}

#Preview { ContentView() }

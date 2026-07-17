//
//  WatchSession.swift
//  MilliWatch
//
//  Sends commands to the iPhone (start_trip / stop_trip) and receives
//  updates (tax_ready_score, earned_today, vault_today, latest_receipt).
//

import Foundation
import WatchConnectivity
import Combine

final class WatchSession: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSession()

    // Published state consumed by the SwiftUI views.
    @Published var isReachable: Bool = false
    @Published var taxReadyScore: Int = 0
    @Published var earnedToday: Double = 0
    @Published var vaultToday: Double = 0
    @Published var latestReceiptAmount: String = "$0.00"
    @Published var latestReceiptSource: String = "No payouts yet"
    @Published var latestTax: Double = 0
    @Published var latestRetire: Double = 0
    @Published var latestInvest: Double = 0
    @Published var latestAvailable: Double = 0

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        guard let s = session else { return }
        s.delegate = self
        s.activate()
    }

    /// Send a plain command to the iPhone (e.g. "start_trip", "stop_trip").
    func send(command: String) {
        guard let s = session, s.activationState == .activated, s.isReachable else { return }
        s.sendMessage(["cmd": command, "ts": Date().timeIntervalSince1970],
                       replyHandler: nil, errorHandler: nil)
    }

    /// Convenience formatter.
    func formatted(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "$0.00"
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                  activationDidCompleteWith activationState: WCSessionActivationState,
                  error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    /// Handle application-context updates pushed from the iPhone.
    func session(_ session: WCSession, didReceiveApplicationContext ctx: [String: Any]) {
        DispatchQueue.main.async { self.apply(ctx) }
    }

    /// Handle live message pushes from the iPhone.
    func session(_ session: WCSession,
                  didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.apply(message) }
    }

    private func apply(_ payload: [String: Any]) {
        if let s = payload["tax_ready_score"] as? Int { taxReadyScore = s }
        if let e = payload["earned_today"] as? Double { earnedToday = e }
        if let v = payload["vault_today"] as? Double { vaultToday = v }
        if let r = payload["latest_receipt"] as? [String: Any] {
            latestReceiptAmount = formatted((r["amount"] as? Double) ?? 0)
            latestReceiptSource = (r["source"] as? String) ?? "Payout"
            latestTax      = (r["tax_reserve"] as? Double) ?? 0
            latestRetire   = (r["retirement_amount"] as? Double) ?? 0
            latestInvest   = (r["investing_amount"] as? Double) ?? 0
            latestAvailable = (r["available_to_spend"] as? Double) ?? 0
        }
    }
}

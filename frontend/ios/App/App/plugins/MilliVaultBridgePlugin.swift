//
//  MilliVaultBridgePlugin.swift
//
//  Capacitor bridge — lets React write the vault snapshot straight into
//  the App Group UserDefaults that MilliVaultWidget reads from.
//  No manual Xcode wiring needed after target creation.
//
//  Usage from React:
//    import { MilliVaultBridge } from "@/plugins/MilliVaultBridge";
//    await MilliVaultBridge.update({ balance, goal, thisMonth });
//

import Foundation
import Capacitor
import WidgetKit

@objc(MilliVaultBridge)
public class MilliVaultBridge: CAPPlugin {

    private static let appGroup = "group.app.milli.tax"
    private static let widgetKind = "MilliVaultWidget"

    @objc func update(_ call: CAPPluginCall) {
        let balance   = call.getDouble("balance")   ?? 0
        let goal      = call.getDouble("goal")      ?? 20000
        let thisMonth = call.getDouble("thisMonth") ?? 0

        guard let d = UserDefaults(suiteName: Self.appGroup) else {
            call.reject("App Group \(Self.appGroup) not configured")
            return
        }
        d.set(balance,   forKey: "vault_balance")
        d.set(goal,      forKey: "vault_goal")
        d.set(thisMonth, forKey: "vault_month")
        d.set(Date().timeIntervalSince1970, forKey: "vault_updated")

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        }
        call.resolve(["ok": true])
    }

    @objc func read(_ call: CAPPluginCall) {
        guard let d = UserDefaults(suiteName: Self.appGroup) else {
            call.reject("App Group \(Self.appGroup) not configured")
            return
        }
        call.resolve([
            "balance":   d.double(forKey: "vault_balance"),
            "goal":      d.double(forKey: "vault_goal"),
            "month":     d.double(forKey: "vault_month"),
            "updated":   d.double(forKey: "vault_updated"),
        ])
    }
}

//
//  MilliWatchApp.swift
//  MilliWatch — companion Apple Watch app for Milli Tax Autopilot
//
//  SwiftUI entry point. Targets watchOS 10+.
//

import SwiftUI
import WatchKit

@main
struct MilliWatchApp: App {
    @WKApplicationDelegateAdaptor(MilliWatchDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WatchSession.shared)
                .environmentObject(TripState.shared)
        }
        WKNotificationScene(controller: NotificationController.self,
                             category: "milli_autopilot")
    }
}

/// App-level delegate — wakes the WatchConnectivity session and hooks into
/// notifications.
final class MilliWatchDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchSession.shared.activate()
    }
}

/// Placeholder for interactive notifications (Autopilot receipts).
final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView { NotificationView() }
}

struct NotificationView: View {
    var body: some View {
        VStack {
            Text("Milli").font(.headline)
            Text("Autopilot ran on your latest payout.").font(.footnote)
        }
    }
}

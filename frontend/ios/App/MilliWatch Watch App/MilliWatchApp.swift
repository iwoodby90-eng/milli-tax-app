//
//  MilliWatchApp.swift
//  MilliWatch Watch App
//
//  SwiftUI @main entry point for the Milli Watch companion.
//  Displays a live Milli Tax Vault™ balance + earning streak, mirroring
//  what the iPhone app pushes into the shared App Group.
//
//  Setup (one-time, in Xcode):
//    1. File → New → Target → watchOS → App
//         Product Name: MilliWatch
//         Interface: SwiftUI, Language: Swift, Include Notification Scene: OFF
//    2. Under Signing & Capabilities on BOTH the Watch target AND the main
//       iOS "App" target: + App Groups → group.app.milli.tax
//    3. Replace the auto-generated files inside "MilliWatch Watch App" with
//       the three .swift files in this folder.
//    4. In Xcode → target MilliWatch → Signing → set your Team + bundle id
//         suggested: app.milli.tax.watchkitapp
//    5. Build & run on a paired Apple Watch simulator or device.
//

import SwiftUI

@main
struct MilliWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

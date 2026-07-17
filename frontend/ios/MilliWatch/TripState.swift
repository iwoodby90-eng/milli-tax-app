//
//  TripState.swift
//  MilliWatch
//
//  Simple observable trip state used by the LiveTripView. Distance +
//  elapsed time are ticked locally by a Timer; the actual GPS trip
//  lives on the iPhone (via @capacitor-community/background-geolocation).
//  The iPhone streams periodic distance updates over WatchConnectivity.
//

import Foundation
import Combine

final class TripState: ObservableObject {
    static let shared = TripState()

    @Published var isRunning: Bool = false
    @Published var miles: Double = 0
    @Published var elapsedSeconds: Int = 0

    private var timer: Timer?
    private var startDate: Date?

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        miles = 0
        elapsedSeconds = 0
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            DispatchQueue.main.async {
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    /// Called when the phone streams a distance delta.
    func apply(distanceMiles: Double) {
        DispatchQueue.main.async { self.miles = distanceMiles }
    }
}

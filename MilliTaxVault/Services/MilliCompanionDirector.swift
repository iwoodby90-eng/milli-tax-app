import Foundation
import SwiftUI

// MARK: - MilliMilestone
// Milestones are real, observable events in the user's own data. Nothing here
// invents progress: every case is derived from verified payouts, the user's tax
// profile or expenses they recorded themselves.

enum MilliMilestone: String, CaseIterable {
    case bankConnected
    case firstPayout
    case reserveQuarter
    case reserveHalf
    case reserveThreeQuarters
    case reserveFunded
    case deductionsFiveHundred
    case deductionsTwoThousand

    var title: String {
        switch self {
        case .bankConnected: return "Bank connected"
        case .firstPayout: return "First payout protected"
        case .reserveQuarter: return "Reserve 25% funded"
        case .reserveHalf: return "Reserve halfway"
        case .reserveThreeQuarters: return "Reserve 75% funded"
        case .reserveFunded: return "Reserve fully funded"
        case .deductionsFiveHundred: return "$500 in deductions"
        case .deductionsTwoThousand: return "$2,000 in deductions"
        }
    }

    var line: String {
        switch self {
        case .bankConnected: return "We're live — I can see your real numbers now."
        case .firstPayout: return "Your first payout is split and protected."
        case .reserveQuarter: return "A quarter of this year's tax bill is already set aside."
        case .reserveHalf: return "Halfway to covering your tax bill. Nice work."
        case .reserveThreeQuarters: return "Three quarters banked — the hard part is behind you."
        case .reserveFunded: return "Your whole estimated tax bill is covered. Breathe."
        case .deductionsFiveHundred: return "$500 in deductions logged — that's real money back."
        case .deductionsTwoThousand: return "$2,000 in deductions. Your receipts are paying off."
        }
    }
}

// MARK: - MilliCompanionDirector
// Drives the Milli AI character: an occasional stroll along the navigation deck,
// and a celebration inside the M dial when the user hits a real milestone.

@MainActor
final class MilliCompanionDirector: ObservableObject {
    static let shared = MilliCompanionDirector()

    @Published private(set) var isStrolling = false
    @Published private(set) var celebration: MilliMilestone?

    /// Quiet window between strolls so the character stays a surprise.
    private let strollInterval: ClosedRange<TimeInterval> = 70...150
    private let strollDuration: TimeInterval = 7.5
    private let celebrationDuration: TimeInterval = 5.0
    private let storageKey = "milliCelebratedMilestones"

    private var strollTask: Task<Void, Never>?
    private var celebrationTask: Task<Void, Never>?

    private var celebrated: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: storageKey) }
    }

    // MARK: Stroll

    func startStrolling() {
        guard strollTask == nil else { return }

        strollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let delay = Double.random(in: self.strollInterval)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, self.celebration == nil else { continue }

                self.isStrolling = true
                try? await Task.sleep(nanoseconds: UInt64(self.strollDuration * 1_000_000_000))
                self.isStrolling = false
            }
        }
    }

    func stopStrolling() {
        strollTask?.cancel()
        strollTask = nil
        isStrolling = false
    }

    // MARK: Celebration

    /// Fires at most one celebration per milestone, ever.
    func evaluate(snapshot: MilliFinancialSnapshot) {
        guard celebration == nil else { return }

        for milestone in MilliMilestone.allCases where !celebrated.contains(milestone.rawValue) {
            guard Self.isReached(milestone, in: snapshot) else { continue }
            celebrate(milestone)
            return
        }
    }

    func celebrate(_ milestone: MilliMilestone) {
        var reached = celebrated
        reached.insert(milestone.rawValue)
        celebrated = reached

        isStrolling = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            celebration = milestone
        }

        celebrationTask?.cancel()
        celebrationTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.celebrationDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.dismissCelebration()
        }
    }

    func dismissCelebration() {
        celebrationTask?.cancel()
        celebrationTask = nil
        withAnimation(.easeOut(duration: 0.3)) {
            celebration = nil
        }
    }

    static func isReached(_ milestone: MilliMilestone, in snapshot: MilliFinancialSnapshot) -> Bool {
        switch milestone {
        case .bankConnected:
            return snapshot.isBankConnected
        case .firstPayout:
            return snapshot.hasPayouts
        case .reserveQuarter:
            return (snapshot.reserveProgress ?? 0) >= 0.25
        case .reserveHalf:
            return (snapshot.reserveProgress ?? 0) >= 0.5
        case .reserveThreeQuarters:
            return (snapshot.reserveProgress ?? 0) >= 0.75
        case .reserveFunded:
            return (snapshot.reserveProgress ?? 0) >= 1
        case .deductionsFiveHundred:
            return snapshot.deductions >= 500
        case .deductionsTwoThousand:
            return snapshot.deductions >= 2000
        }
    }
}

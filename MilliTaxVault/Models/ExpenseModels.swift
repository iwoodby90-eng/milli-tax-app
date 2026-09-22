import Foundation
import SwiftUI

// MARK: - ExpenseModels
// Extracted from ExpensesView for persistence and testability.
// All models are Codable so they survive app restarts via ExpenseStore.

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case fuel
    case maintenance
    case parking
    case supplies
    case insurance
    case professional
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fuel: return "Fuel"
        case .maintenance: return "Car Maintenance"
        case .parking: return "Tolls & Parking"
        case .supplies: return "Supplies"
        case .insurance: return "Insurance"
        case .professional: return "Professional Services"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .parking: return "parkingsign.circle.fill"
        case .supplies: return "shippingbox.fill"
        case .insurance: return "shield.fill"
        case .professional: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .fuel: return MilliColors.warning
        case .maintenance: return Color(hex: "4285F4")
        case .parking: return MilliColors.deepCyan
        case .supplies: return MilliColors.positive
        case .insurance: return MilliColors.negative
        case .professional: return MilliColors.cyanGlow
        case .other: return MilliColors.textSecondary
        }
    }
}

struct ExpenseItem: Identifiable, Codable, Equatable {
    let id: UUID
    let merchant: String
    let category: ExpenseCategory
    let date: Date
    let amount: Double
    let isDeductible: Bool

    init(id: UUID = UUID(), merchant: String, category: ExpenseCategory, date: Date, amount: Double, isDeductible: Bool) {
        self.id = id
        self.merchant = merchant
        self.category = category
        self.date = date
        self.amount = amount
        self.isDeductible = isDeductible
    }

    static var seeded: [ExpenseItem] {
        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            ExpenseItem(merchant: "Fuel Stop", category: .fuel, date: date(daysAgo: 0), amount: 68.42, isDeductible: true),
            ExpenseItem(merchant: "Vehicle Service", category: .maintenance, date: date(daysAgo: 1), amount: 89.75, isDeductible: true),
            ExpenseItem(merchant: "City Parking", category: .parking, date: date(daysAgo: 3), amount: 24.60, isDeductible: true),
            ExpenseItem(merchant: "Delivery Supplies", category: .supplies, date: date(daysAgo: 5), amount: 12.35, isDeductible: true),
            ExpenseItem(merchant: "Auto Insurance", category: .insurance, date: date(daysAgo: 7), amount: 39.45, isDeductible: true)
        ]
    }
}

struct ReceiptItem: Identifiable, Codable, Equatable {
    let id: UUID
    let merchant: String
    let date: Date
    let amount: Double
    let isLinked: Bool
    /// Name of the scanned image in `ReceiptImageStore`; nil for entries typed by hand.
    let imageFilename: String?

    init(
        id: UUID = UUID(),
        merchant: String,
        date: Date,
        amount: Double,
        isLinked: Bool,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.merchant = merchant
        self.date = date
        self.amount = amount
        self.isLinked = isLinked
        self.imageFilename = imageFilename
    }

    static var seeded: [ReceiptItem] {
        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            ReceiptItem(merchant: "Fuel Stop", date: date(daysAgo: 0), amount: 68.42, isLinked: true),
            ReceiptItem(merchant: "Vehicle Service", date: date(daysAgo: 1), amount: 89.75, isLinked: true),
            ReceiptItem(merchant: "City Parking", date: date(daysAgo: 3), amount: 24.60, isLinked: false)
        ]
    }
}

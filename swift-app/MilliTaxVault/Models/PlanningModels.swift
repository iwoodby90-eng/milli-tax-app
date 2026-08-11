import Foundation

// MARK: - Retirement
struct RetirementPlan {
    var currentBalance: Double
    var monthlyContribution: Double
    var currentAge: Int
    var retirementAge: Int
    var annualReturn: Double
    var accountType: String

    // Placeholder compounding projection — swap for backend math later.
    func projection() -> [RetirementPoint] {
        var points: [RetirementPoint] = []
        var balance = currentBalance
        let monthlyRate = annualReturn / 12
        var age = currentAge
        var year = Calendar.current.component(.year, from: Date())
        while age <= retirementAge {
            points.append(RetirementPoint(year: year, age: age, balance: balance))
            for _ in 0..<12 { balance = balance * (1 + monthlyRate) + monthlyContribution }
            age += 1; year += 1
        }
        return points
    }
    var projectedBalance: Double { projection().last?.balance ?? currentBalance }
}

struct RetirementPoint: Identifiable {
    let id = UUID()
    let year: Int
    let age: Int
    let balance: Double
}

// MARK: - Investments
enum AssetClass: String, CaseIterable, Identifiable {
    case stocks = "Stocks", etfs = "ETFs", crypto = "Crypto", cash = "Cash"
    var id: String { rawValue }
}

struct Holding: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let value: Double
    let dayChangePct: Double
    let spark: [Double]
    let assetClass: AssetClass
}

struct Allocation: Identifiable {
    let id = UUID()
    let assetClass: AssetClass
    let amount: Double
}

// MARK: - Life goals (Tree of Life)
struct LifeGoal: Identifiable {
    let id = UUID()
    var title: String
    var symbol: String
    var target: Double
    var saved: Double
    var targetDate: Date?
    var monthlyAllocation: Double
    var vaultLinked: Bool
    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
}

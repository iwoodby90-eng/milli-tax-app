import Foundation

// MARK: - MilliFinancialSnapshot
// Single derivation point for every figure the dashboard surfaces render.
//
// Nothing here invents money. Payout figures come from the verified payout
// ledger, liability comes from the user's own tax profile through
// QuarterlyTaxEstimator, and deductions come from the expense store. Any
// figure without an authoritative input stays `nil` so the surface can render
// its unavailable state instead of a placeholder number.

struct MilliFinancialSnapshot {
    let isBankConnected: Bool
    let payouts: [VerifiedPayout]
    let taxProfile: TaxProfile?
    let deductions: Double
    let referenceDate: Date

    @MainActor
    static func current(referenceDate: Date = Date()) -> MilliFinancialSnapshot {
        let bank = BankConnectionService.shared
        return MilliFinancialSnapshot(
            isBankConnected: bank.connectedBank != nil,
            payouts: bank.payouts,
            taxProfile: loadTaxProfile(),
            deductions: ExpenseStore.shared.totalDeductions,
            referenceDate: referenceDate
        )
    }

    static func loadTaxProfile() -> TaxProfile? {
        guard let data = UserDefaults.standard.data(forKey: "onboarding_taxProfile"),
              let profile = try? JSONDecoder().decode(TaxProfile.self, from: data),
              profile.annualIncomeAmount != nil else {
            return nil
        }
        return profile
    }

    // MARK: Payout-derived figures

    var hasPayouts: Bool { !payouts.isEmpty }

    /// Gross verified payout volume on record.
    var grossPayouts: Double? {
        guard hasPayouts else { return nil }
        return payouts.reduce(0) { $0 + $1.grossAmount }
    }

    /// Amount withheld into the tax reserve across verified payouts.
    var reservedForTaxes: Double? {
        guard hasPayouts else { return nil }
        return payouts.reduce(0) { $0 + $1.taxProtected }
    }

    var availableToSpend: Double? {
        guard hasPayouts else { return nil }
        return payouts.reduce(0) { $0 + $1.availableToSpend }
    }

    var pendingPayoutCount: Int { payouts.filter(\.isPending).count }

    /// Most recent verified payouts, newest first as stored by the ledger.
    func recentPayouts(limit: Int) -> [VerifiedPayout] {
        Array(payouts.prefix(limit))
    }

    // MARK: Tax-profile-derived figures

    /// Full-year liability estimate from the user's declared income and their
    /// recorded deductible expenses. `nil` until a tax profile exists.
    var annualEstimate: QuarterlyTaxEstimator.Estimate? {
        guard let income = taxProfile?.annualIncomeAmount, income > 0 else { return nil }
        return QuarterlyTaxEstimator.estimate(
            grossIncome: Decimal(income),
            businessExpenses: Decimal(deductions),
            filingStatus: taxProfile?.filingStatus ?? .single
        )
    }

    var annualLiability: Double? {
        annualEstimate.map { NSDecimalNumber(decimal: $0.totalAnnualTax).doubleValue }
    }

    var quarterlyLiability: Double? {
        annualEstimate.map { NSDecimalNumber(decimal: $0.quarterlyPayment).doubleValue }
    }

    var effectiveRate: Double? {
        annualEstimate.map { NSDecimalNumber(decimal: $0.effectiveRate).doubleValue }
    }

    /// How much of the annual liability the reserve currently covers.
    var reserveProgress: Double? {
        guard let reserved = reservedForTaxes, let liability = annualLiability, liability > 0 else {
            return nil
        }
        return min(max(reserved / liability, 0), 1)
    }

    var remainingToGoal: Double? {
        guard let reserved = reservedForTaxes, let liability = annualLiability else { return nil }
        return max(liability - reserved, 0)
    }

    /// Share of the calendar year elapsed, used to pace the reserve.
    var yearProgress: Double {
        let calendar = Calendar.current
        guard let start = calendar.date(from: calendar.dateComponents([.year], from: referenceDate)),
              let end = calendar.date(byAdding: .year, value: 1, to: start) else {
            return 0
        }
        let span = end.timeIntervalSince(start)
        guard span > 0 else { return 0 }
        return min(max(referenceDate.timeIntervalSince(start) / span, 0), 1)
    }

    // MARK: IRS estimated-payment calendar

    /// Next federal estimated-payment due date (IRS quarterly schedule).
    var nextEstimatedPaymentDue: Date? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: referenceDate)
        let schedule: [(month: Int, day: Int, year: Int)] = [
            (4, 15, year), (6, 15, year), (9, 15, year), (1, 15, year + 1)
        ]

        return schedule
            .compactMap { calendar.date(from: DateComponents(year: $0.year, month: $0.month, day: $0.day)) }
            .first { $0 >= calendar.startOfDay(for: referenceDate) }
    }

    /// Label for the quarter the next due date settles, e.g. "Q2 2026".
    var nextEstimatedPaymentPeriod: String? {
        guard let due = nextEstimatedPaymentDue else { return nil }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: due)
        let year = calendar.component(.year, from: due)
        switch month {
        case 4: return "Q1 \(year)"
        case 6: return "Q2 \(year)"
        case 9: return "Q3 \(year)"
        default: return "Q4 \(year - 1)"
        }
    }
}

// MARK: - Formatting helpers

enum MilliFigureFormat {
    /// Currency with cents, or the unavailable dash when there is no value.
    static func currency(_ value: Double?) -> String {
        guard let value else { return MilliPlaceholder.value }
        return value.formatted(.currency(code: "USD"))
    }

    /// Currency rounded to whole dollars for hero figures.
    static func wholeCurrency(_ value: Double?) -> String {
        guard let value else { return MilliPlaceholder.value }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return MilliPlaceholder.value }
        return "\(Int((value * 100).rounded()))%"
    }

    static func date(_ value: Date?) -> String {
        guard let value else { return MilliPlaceholder.value }
        return value.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

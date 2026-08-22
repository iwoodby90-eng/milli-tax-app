import XCTest
@testable import MilliTaxVault

final class TaxEngineTests: XCTestCase {
    func test2026StandardDeductions() {
        // IRS Rev. Proc. 2025-XX / IRC § 63(c)(2)
        let single = TaxEngine.standardDeduction(for: .single)
        let mfs = TaxEngine.standardDeduction(for: .marriedSeparate)
        let mfj = TaxEngine.standardDeduction(for: .marriedJoint)
        let hoh = TaxEngine.standardDeduction(for: .headOfHousehold)

        XCTAssertEqual(single, Money(cents: 16_100_00))
        XCTAssertEqual(mfs, Money(cents: 16_100_00))
        XCTAssertEqual(mfj, Money(cents: 32_200_00))
        XCTAssertEqual(hoh, Money(cents: 24_150_00))
    }

    func test2026SocialSecurityTaxableMaximum() {
        // SSA 2026 Wage Base Announcement: $184,500
        let oasdiCap = TaxEngine.socialSecurityTaxableMaximum()
        XCTAssertEqual(oasdiCap, Money(cents: 184_500_00))
    }

    func testAdditionalMedicareThresholdsByFilingStatus() {
        // Form 8959 / IRC § 3101(b)(2)
        XCTAssertEqual(TaxEngine.additionalMedicareThreshold(for: .marriedJoint), Money(cents: 250_000_00))
        XCTAssertEqual(TaxEngine.additionalMedicareThreshold(for: .marriedSeparate), Money(cents: 125_000_00))
        XCTAssertEqual(TaxEngine.additionalMedicareThreshold(for: .single), Money(cents: 200_000_00))
        XCTAssertEqual(TaxEngine.additionalMedicareThreshold(for: .headOfHousehold), Money(cents: 200_000_00))
    }

    func testSelfEmploymentTaxCalculation() {
        let netIncome = Money(cents: 80_000_00) // $80,000 net gig income
        let result = TaxEngine.calculateSelfEmploymentTax(netGigIncome: netIncome, filingStatus: .single)

        // 92.35% net earnings = $73,880.00
        XCTAssertEqual(result.netEarnings, Money(cents: 73_880_00))

        // 12.4% Social Security = $9,161.12
        XCTAssertEqual(result.socialSecurityTax, Money(cents: 9_161_12))

        // 2.9% Medicare = $2,142.52
        XCTAssertEqual(result.medicareTax, Money(cents: 2_142_52))

        // Total SE = $11,303.64
        XCTAssertEqual(result.totalSelfEmploymentTax, Money(cents: 11_303_64))

        // 50% above-the-line deduction = $5,651.82
        XCTAssertEqual(result.deductiblePortion, Money(cents: 5_651_82))
    }

    func testHighEarnerAdditionalMedicareTax() {
        let highGigIncome = Money(cents: 300_000_00) // $300,000 net gig income
        // Net SE earnings = $300,000 * 0.9235 = $277,050.00
        
        let singleResult = TaxEngine.calculateSelfEmploymentTax(netGigIncome: highGigIncome, filingStatus: .single)
        // Single threshold $200k -> Excess $77,050 @ 0.9% = $693.45
        XCTAssertEqual(singleResult.additionalMedicareTax, Money(cents: 693_45))

        let mfjResult = TaxEngine.calculateSelfEmploymentTax(netGigIncome: highGigIncome, filingStatus: .marriedJoint)
        // MFJ threshold $250k -> Excess $27,050 @ 0.9% = $243.45
        XCTAssertEqual(mfjResult.additionalMedicareTax, Money(cents: 243_45))

        let mfsResult = TaxEngine.calculateSelfEmploymentTax(netGigIncome: highGigIncome, filingStatus: .marriedSeparate)
        // MFS threshold $125k -> Excess $152,050 @ 0.9% = $1,368.45
        XCTAssertEqual(mfsResult.additionalMedicareTax, Money(cents: 1_368_45))
    }

    func testEffectiveDatedMileageRatesByTripDate() {
        let calendar = Calendar(identifier: .gregorian)
        
        // H1 Trip: March 15, 2026 -> 72.5¢ / mile
        var h1Components = DateComponents()
        h1Components.year = 2026
        h1Components.month = 3
        h1Components.day = 15
        let h1Date = calendar.date(from: h1Components)!
        
        let h1Rate = TaxEngine.businessMileageRate(for: h1Date)
        XCTAssertEqual(h1Rate, Decimal(string: "0.725")!)
        
        let h1Deduction = TaxEngine.calculateMileageDeduction(miles: 1000.0, date: h1Date)
        XCTAssertEqual(h1Deduction, Money(cents: 725_00)) // $725.00

        // H2 Trip: August 20, 2026 -> 76.0¢ / mile
        var h2Components = DateComponents()
        h2Components.year = 2026
        h2Components.month = 8
        h2Components.day = 20
        let h2Date = calendar.date(from: h2Components)!
        
        let h2Rate = TaxEngine.businessMileageRate(for: h2Date)
        XCTAssertEqual(h2Rate, Decimal(string: "0.760")!)
        
        let h2Deduction = TaxEngine.calculateMileageDeduction(miles: 1000.0, date: h2Date)
        XCTAssertEqual(h2Deduction, Money(cents: 760_00)) // $760.00
    }

    func testQuarterlyEstimatedTaxSchedule() {
        let annualLiability = Money(cents: 12_000_00) // $12,000
        let schedule = TaxEngine.calculateQuarterlyEstimatedPayments(annualTaxLiability: annualLiability, year: 2026)

        XCTAssertEqual(schedule.quarterlyPaymentAmount, Money(cents: 3_000_00))
        XCTAssertEqual(schedule.q1DueDate, "April 15, 2026")
        XCTAssertEqual(schedule.q2DueDate, "June 15, 2026")
        XCTAssertEqual(schedule.q3DueDate, "September 15, 2026")
        XCTAssertEqual(schedule.q4DueDate, "January 15, 2027")
    }

    func testMilliCentsProfitabilityAnalysis() {
        let calendar = Calendar(identifier: .gregorian)
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 7
        comp.day = 10
        let tripDate = calendar.date(from: comp)!

        let analysis = TaxEngine.calculateMilliCentsProfitability(
            offerGross: Money(cents: 24_50),
            totalMiles: 8.2,
            estimatedTimeMinutes: 28,
            tripDate: tripDate,
            gasPricePerGallon: Money(cents: 385),
            vehicleMpg: 26.0
        )

        XCTAssertEqual(analysis.effectiveMileageRate, Decimal(string: "0.760")!)
        XCTAssertTrue(analysis.netProfit.isPositive)
        XCTAssertEqual(analysis.recommendation, .go)
    }
}

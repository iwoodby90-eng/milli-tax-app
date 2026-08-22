import XCTest
@testable import MilliTaxVault

final class TaxEngineTests: XCTestCase {
    // MARK: - 1. Standard Deductions (IRS Rev. Proc. 2025-32, Sec. 3.16 / IRC § 63(c)(2))
    func test2026StandardDeductions() throws {
        let single = try TaxEngine.standardDeduction(for: .single)
        let mfs = try TaxEngine.standardDeduction(for: .marriedSeparate)
        let mfj = try TaxEngine.standardDeduction(for: .marriedJoint)
        let hoh = try TaxEngine.standardDeduction(for: .headOfHousehold)

        XCTAssertEqual(single, Money(cents: 16_100_00))
        XCTAssertEqual(mfs, Money(cents: 16_100_00))
        XCTAssertEqual(mfj, Money(cents: 32_200_00))
        XCTAssertEqual(hoh, Money(cents: 24_150_00))

        // Historical 2025 standard deductions (Rev. Proc. 2024-40)
        XCTAssertEqual(try TaxEngine.standardDeduction(for: .single, year: 2025), Money(cents: 15_000_00))
        XCTAssertEqual(try TaxEngine.standardDeduction(for: .marriedJoint, year: 2025), Money(cents: 30_000_00))
        XCTAssertEqual(try TaxEngine.standardDeduction(for: .headOfHousehold, year: 2025), Money(cents: 22_500_00))
    }

    // MARK: - 2. OASDI Wage Base Cap (SSA 2026 Wage Base Announcement / 89 FR 84431)
    func test2026SocialSecurityTaxableMaximum() throws {
        let oasdiCap2026 = try TaxEngine.socialSecurityTaxableMaximum(year: 2026)
        XCTAssertEqual(oasdiCap2026, Money(cents: 184_500_00))

        let oasdiCap2025 = try TaxEngine.socialSecurityTaxableMaximum(year: 2025)
        XCTAssertEqual(oasdiCap2025, Money(cents: 176_100_00))
    }

    // MARK: - 3. Additional Medicare Tax Thresholds (IRC § 3101(b)(2) / Form 8959)
    func testAdditionalMedicareThresholdsByFilingStatus() throws {
        XCTAssertEqual(try TaxEngine.additionalMedicareThreshold(for: .marriedJoint), Money(cents: 250_000_00))
        XCTAssertEqual(try TaxEngine.additionalMedicareThreshold(for: .marriedSeparate), Money(cents: 125_000_00))
        XCTAssertEqual(try TaxEngine.additionalMedicareThreshold(for: .single), Money(cents: 200_000_00))
        XCTAssertEqual(try TaxEngine.additionalMedicareThreshold(for: .headOfHousehold), Money(cents: 200_000_00))
    }

    // MARK: - 4. Federal Bracket Boundary Tests (Single, MFJ, MFS, HOH)
    // Official 2026 schedules from IRS Rev. Proc. 2025-32, Sec. 3.01
    // Tests values immediately below (T - 1¢), exactly at (T), and immediately above (T + 1¢) for every boundary.
    
    func testSingleBracketBoundaries() throws {
        // Thresholds: $12,400 (10%->12%), $50,400 (12%->22%), $105,700 (22%->24%),
        //             $201,775 (24%->32%), $256,225 (32%->35%), $640,600 (35%->37%)
        let status = TaxProfile.FilingStatus.single

        // $0
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 0), filingStatus: status), Money(cents: 0))

        // Threshold 1: $12,400 (Base tax at threshold = $1,240.00)
        let t1_below = Money(cents: 12_399_99) // $12,399.99 @ 10%
        let t1_at = Money(cents: 12_400_00)    // $12,400.00 -> $1,240.00
        let t1_above = Money(cents: 12_400_01) // $12,400.00 + $0.01 @ 12%
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: t1_below, filingStatus: status), Money(cents: 1_240_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: t1_at, filingStatus: status), Money(cents: 1_240_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: t1_above, filingStatus: status), Money(cents: 1_240_00))
        // Test with $1 delta for explicit rate slope verification
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 12_399_00), filingStatus: status), Money(cents: 1_239_90))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 12_401_00), filingStatus: status), Money(cents: 1_240_12))

        // Threshold 2: $50,400 (Base tax = $1,240 + $4,560 = $5,800.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 50_399_00), filingStatus: status), Money(cents: 5_799_88))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 50_400_00), filingStatus: status), Money(cents: 5_800_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 50_401_00), filingStatus: status), Money(cents: 5_800_22))

        // Threshold 3: $105,700 (Base tax = $5,800 + $12,166 = $17,966.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_699_00), filingStatus: status), Money(cents: 17_965_78))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_700_00), filingStatus: status), Money(cents: 17_966_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_701_00), filingStatus: status), Money(cents: 17_966_24))

        // Threshold 4: $201,775 (Base tax = $17,966 + $23,058 = $41,024.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_774_00), filingStatus: status), Money(cents: 41_023_76))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_775_00), filingStatus: status), Money(cents: 41_024_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_776_00), filingStatus: status), Money(cents: 41_024_32))

        // Threshold 5: $256,225 (Base tax = $41,024 + $17,424 = $58,448.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_224_00), filingStatus: status), Money(cents: 58_447_68))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_225_00), filingStatus: status), Money(cents: 58_448_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_226_00), filingStatus: status), Money(cents: 58_448_35))

        // Threshold 6: $640,600 (Base tax = $58,448 + $134,531.25 = $192,979.25)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_599_00), filingStatus: status), Money(cents: 192_978_90))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_600_00), filingStatus: status), Money(cents: 192_979_25))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_601_00), filingStatus: status), Money(cents: 192_979_62))
    }

    func testMarriedFilingJointlyBracketBoundaries() throws {
        // Thresholds: $24,800 (10%->12%), $100,800 (12%->22%), $211,400 (22%->24%),
        //             $403,550 (24%->32%), $512,450 (32%->35%), $768,700 (35%->37%)
        let status = TaxProfile.FilingStatus.marriedJoint

        // Threshold 1: $24,800 (Base tax = $2,480.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 24_799_00), filingStatus: status), Money(cents: 2_479_90))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 24_800_00), filingStatus: status), Money(cents: 2_480_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 24_801_00), filingStatus: status), Money(cents: 2_480_12))

        // Threshold 2: $100,800 (Base tax = $2,480 + $9,120 = $11,600.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 100_799_00), filingStatus: status), Money(cents: 11_599_88))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 100_800_00), filingStatus: status), Money(cents: 11_600_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 100_801_00), filingStatus: status), Money(cents: 11_600_22))

        // Threshold 3: $211,400 (Base tax = $11,600 + $24,332 = $35,932.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 211_399_00), filingStatus: status), Money(cents: 35_931_78))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 211_400_00), filingStatus: status), Money(cents: 35_932_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 211_401_00), filingStatus: status), Money(cents: 35_932_24))

        // Threshold 4: $403,550 (Base tax = $35,932 + $46,116 = $82,048.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 403_549_00), filingStatus: status), Money(cents: 82_047_76))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 403_550_00), filingStatus: status), Money(cents: 82_048_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 403_551_00), filingStatus: status), Money(cents: 82_048_32))

        // Threshold 5: $512,450 (Base tax = $82,048 + $34,848 = $116,896.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 512_449_00), filingStatus: status), Money(cents: 116_895_68))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 512_450_00), filingStatus: status), Money(cents: 116_896_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 512_451_00), filingStatus: status), Money(cents: 116_896_35))

        // Threshold 6: $768,700 (Base tax = $116,896 + $89,687.50 = $206,583.50)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 768_699_00), filingStatus: status), Money(cents: 206_583_15))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 768_700_00), filingStatus: status), Money(cents: 206_583_50))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 768_701_00), filingStatus: status), Money(cents: 206_583_87))
    }

    func testMarriedFilingSeparatelyBracketBoundaries() throws {
        // MFS matches Single through $256,225, but 35% bracket caps at $384,350 (half of MFJ $768,700)
        let status = TaxProfile.FilingStatus.marriedSeparate

        // Threshold 1: $12,400
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 12_400_00), filingStatus: status), Money(cents: 1_240_00))
        // Threshold 2: $50,400
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 50_400_00), filingStatus: status), Money(cents: 5_800_00))
        // Threshold 3: $105,700
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_700_00), filingStatus: status), Money(cents: 17_966_00))
        // Threshold 4: $201,775
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_775_00), filingStatus: status), Money(cents: 41_024_00))
        // Threshold 5: $256,225
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_225_00), filingStatus: status), Money(cents: 58_448_00))

        // Threshold 6: $384,350 (DIVERGENCE POINT from Single $640,600)
        // Base tax at $384,350 = $58,448 + ($128,125 * 35% = $44,843.75) = $103,291.75
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 384_349_00), filingStatus: status), Money(cents: 103_291_40))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 384_350_00), filingStatus: status), Money(cents: 103_291_75))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 384_351_00), filingStatus: status), Money(cents: 103_292_12))

        // Confirm Single at $384,350 is in 35% bracket, while MFS at $384,351 is in 37% bracket
        let singleTaxAt385k = try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 385_000_00), filingStatus: .single)
        let mfsTaxAt385k = try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 385_000_00), filingStatus: .marriedSeparate)
        XCTAssertTrue(mfsTaxAt385k > singleTaxAt385k, "MFS reaches 37% bracket at $384,350, so tax must be strictly higher than Single")
    }

    func testHeadOfHouseholdBracketBoundaries() throws {
        // Thresholds: $17,700 (10%->12%), $67,450 (12%->22%), $105,700 (22%->24%),
        //             $201,750 (24%->32%), $256,200 (32%->35%), $640,600 (35%->37%)
        let status = TaxProfile.FilingStatus.headOfHousehold

        // Threshold 1: $17,700 (Base tax = $1,770.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 17_699_00), filingStatus: status), Money(cents: 1_769_90))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 17_700_00), filingStatus: status), Money(cents: 1_770_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 17_701_00), filingStatus: status), Money(cents: 1_770_12))

        // Threshold 2: $67,450 (Base tax = $1,770 + $5,970 = $7,740.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 67_449_00), filingStatus: status), Money(cents: 7_739_88))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 67_450_00), filingStatus: status), Money(cents: 7_740_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 67_451_00), filingStatus: status), Money(cents: 7_740_22))

        // Threshold 3: $105,700 (Base tax = $7,740 + $8,415 = $16,155.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_699_00), filingStatus: status), Money(cents: 16_154_78))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_700_00), filingStatus: status), Money(cents: 16_155_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 105_701_00), filingStatus: status), Money(cents: 16_155_24))

        // Threshold 4: $201,750 (Base tax = $16,155 + $23,052 = $39,207.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_749_00), filingStatus: status), Money(cents: 39_206_76))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_750_00), filingStatus: status), Money(cents: 39_207_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 201_751_00), filingStatus: status), Money(cents: 39_207_32))

        // Threshold 5: $256,200 (Base tax = $39,207 + $17,424 = $56,631.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_199_00), filingStatus: status), Money(cents: 56_630_68))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_200_00), filingStatus: status), Money(cents: 56_631_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 256_201_00), filingStatus: status), Money(cents: 56_631_35))

        // Threshold 6: $640,600 (Base tax = $56,631 + $134,540 = $191,171.00)
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_599_00), filingStatus: status), Money(cents: 191_170_90))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_600_00), filingStatus: status), Money(cents: 191_171_00))
        XCTAssertEqual(try TaxEngine.calculateFederalIncomeTax(taxableIncome: Money(cents: 640_601_00), filingStatus: status), Money(cents: 191_171_37))
    }

    // MARK: - 5. Mixed Income Self-Employment Tax Tests (W-2 + SE Income)
    func testMixedIncomeSelfEmploymentTax() throws {
        let netIncome = Money(cents: 50_000_00) // $50,000 net gig income
        // Net SE earnings = $50,000 * 0.9235 = $46,175.00

        // Case A: No W-2 wages ($0 W-2)
        let resA = try TaxEngine.calculateSelfEmploymentTax(
            netGigIncome: netIncome,
            filingStatus: .single,
            w2SocialSecurityWages: .zero,
            w2MedicareWages: .zero
        )
        XCTAssertEqual(resA.netEarnings, Money(cents: 46_175_00))
        XCTAssertEqual(resA.remainingOASDICap, Money(cents: 184_500_00))
        XCTAssertEqual(resA.socialSecurityTax, Money(cents: 5_725_70)) // $46,175 * 12.4%
        XCTAssertEqual(resA.medicareTax, Money(cents: 1_339_08))       // $46,175 * 2.9%
        XCTAssertEqual(resA.additionalMedicareTax, .zero)

        // Case B: Partial W-2 OASDI consumption (W-2 SS Wages = $150,000)
        // Remaining OASDI cap = $184,500 - $150,000 = $34,500.00
        // SS taxable SE earnings = min($46,175, $34,500) = $34,500.00
        // SS Tax on SE = $34,500 * 12.4% = $4,278.00
        let resB = try TaxEngine.calculateSelfEmploymentTax(
            netGigIncome: netIncome,
            filingStatus: .single,
            w2SocialSecurityWages: Money(cents: 150_000_00),
            w2MedicareWages: Money(cents: 150_000_00)
        )
        XCTAssertEqual(resB.remainingOASDICap, Money(cents: 34_500_00))
        XCTAssertEqual(resB.socialSecurityTax, Money(cents: 4_278_00))
        XCTAssertEqual(resB.medicareTax, Money(cents: 1_339_08))
        XCTAssertEqual(resB.additionalMedicareTax, .zero) // Total Medicare comp = $150k + $46.175k = $196.175k < $200k

        // Case C: Fully capped W-2 OASDI (W-2 SS Wages = $184,500)
        // Remaining OASDI cap = $0 -> SS Tax on SE must be exactly $0!
        let resC = try TaxEngine.calculateSelfEmploymentTax(
            netGigIncome: netIncome,
            filingStatus: .single,
            w2SocialSecurityWages: Money(cents: 184_500_00),
            w2MedicareWages: Money(cents: 184_500_00)
        )
        XCTAssertEqual(resC.remainingOASDICap, .zero)
        XCTAssertEqual(resC.socialSecurityTax, .zero)
        XCTAssertEqual(resC.medicareTax, Money(cents: 1_339_08))
        // Additional Medicare: W-2 Medicare = $184,500. Remaining threshold = $200,000 - $184,500 = $15,500
        // SE earnings subject to AddMed = $46,175 - $15,500 = $30,675 @ 0.9% = $276.08
        XCTAssertEqual(resC.additionalMedicareTax, Money(cents: 276_08))

        // Case D: Exceeded W-2 OASDI (W-2 SS Wages = $200,000, W-2 Medicare = $220,000)
        // SS Tax on SE = $0. Remaining threshold for AddMed = $0 -> ALL $46,175 subject to 0.9% = $415.58
        let resD = try TaxEngine.calculateSelfEmploymentTax(
            netGigIncome: netIncome,
            filingStatus: .single,
            w2SocialSecurityWages: Money(cents: 200_000_00),
            w2MedicareWages: Money(cents: 220_000_00)
        )
        XCTAssertEqual(resD.remainingOASDICap, .zero)
        XCTAssertEqual(resD.socialSecurityTax, .zero)
        XCTAssertEqual(resD.medicareTax, Money(cents: 1_339_08))
        XCTAssertEqual(resD.additionalMedicareTax, Money(cents: 415_58))
        XCTAssertEqual(resD.totalSelfEmploymentTax, Money(cents: 1_754_66)) // $1,339.08 + $415.58
        XCTAssertEqual(resD.deductiblePortion, Money(cents: 877_33))        // 50% above-the-line
    }

    // MARK: - 6. Unsupported Tax Year & Rule Resolution Errors (Strict Error Handling)
    func testUnsupportedTaxYearThrowsError() {
        // Requesting unsupported tax years must throw TaxEngineError.unsupportedTaxYear
        XCTAssertThrowsError(try TaxEngine.standardDeduction(for: .single, year: 2027)) { error in
            XCTAssertEqual(error as? TaxEngineError, TaxEngineError.unsupportedTaxYear(2027))
        }

        XCTAssertThrowsError(try TaxEngine.socialSecurityTaxableMaximum(year: 2024)) { error in
            XCTAssertEqual(error as? TaxEngineError, TaxEngineError.unsupportedTaxYear(2024))
        }

        XCTAssertThrowsError(try TaxEngine.federalBrackets(for: .single, year: 2028)) { error in
            XCTAssertEqual(error as? TaxEngineError, TaxEngineError.unsupportedTaxYear(2028))
        }

        // Unsupported trip dates
        let calendar = Calendar(identifier: .gregorian)
        var comp = DateComponents()
        comp.year = 2028
        comp.month = 5
        comp.day = 1
        let futureDate = calendar.date(from: comp)!

        XCTAssertThrowsError(try TaxEngine.businessMileageRate(for: futureDate)) { error in
            XCTAssertEqual(error as? TaxEngineError, TaxEngineError.unsupportedTripDate(futureDate))
        }
    }

    // MARK: - 7. Effective-Dated Mileage Rates by Trip Date
    func testEffectiveDatedMileageRatesByTripDate() throws {
        let calendar = Calendar(identifier: .gregorian)
        
        // H1 Trip: March 15, 2026 -> 72.5¢ / mile (IRS Notice 2025-88)
        var h1Components = DateComponents()
        h1Components.year = 2026
        h1Components.month = 3
        h1Components.day = 15
        let h1Date = calendar.date(from: h1Components)!
        
        let h1Rate = try TaxEngine.businessMileageRate(for: h1Date)
        XCTAssertEqual(h1Rate, Decimal(string: "0.725")!)
        
        let h1Deduction = try TaxEngine.calculateMileageDeduction(miles: 1000.0, date: h1Date)
        XCTAssertEqual(h1Deduction, Money(cents: 725_00)) // $725.00

        // H2 Trip: August 20, 2026 -> 76.0¢ / mile (IRS Notice 2026-01)
        var h2Components = DateComponents()
        h2Components.year = 2026
        h2Components.month = 8
        h2Components.day = 20
        let h2Date = calendar.date(from: h2Components)!
        
        let h2Rate = try TaxEngine.businessMileageRate(for: h2Date)
        XCTAssertEqual(h2Rate, Decimal(string: "0.760")!)
        
        let h2Deduction = try TaxEngine.calculateMileageDeduction(miles: 1000.0, date: h2Date)
        XCTAssertEqual(h2Deduction, Money(cents: 760_00)) // $760.00

        // 2025 Historical Trip: October 10, 2025 -> 70.0¢ / mile (IRS Notice 2024-88)
        var y2025Components = DateComponents()
        y2025Components.year = 2025
        y2025Components.month = 10
        y2025Components.day = 10
        let y2025Date = calendar.date(from: y2025Components)!

        let y2025Rate = try TaxEngine.businessMileageRate(for: y2025Date)
        XCTAssertEqual(y2025Rate, Decimal(string: "0.700")!)
        let y2025Deduction = try TaxEngine.calculateMileageDeduction(miles: 1000.0, date: y2025Date)
        XCTAssertEqual(y2025Deduction, Money(cents: 700_00))
    }

    // MARK: - 8. Quarterly Estimated Tax Schedule (Form 1040-ES)
    func testQuarterlyEstimatedTaxSchedule() {
        let annualLiability = Money(cents: 12_000_00) // $12,000
        let schedule = TaxEngine.calculateQuarterlyEstimatedPayments(annualTaxLiability: annualLiability, year: 2026)

        XCTAssertEqual(schedule.quarterlyPaymentAmount, Money(cents: 3_000_00))
        XCTAssertEqual(schedule.q1DueDate, "April 15, 2026")
        XCTAssertEqual(schedule.q2DueDate, "June 15, 2026")
        XCTAssertEqual(schedule.q3DueDate, "September 15, 2026")
        XCTAssertEqual(schedule.q4DueDate, "January 15, 2027")
    }

    // MARK: - 9. Milli Cents Gig Offer Profitability Analysis
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
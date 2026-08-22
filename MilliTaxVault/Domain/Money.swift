import Foundation

// MARK: - Milli Money & Deterministic Currency Math
// Backed by Foundation.Decimal and exact integer cents (Int64).
// Eliminates IEEE-754 floating-point drift across all MILLI financial calculations.

public struct Money: Codable, Hashable, Comparable, CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public let decimalValue: Decimal
    public let currency: String

    // MARK: - Constants
    public static let zero = Money(cents: 0)
    public static let min = Money(decimal: Decimal.leastFiniteMagnitude)
    public static let max = Money(decimal: Decimal.greatestFiniteMagnitude)

    // MARK: - Initializers
    public init(decimal: Decimal, currency: String = "USD") {
        self.decimalValue = decimal
        self.currency = currency
    }

    public init(cents: Int64, currency: String = "USD") {
        let dec = Decimal(cents) / Decimal(100)
        self.decimalValue = dec
        self.currency = currency
    }

    public init(double: Double, currency: String = "USD") {
        // Safe conversion via formatted string to eliminate binary float artifacts (e.g., 0.1 + 0.2 != 0.3)
        let formatted = String(format: "%.4f", double)
        let dec = Decimal(string: formatted) ?? Decimal(double)
        self.decimalValue = dec
        self.currency = currency
    }

    public init(string: String, currency: String = "USD") {
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let dec = Decimal(string: cleaned) ?? Decimal.zero
        self.decimalValue = dec
        self.currency = currency
    }

    public init(integerLiteral value: Int) {
        self.init(cents: Int64(value) * 100)
    }

    public init(floatLiteral value: Double) {
        self.init(double: value)
    }

    // MARK: - Computed Properties
    public var cents: Int64 {
        let roundedDecimal = MilliRounding.round(decimal: decimalValue, scale: 2, policy: .halfUp)
        let scaled = roundedDecimal * 100
        return NSDecimalNumber(decimal: scaled).int64Value
    }

    public var doubleValue: Double {
        NSDecimalNumber(decimal: decimalValue).doubleValue
    }

    public var isZero: Bool {
        decimalValue == Decimal.zero
    }

    public var isPositive: Bool {
        decimalValue > Decimal.zero
    }

    public var isNegative: Bool {
        decimalValue < Decimal.zero
    }

    public var absolute: Money {
        Money(decimal: Swift.abs(decimalValue), currency: currency)
    }

    // MARK: - Formatting
    public func formattedCurrency(showCents: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = showCents ? 2 : 0
        formatter.minimumFractionDigits = showCents ? 2 : 0
        let number = NSDecimalNumber(decimal: decimalValue)
        return formatter.string(from: number) ?? "$\(formattedPlain(scale: showCents ? 2 : 0))"
    }

    public func formattedPlain(scale: Int = 2) -> String {
        let rounded = MilliRounding.round(decimal: decimalValue, scale: scale, policy: .halfUp)
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = scale
        formatter.maximumFractionDigits = scale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSDecimalNumber(decimal: rounded)) ?? "\(rounded)"
    }

    public var description: String {
        formattedCurrency(showCents: true)
    }

    // MARK: - Rounding
    public func rounded(scale: Int = 2, policy: RoundingPolicy = .halfUp) -> Money {
        let roundedDec = MilliRounding.round(decimal: decimalValue, scale: scale, policy: policy)
        return Money(decimal: roundedDec, currency: currency)
    }

    // MARK: - Arithmetic Operators
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency, "Cannot add Money of different currencies (\(lhs.currency) vs \(rhs.currency))")
        return Money(decimal: lhs.decimalValue + rhs.decimalValue, currency: lhs.currency)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency, "Cannot subtract Money of different currencies (\(lhs.currency) vs \(rhs.currency))")
        return Money(decimal: lhs.decimalValue - rhs.decimalValue, currency: lhs.currency)
    }

    public static func * (lhs: Money, rhs: Decimal) -> Money {
        Money(decimal: lhs.decimalValue * rhs, currency: lhs.currency)
    }

    public static func * (lhs: Decimal, rhs: Money) -> Money {
        Money(decimal: lhs * rhs.decimalValue, currency: rhs.currency)
    }

    public static func * (lhs: Money, rhs: Int) -> Money {
        Money(decimal: lhs.decimalValue * Decimal(rhs), currency: lhs.currency)
    }

    public static func * (lhs: Money, rhs: Double) -> Money {
        lhs * Decimal(string: String(format: "%.6f", rhs))!
    }

    public static func / (lhs: Money, rhs: Decimal) -> Money {
        precondition(rhs != Decimal.zero, "Division by zero in Money arithmetic")
        return Money(decimal: lhs.decimalValue / rhs, currency: lhs.currency)
    }

    public static func / (lhs: Money, rhs: Int) -> Money {
        precondition(rhs != 0, "Division by zero in Money arithmetic")
        return Money(decimal: lhs.decimalValue / Decimal(rhs), currency: lhs.currency)
    }

    public static func / (lhs: Money, rhs: Double) -> Money {
        precondition(rhs != 0, "Division by zero in Money arithmetic")
        let dec = Decimal(string: String(format: "%.6f", rhs))!
        return Money(decimal: lhs.decimalValue / dec, currency: lhs.currency)
    }

    public static prefix func - (money: Money) -> Money {
        Money(decimal: -money.decimalValue, currency: money.currency)
    }

    // MARK: - Comparable
    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currency == rhs.currency, "Cannot compare Money of different currencies (\(lhs.currency) vs \(rhs.currency))")
        return lhs.decimalValue < rhs.decimalValue
    }

    public static func == (lhs: Money, rhs: Money) -> Bool {
        lhs.currency == rhs.currency && lhs.cents == rhs.cents
    }

    // MARK: - Codable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decString = try? container.decode(String.self) {
            self.init(string: decString)
        } else if let intCents = try? container.decode(Int64.self) {
            self.init(cents: intCents)
        } else if let dbl = try? container.decode(Double.self) {
            self.init(double: dbl)
        } else {
            let dec = try container.decode(Decimal.self)
            self.init(decimal: dec)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(formattedPlain(scale: 2))
    }
}

import Foundation
import SwiftUI

// MARK: - MarketDataViewModel
// Pulls real OHLC market observations from the existing Yahoo Finance chart
// transport. There is deliberately no synthetic/random fallback: if the external
// feed is unavailable the UI says so instead of drawing invented prices.

@MainActor
final class MarketDataViewModel: ObservableObject {
    @Published var chartPoints: [ChartPricePoint] = []
    @Published var candles: [LiveOHLCCandle] = []
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var percentChange: Double = 0
    @Published var selectedTicker: String = "VOO"
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var latestMarketTimestamp: Date?
    @Published var feedStatus: MarketFeedStatus = .loading

    @Published var indices: [MarketIndex] = [
        MarketIndex(symbol: "^GSPC", name: "S&P 500", value: 0, change: 0, isLive: false),
        MarketIndex(symbol: "^IXIC", name: "NASDAQ", value: 0, change: 0, isLive: false),
        MarketIndex(symbol: "^DJI", name: "DOW JONES", value: 0, change: 0, isLive: false)
    ]

    @Published var holdings: [LiveHolding] = [
        LiveHolding(ticker: "AAPL", name: "Apple Inc.", price: 0, change: 0, sparkData: [], isLive: false),
        LiveHolding(ticker: "VOO", name: "Vanguard S&P 500 ETF", price: 0, change: 0, sparkData: [], isLive: false),
        LiveHolding(ticker: "BTC-USD", name: "Bitcoin", price: 0, change: 0, sparkData: [], isLive: false),
        LiveHolding(ticker: "NVDA", name: "NVIDIA Corp.", price: 0, change: 0, sparkData: [], isLive: false),
        LiveHolding(ticker: "QQQ", name: "Invesco QQQ", price: 0, change: 0, sparkData: [], isLive: false)
    ]

    private var chartTimer: Timer?
    private var indicesTimer: Timer?
    private var activeInterval = "1h"
    private var activeRange = "1mo"

    init() {
        fetchChart(for: selectedTicker, interval: activeInterval, range: activeRange)
        fetchIndices()
        refreshHoldings()
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        // Polling rather than pretending to stream. Every refresh re-reads the
        // external market feed and rebuilds the latest real OHLC candle sequence.
        chartTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.fetchChart(
                    for: self.selectedTicker,
                    interval: self.activeInterval,
                    range: self.activeRange
                )
                self.refreshHoldings()
            }
        }

        indicesTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchIndices()
            }
        }
    }

    func stopAutoRefresh() {
        chartTimer?.invalidate()
        chartTimer = nil
        indicesTimer?.invalidate()
        indicesTimer = nil
    }

    func switchTicker(_ ticker: String) {
        selectedTicker = ticker
        fetchChart(for: ticker, interval: activeInterval, range: activeRange)
    }

    func fetchChart(
        for symbol: String,
        interval: String = "5m",
        range: String = "1d"
    ) {
        selectedTicker = symbol
        activeInterval = interval
        activeRange = range
        isLoading = true
        feedStatus = .loading

        Task {
            guard let url = marketChartURL(symbol: symbol, interval: interval, range: range) else {
                markChartUnavailable()
                return
            }

            do {
                let (data, response) = try await performMarketRequest(url: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let chart = parsed["chart"] as? [String: Any],
                      let results = (chart["result"] as? [[String: Any]])?.first,
                      let timestamps = results["timestamp"] as? [Int],
                      let indicators = results["indicators"] as? [String: Any],
                      let quotes = (indicators["quote"] as? [[String: Any]])?.first
                else {
                    markChartUnavailable()
                    return
                }

                let opens = numberArray(quotes["open"])
                let highs = numberArray(quotes["high"])
                let lows = numberArray(quotes["low"])
                let closes = numberArray(quotes["close"])

                guard !opens.isEmpty, !highs.isEmpty, !lows.isEmpty, !closes.isEmpty else {
                    markChartUnavailable()
                    return
                }

                var newPoints: [ChartPricePoint] = []
                var newCandles: [LiveOHLCCandle] = []

                for (index, timestamp) in timestamps.enumerated() {
                    guard let open = flattenedValue(opens, at: index),
                          let high = flattenedValue(highs, at: index),
                          let low = flattenedValue(lows, at: index),
                          let close = flattenedValue(closes, at: index),
                          open.isFinite,
                          high.isFinite,
                          low.isFinite,
                          close.isFinite,
                          high >= low
                    else {
                        continue
                    }

                    let time = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    newPoints.append(ChartPricePoint(time: time, price: close))
                    newCandles.append(
                        LiveOHLCCandle(
                            time: time,
                            open: open,
                            high: high,
                            low: low,
                            close: close
                        )
                    )
                }

                guard let first = newCandles.first,
                      let last = newCandles.last
                else {
                    markChartUnavailable()
                    return
                }

                chartPoints = newPoints
                candles = newCandles
                currentPrice = last.close
                priceChange = last.close - first.open
                percentChange = first.open > 0 ? (priceChange / first.open) * 100 : 0
                latestMarketTimestamp = last.time
                lastUpdated = Date()
                feedStatus = .live
                isLoading = false
            } catch {
                markChartUnavailable()
            }
        }
    }

    func fetchIndices() {
        let symbols = ["^GSPC", "^IXIC", "^DJI"]
        let names = ["S&P 500", "NASDAQ", "DOW JONES"]

        for (index, symbol) in symbols.enumerated() {
            Task {
                guard let url = marketChartURL(symbol: symbol, interval: "1d", range: "5d") else { return }

                do {
                    let (data, response) = try await performMarketRequest(url: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let chart = parsed["chart"] as? [String: Any],
                          let results = (chart["result"] as? [[String: Any]])?.first,
                          let meta = results["meta"] as? [String: Any],
                          let regularPrice = number(meta["regularMarketPrice"])
                    else {
                        return
                    }

                    let previousClose = number(meta["previousClose"])
                        ?? number(meta["chartPreviousClose"])
                        ?? regularPrice
                    let change = previousClose > 0
                        ? ((regularPrice - previousClose) / previousClose) * 100
                        : 0

                    guard indices.indices.contains(index) else { return }
                    indices[index] = MarketIndex(
                        symbol: symbol,
                        name: names[index],
                        value: regularPrice,
                        change: change,
                        isLive: true
                    )
                } catch {
                    // Preserve explicit non-live state rather than fabricating a value.
                }
            }
        }
    }

    func refreshHoldings() {
        for (index, holding) in holdings.enumerated() {
            Task {
                guard let url = marketChartURL(symbol: holding.ticker, interval: "15m", range: "5d") else { return }

                do {
                    let (data, response) = try await performMarketRequest(url: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let chart = parsed["chart"] as? [String: Any],
                          let results = (chart["result"] as? [[String: Any]])?.first,
                          let meta = results["meta"] as? [String: Any],
                          let regularPrice = number(meta["regularMarketPrice"])
                    else {
                        return
                    }

                    let previousClose = number(meta["previousClose"])
                        ?? number(meta["chartPreviousClose"])
                        ?? regularPrice
                    let change = previousClose > 0
                        ? ((regularPrice - previousClose) / previousClose) * 100
                        : 0

                    var spark: [Double] = []
                    if let indicators = results["indicators"] as? [String: Any],
                       let quotes = (indicators["quote"] as? [[String: Any]])?.first {
                        spark = Array(numberArray(quotes["close"]).compactMap { $0 }.suffix(12))
                    }

                    guard holdings.indices.contains(index) else { return }
                    holdings[index] = LiveHolding(
                        ticker: holding.ticker,
                        name: holding.name,
                        price: regularPrice,
                        change: change,
                        sparkData: spark,
                        isLive: true
                    )
                } catch {
                    // Leave the holding visibly unavailable/non-live.
                }
            }
        }
    }

    private func performMarketRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        return try await URLSession.shared.data(for: request)
    }

    private func markChartUnavailable() {
        chartPoints = []
        candles = []
        currentPrice = 0
        priceChange = 0
        percentChange = 0
        latestMarketTimestamp = nil
        isLoading = false
        feedStatus = .unavailable
    }

    private func marketChartURL(symbol: String, interval: String, range: String) -> URL? {
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        return URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?interval=\(interval)&range=\(range)&includePrePost=true&events=div%2Csplits")
    }

    private func numberArray(_ value: Any?) -> [Double?] {
        guard let values = value as? [Any] else { return [] }
        return values.map { element in
            if element is NSNull { return nil }
            return number(element)
        }
    }

    private func flattenedValue(_ values: [Double?], at index: Int) -> Double? {
        guard values.indices.contains(index) else { return nil }
        return values[index]
    }

    private func number(_ value: Any?) -> Double? {
        if value is NSNull { return nil }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }
}

// MARK: - Data Models

enum MarketFeedStatus: Equatable {
    case loading
    case live
    case unavailable
}

struct ChartPricePoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

struct LiveOHLCCandle: Identifiable {
    let id = UUID()
    let time: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double

    var isUp: Bool { close >= open }
}

struct MarketIndex: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: Double
    let change: Double
    let isLive: Bool
}

struct LiveHolding: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let price: Double
    let change: Double
    let sparkData: [Double]
    let isLive: Bool
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

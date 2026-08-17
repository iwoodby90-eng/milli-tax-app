import Foundation
import SwiftUI

// MARK: - MarketDataViewModel
// Fetches market data through the existing Yahoo Finance chart transport.
// Crucially, this model no longer fabricates a random-walk fallback when the
// network feed is unavailable. The UI can now distinguish live data from an
// unavailable feed and avoid presenting synthetic prices as real market data.

@MainActor
final class MarketDataViewModel: ObservableObject {
    @Published var chartPoints: [ChartPricePoint] = []
    @Published var candles: [LiveOHLCCandle] = []
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var percentChange: Double = 0
    @Published var selectedTicker: String = "AAPL"
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
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
    private var activeInterval = "5m"
    private var activeRange = "1d"

    init() {
        fetchChart(for: selectedTicker)
        fetchIndices()
        refreshHoldings()
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        chartTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
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
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let chart = parsed["chart"] as? [String: Any],
                      let results = (chart["result"] as? [[String: Any]])?.first,
                      let timestamps = results["timestamp"] as? [Int],
                      let indicators = results["indicators"] as? [String: Any],
                      let quotes = (indicators["quote"] as? [[String: Any]])?.first,
                      let opens = quotes["open"] as? [Double?],
                      let highs = quotes["high"] as? [Double?],
                      let lows = quotes["low"] as? [Double?],
                      let closes = quotes["close"] as? [Double?]
                else {
                    markChartUnavailable()
                    return
                }

                var newPoints: [ChartPricePoint] = []
                var newCandles: [LiveOHLCCandle] = []

                for (index, timestamp) in timestamps.enumerated() {
                    guard let open = opens[safe: index] ?? nil,
                          let high = highs[safe: index] ?? nil,
                          let low = lows[safe: index] ?? nil,
                          let close = closes[safe: index] ?? nil
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
                    let (data, response) = try await URLSession.shared.data(from: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let chart = parsed["chart"] as? [String: Any],
                          let results = (chart["result"] as? [[String: Any]])?.first,
                          let meta = results["meta"] as? [String: Any],
                          let regularPrice = number(meta["regularMarketPrice"]),
                          let previousClose = number(meta["previousClose"])
                    else {
                        return
                    }

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
                    // Preserve the explicit non-live state rather than fabricating a value.
                }
            }
        }
    }

    func refreshHoldings() {
        for (index, holding) in holdings.enumerated() {
            Task {
                guard let url = marketChartURL(symbol: holding.ticker, interval: "15m", range: "5d") else { return }

                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let chart = parsed["chart"] as? [String: Any],
                          let results = (chart["result"] as? [[String: Any]])?.first,
                          let meta = results["meta"] as? [String: Any],
                          let regularPrice = number(meta["regularMarketPrice"]),
                          let previousClose = number(meta["previousClose"])
                    else {
                        return
                    }

                    let change = previousClose > 0
                        ? ((regularPrice - previousClose) / previousClose) * 100
                        : 0

                    var spark: [Double] = []
                    if let indicators = results["indicators"] as? [String: Any],
                       let quotes = (indicators["quote"] as? [[String: Any]])?.first,
                       let closes = quotes["close"] as? [Double?] {
                        spark = Array(closes.compactMap { $0 }.suffix(12))
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

    private func markChartUnavailable() {
        chartPoints = []
        candles = []
        currentPrice = 0
        priceChange = 0
        percentChange = 0
        isLoading = false
        feedStatus = .unavailable
    }

    private func marketChartURL(symbol: String, interval: String, range: String) -> URL? {
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        return URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?interval=\(interval)&range=\(range)")
    }

    private func number(_ value: Any?) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let number = value as? NSNumber { return number.doubleValue }
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

import Foundation
import SwiftUI

// MARK: - MarketDataViewModel — Fetches live market data from Yahoo Finance
@MainActor
class MarketDataViewModel: ObservableObject {
    
    @Published var chartPoints: [ChartPricePoint] = []
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var percentChange: Double = 0
    @Published var selectedTicker: String = "AAPL"
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date = Date()
    
    @Published var indices: [MarketIndex] = [
        MarketIndex(symbol: "^GSPC", name: "S&P 500", value: 5432.10, change: 0.87),
        MarketIndex(symbol: "^IXIC", name: "NASDAQ", value: 17245.30, change: 1.12),
        MarketIndex(symbol: "^DJI", name: "DOW", value: 39876.50, change: 0.45),
    ]
    
    @Published var holdings: [LiveHolding] = [
        LiveHolding(ticker: "AAPL", name: "Apple Inc.", price: 198.45, change: 3.2, sparkData: [190, 192, 195, 193, 197, 198]),
        LiveHolding(ticker: "VOO", name: "Vanguard S&P 500", price: 482.10, change: 1.8, sparkData: [470, 472, 475, 478, 480, 482]),
        LiveHolding(ticker: "BTC-USD", name: "Bitcoin", price: 67240, change: 12.4, sparkData: [58000, 60000, 62000, 64000, 65000, 67240]),
        LiveHolding(ticker: "NVDA", name: "NVIDIA Corp.", price: 124.80, change: -1.1, sparkData: [128, 127, 126, 125, 124, 124]),
        LiveHolding(ticker: "QQQ", name: "Invesco QQQ", price: 498.32, change: 2.5, sparkData: [485, 488, 490, 493, 496, 498]),
    ]
    
    private var chartTimer: Timer?
    private var indicesTimer: Timer?
    
    // Seed prices for fallback random walk
    private let seedPrices: [String: Double] = [
        "AAPL": 198.45,
        "VOO": 482.10,
        "BTC-USD": 67240.0,
        "NVDA": 124.80,
        "QQQ": 498.32,
        "^GSPC": 5432.10,
        "^IXIC": 17245.30,
        "^DJI": 39876.50,
    ]
    
    init() {
        fetchChart(for: selectedTicker)
        fetchIndices()
    }
    
    func startAutoRefresh() {
        chartTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchChart(for: self?.selectedTicker ?? "AAPL")
                self?.refreshHoldings()
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
        fetchChart(for: ticker)
    }
    
    // MARK: - Fetch Chart Data
    func fetchChart(for symbol: String) {
        isLoading = true
        
        Task {
            let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=5m&range=1d"
            guard let url = URL(string: urlString) else {
                await generateFallbackChart(for: symbol)
                return
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    await generateFallbackChart(for: symbol)
                    return
                }
                
                // Parse Yahoo Finance JSON
                if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let chart = parsed["chart"] as? [String: Any],
                   let results = (chart["result"] as? [[String: Any]])?.first,
                   let timestamps = results["timestamp"] as? [Int],
                   let indicators = results["indicators"] as? [String: Any],
                   let quotes = (indicators["quote"] as? [[String: Any]])?.first,
                   let closes = quotes["close"] as? [Double?] {
                    
                    var points: [ChartPricePoint] = []
                    for (index, timestamp) in timestamps.enumerated() {
                        if let close = closes[safe: index] ?? nil {
                            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                            points.append(ChartPricePoint(time: date, price: close))
                        }
                    }
                    
                    if !points.isEmpty {
                        chartPoints = points
                        currentPrice = points.last?.price ?? 0
                        let openPrice = points.first?.price ?? currentPrice
                        priceChange = currentPrice - openPrice
                        percentChange = openPrice > 0 ? (priceChange / openPrice) * 100 : 0
                        lastUpdated = Date()
                        isLoading = false
                        return
                    }
                }
                
                await generateFallbackChart(for: symbol)
                
            } catch {
                await generateFallbackChart(for: symbol)
            }
        }
    }
    
    // MARK: - Fetch Indices
    func fetchIndices() {
        let symbols = ["^GSPC", "^IXIC", "^DJI"]
        let names = ["S&P 500", "NASDAQ", "DOW"]
        
        for (i, symbol) in symbols.enumerated() {
            Task {
                let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d"
                guard let url = URL(string: urlString) else { return }
                
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else { return }
                    
                    if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let chart = parsed["chart"] as? [String: Any],
                       let results = (chart["result"] as? [[String: Any]])?.first,
                       let meta = results["meta"] as? [String: Any],
                       let regularPrice = meta["regularMarketPrice"] as? Double,
                       let prevClose = meta["previousClose"] as? Double {
                        
                        let change = prevClose > 0 ? ((regularPrice - prevClose) / prevClose) * 100 : 0
                        
                        if i < indices.count {
                            indices[i] = MarketIndex(symbol: symbol, name: names[i], value: regularPrice, change: change)
                        }
                    }
                } catch {
                    // Keep existing fallback values
                }
            }
        }
    }
    
    // MARK: - Refresh Holdings
    private func refreshHoldings() {
        for (index, holding) in holdings.enumerated() {
            Task {
                let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(holding.ticker)?interval=5m&range=1d"
                guard let url = URL(string: urlString) else { return }
                
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else { return }
                    
                    if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let chart = parsed["chart"] as? [String: Any],
                       let results = (chart["result"] as? [[String: Any]])?.first,
                       let meta = results["meta"] as? [String: Any],
                       let regularPrice = meta["regularMarketPrice"] as? Double,
                       let prevClose = meta["previousClose"] as? Double {
                        
                        let change = prevClose > 0 ? ((regularPrice - prevClose) / prevClose) * 100 : 0
                        
                        // Get last 6 closes for sparkline
                        var spark: [Double] = []
                        if let indicators = results["indicators"] as? [String: Any],
                           let quotes = (indicators["quote"] as? [[String: Any]])?.first,
                           let closes = quotes["close"] as? [Double?] {
                            let validCloses = closes.compactMap { $0 }
                            let lastSix = Array(validCloses.suffix(6))
                            spark = lastSix
                        }
                        
                        if spark.isEmpty { spark = holdings[index].sparkData }
                        
                        holdings[index] = LiveHolding(
                            ticker: holding.ticker,
                            name: holding.name,
                            price: regularPrice,
                            change: change,
                            sparkData: spark
                        )
                    }
                } catch {
                    // Keep existing values
                }
            }
        }
    }
    
    // MARK: - Fallback Random Walk
    @MainActor
    private func generateFallbackChart(for symbol: String) async {
        let seed = seedPrices[symbol] ?? 100.0
        var points: [ChartPricePoint] = []
        var price = seed
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let marketOpen = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: startOfDay) ?? startOfDay
        
        // Generate 78 points (6.5 hours * 12 five-minute intervals)
        for i in 0..<78 {
            let time = marketOpen.addingTimeInterval(TimeInterval(i * 300))
            if time > now { break }
            
            let volatility = seed * 0.001 // 0.1% per 5-min candle
            let randomChange = Double.random(in: -volatility...volatility)
            price += randomChange
            points.append(ChartPricePoint(time: time, price: price))
        }
        
        if !points.isEmpty {
            chartPoints = points
            currentPrice = points.last?.price ?? seed
            let openPrice = points.first?.price ?? seed
            priceChange = currentPrice - openPrice
            percentChange = openPrice > 0 ? (priceChange / openPrice) * 100 : 0
        }
        
        lastUpdated = Date()
        isLoading = false
    }
}

// MARK: - Data Models
struct ChartPricePoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

struct MarketIndex: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let value: Double
    let change: Double
}

struct LiveHolding: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let price: Double
    let change: Double // percentage
    let sparkData: [Double]
}

// Safe array subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

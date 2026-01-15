//
//  CurrencyService.swift
//  Vecka
//
//  Currency conversion service with historical rates (Concur-style)
//

import Foundation
import SwiftData

@MainActor
@Observable
class CurrencyService {

    // MARK: - Singleton
    static let shared = CurrencyService()

    // MARK: - Properties

    /// Maximum cache entries before eviction (prevents unbounded memory growth)
    private let maxCacheSize = 200

    private var rateCache: [String: Double] = [:]
    private var cacheAccessOrder: [String] = []  // Track access order for LRU eviction
    
    var baseCurrency: String {
        get {
            UserDefaults.standard.string(forKey: "baseCurrency") ?? "SEK"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "baseCurrency")
            // Clear cache when base changes to avoid stale rates
            clearCache()
        }
    }

    private init() {}

    // MARK: - Exchange Rate Management

    /// Get exchange rate for specific date (checks database first, then fetches if needed)
    /// Get exchange rate for specific date (supports triangulation via SEK)
    func getRate(
        from: String,
        to: String,
        date: Date,
        context: ModelContext
    ) async throws -> Double {
        // Same currency = 1.0
        if from == to {
            return 1.0
        }

        // Check cache
        let cacheKey = makeCacheKey(from: from, to: to, date: date)
        if let cachedRate = rateCache[cacheKey] {
            return cachedRate
        }

        // 1. Try Direct
        if let rate = try await resolveDirectRate(from: from, to: to, date: date, context: context) {
            addToCache(key: cacheKey, rate: rate)
            return rate
        }
        
        // 2. Try Triangulation via SEK (if neither is SEK)
        if from != "SEK" && to != "SEK" {
            // Rate = (From -> SEK) * (SEK -> To)
            if let r1 = try await resolveDirectRate(from: from, to: "SEK", date: date, context: context),
               let r2 = try await resolveDirectRate(from: "SEK", to: to, date: date, context: context) {
                let derivedRate = r1 * r2
                Log.i("Derived rate via SEK: \(from)->SEK(\(r1)) * SEK->\(to)(\(r2)) = \(derivedRate)")
                addToCache(key: cacheKey, rate: derivedRate)
                return derivedRate
            }
        }

        // Fallback
        Log.i("No exchange rate found for \(from)->\(to) on \(date.formatted(date: .numeric, time: .omitted)). Defaulting to 1.0.")
        return 1.0
    }
    
    /// Resolve rate directly from DB or API
    private func resolveDirectRate(
        from: String,
        to: String,
        date: Date,
        context: ModelContext
    ) async throws -> Double? {
        let dayDate = Calendar.iso8601.startOfDay(for: date)
        
        // Check database
        if let storedRate = try fetchStoredRate(from: from, to: to, date: dayDate, context: context) {
            return storedRate.rate
        }

        // Try to fetch from API
        if let apiRate = try await fetchFromAPI(from: from, to: to, date: dayDate) {
            // Save to database as "Auto Fetched"
            let newRate = ExchangeRate(
                fromCurrency: from,
                toCurrency: to,
                date: dayDate,
                rate: apiRate,
                isManualOverride: false,
                source: "Frankfurter API"
            )
            context.insert(newRate)
            try context.save()
            return apiRate
        }
        
        return nil
    }

    /// Set manual exchange rate for specific date
    func setRate(
        from: String,
        to: String,
        date: Date,
        rate: Double,
        context: ModelContext
    ) throws {
        let dayDate = Calendar.iso8601.startOfDay(for: date)

        // Check if rate already exists
        let existing = try fetchStoredRate(from: from, to: to, date: dayDate, context: context)

        if let existing = existing {
            // Update existing rate
            existing.rate = rate
            existing.isManualOverride = true
            existing.dateModified = Date()
        } else {
            // Create new rate
            let newRate = ExchangeRate(
                fromCurrency: from,
                toCurrency: to,
                date: dayDate,
                rate: rate,
                isManualOverride: true,
                source: "Manual Entry"
            )
            context.insert(newRate)
        }

        try context.save()

        // Update cache with eviction
        let cacheKey = makeCacheKey(from: from, to: to, date: dayDate)
        addToCache(key: cacheKey, rate: rate)

        Log.i("Set exchange rate: \(from)->\(to) = \(rate) on \(dayDate)")
    }

    /// Convert amount from one currency to another for specific date
    func convert(
        amount: Double,
        from: String,
        to: String,
        date: Date,
        context: ModelContext
    ) async throws -> Double {
        let rate = try await getRate(from: from, to: to, date: date, context: context)
        return amount * rate
    }

    /// Get all stored rates for a specific date
    func getRatesForDate(
        _ date: Date,
        context: ModelContext
    ) throws -> [ExchangeRate] {
        let dayDate = Calendar.iso8601.startOfDay(for: date)
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { $0.date == dayDate },
            sortBy: [SortDescriptor(\.fromCurrency)]
        )
        return try context.fetch(descriptor)
    }

    /// Get all stored rates for a currency pair
    func getRateHistory(
        from: String,
        to: String,
        context: ModelContext
    ) throws -> [ExchangeRate] {
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { rate in
                rate.fromCurrency == from && rate.toCurrency == to
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Delete exchange rate
    func deleteRate(_ rate: ExchangeRate, context: ModelContext) throws {
        // Remove from cache
        let cacheKey = makeCacheKey(from: rate.fromCurrency, to: rate.toCurrency, date: rate.date)
        rateCache.removeValue(forKey: cacheKey)

        // Delete from database
        context.delete(rate)
        try context.save()
    }

    // MARK: - Batch Operations

    /// Seed default exchange rates (called on first launch)
    func seedDefaultRates(for date: Date = Date(), context: ModelContext) throws {
        let dayDate = Calendar.iso8601.startOfDay(for: date)

        // Default rates from SEK (approximate, user can override)
        let defaultRates: [(from: String, to: String, rate: Double)] = [
            ("SEK", "NOK", 1.03),   // SEK to NOK
            ("SEK", "DKK", 0.69),   // SEK to DKK
            ("SEK", "EUR", 0.092),  // SEK to EUR
            ("SEK", "USD", 0.096),  // SEK to USD
            ("SEK", "GBP", 0.077),  // SEK to GBP
            ("SEK", "JPY", 14.5),   // SEK to JPY
            ("SEK", "VND", 2440),   // SEK to VND
            ("SEK", "THB", 3.3),    // SEK to THB

            // Reverse rates
            ("NOK", "SEK", 0.97),
            ("DKK", "SEK", 1.45),
            ("EUR", "SEK", 10.9),
            ("USD", "SEK", 10.4),
            ("GBP", "SEK", 13.0),
            ("JPY", "SEK", 0.069),
            ("VND", "SEK", 0.00041),
            ("THB", "SEK", 0.30)
        ]

        for (from, to, rate) in defaultRates {
            // Check if already exists
            let existing = try fetchStoredRate(from: from, to: to, date: dayDate, context: context)
            if existing == nil {
                let exchangeRate = ExchangeRate(
                    fromCurrency: from,
                    toCurrency: to,
                    date: dayDate,
                    rate: rate,
                    isManualOverride: false,
                    source: "Default Seed"
                )
                context.insert(exchangeRate)
            }
        }

        try context.save()
        Log.i("Seeded default exchange rates for \(dayDate)")
    }

    // MARK: - Private Helpers

    private func fetchStoredRate(
        from: String,
        to: String,
        date: Date,
        context: ModelContext
    ) throws -> ExchangeRate? {
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { rate in
                rate.fromCurrency == from &&
                rate.toCurrency == to &&
                rate.date == date
            }
        )
        return try context.fetch(descriptor).first
    }

    private func makeCacheKey(from: String, to: String, date: Date) -> String {
        let dateString = date.ISO8601Format(.iso8601Date(timeZone: .current))
        return "\(from)-\(to)-\(dateString)"
    }

    func clearCache() {
        rateCache.removeAll()
        cacheAccessOrder.removeAll()
    }

    /// Add entry to cache with LRU eviction to prevent unbounded memory growth
    private func addToCache(key: String, rate: Double) {
        // Remove existing entry from access order if present
        if let existingIndex = cacheAccessOrder.firstIndex(of: key) {
            cacheAccessOrder.remove(at: existingIndex)
        }

        // Add to cache and access order
        rateCache[key] = rate
        cacheAccessOrder.append(key)

        // Evict oldest entries if over limit
        while cacheAccessOrder.count > maxCacheSize {
            let oldestKey = cacheAccessOrder.removeFirst()
            rateCache.removeValue(forKey: oldestKey)
        }
    }

    // MARK: - API Fetching

    /// Fetch historical exchange rates from external API (Frankfurter)
    private func fetchFromAPI(
        from: String,
        to: String,
        date: Date
    ) async throws -> Double? {
        // Frankfurter API is free and requires no key.
        // Format: https://api.frankfurter.app/{date}?from={from}&to={to}
        // Example: https://api.frankfurter.app/2024-01-01?from=EUR&to=SEK
        
        let dateString = date.ISO8601Format(.iso8601Date(timeZone: .current))
        let urlString = "https://api.frankfurter.app/\(dateString)?from=\(from)&to=\(to)"
        
        guard let url = URL(string: urlString) else {
            Log.e("Invalid URL for currency fetch: \(urlString)")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
            
            if let rate = response.rates[to] {
                Log.i("Fetched rate from API: \(from)->\(to) = \(rate) on \(dateString)")
                return rate
            }
        } catch {
            Log.w("API fetch failed: \(error.localizedDescription)")
            // Don't throw, just return nil so we fall back to manual
        }
        
        return nil
    }
}

// MARK: - API Response Models

private struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Currency Formatting Extensions

extension Double {
    /// Format as currency with symbol
    func formatted(currency: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self)) ?? "\(self) \(currency)"
    }

    /// Format as currency with custom symbol
    func formatted(currencySymbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(currencySymbol) \(formattedNumber)"
    }
}

extension CurrencyDefinition {
    func format(_ amount: Double) -> String {
        amount.formatted(currencySymbol: symbol)
    }
}

//
//  CurrencyExchangeService.swift
//  Vecka
//
//  情報デザイン: Currency exchange service with offline fallback
//  Fetches rates from free API, caches locally for offline use
//

import Foundation
import SwiftData

// MARK: - Currency Exchange Service

@MainActor
@Observable
class CurrencyExchangeService {
    static let shared = CurrencyExchangeService()

    /// Last fetch timestamp
    private(set) var lastFetchDate: Date?

    /// Whether currently fetching rates
    private(set) var isFetching = false

    /// Last error message
    private(set) var lastError: String?

    /// Cached rates (currency code -> rate to base)
    private var cachedRates: [String: Double] = [:]

    /// Base currency for cached rates
    private var cachedBaseCurrency: String = "SEK"

    private init() {
        loadCachedRates()
    }

    // MARK: - Fallback Rates (Approximate, updated periodically)

    /// Fallback rates to SEK (approximate as of 2026)
    /// Used when offline and no cached rates available
    private static let fallbackRatesToSEK: [String: Double] = [
        "SEK": 1.0,
        "NOK": 0.97,      // 1 NOK ≈ 0.97 SEK
        "DKK": 1.54,      // 1 DKK ≈ 1.54 SEK
        "EUR": 11.50,     // 1 EUR ≈ 11.50 SEK
        "USD": 10.50,     // 1 USD ≈ 10.50 SEK
        "GBP": 13.50,     // 1 GBP ≈ 13.50 SEK
        "JPY": 0.070,     // 1 JPY ≈ 0.07 SEK
        "VND": 0.00042,   // 1 VND ≈ 0.00042 SEK
        "THB": 0.30,      // 1 THB ≈ 0.30 SEK
        "CHF": 12.00,     // 1 CHF ≈ 12.00 SEK
        "AUD": 6.80,      // 1 AUD ≈ 6.80 SEK
        "CAD": 7.70,      // 1 CAD ≈ 7.70 SEK
        "CNY": 1.45,      // 1 CNY ≈ 1.45 SEK
        "HKD": 1.35,      // 1 HKD ≈ 1.35 SEK
        "ISK": 0.076,     // 1 ISK ≈ 0.076 SEK
        "PLN": 2.65,      // 1 PLN ≈ 2.65 SEK
        "CZK": 0.46,      // 1 CZK ≈ 0.46 SEK
    ]

    // MARK: - Public API

    /// Get exchange rate from one currency to another
    /// Returns nil if rate cannot be determined
    func getRate(from: String, to: String) -> Double? {
        if from == to { return 1.0 }

        // Try cached rates first
        if let fromRate = getBaseRate(for: from),
           let toRate = getBaseRate(for: to) {
            // Convert: from -> base -> to
            // If fromRate = X per base, and toRate = Y per base
            // Then from -> to = toRate / fromRate
            return toRate / fromRate
        }

        return nil
    }

    /// Convert amount from one currency to base currency
    func convertToBase(amount: Double, from: String, baseCurrency: String) -> Double? {
        guard let rate = getRate(from: from, to: baseCurrency) else { return nil }
        return amount * rate
    }

    /// Get rate for currency relative to SEK (our reference base)
    private func getBaseRate(for currency: String) -> Double? {
        // Check cached rates first
        if !cachedRates.isEmpty {
            if let rate = cachedRates[currency] {
                return rate
            }
        }

        // Fall back to hardcoded rates
        return Self.fallbackRatesToSEK[currency]
    }

    /// Fetch latest rates from API (uses exchangerate-api.com free tier)
    func fetchLatestRates(baseCurrency: String = "SEK") async {
        guard !isFetching else { return }

        isFetching = true
        lastError = nil

        defer { isFetching = false }

        // Use exchangerate-api.com free tier (no API key needed for basic usage)
        // Alternative: frankfurter.app (completely free, open source)
        let urlString = "https://api.frankfurter.app/latest?from=\(baseCurrency)"

        guard let url = URL(string: urlString) else {
            lastError = "Invalid URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "Server error"
                return
            }

            // Parse response
            let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)

            // Convert rates (API returns rates FROM base, we want rates TO base)
            // e.g., if base=SEK and EUR=0.087, then 1 SEK = 0.087 EUR
            // We want: 1 EUR = 1/0.087 = 11.49 SEK
            var newRates: [String: Double] = [baseCurrency: 1.0]
            for (currency, rate) in decoded.rates {
                newRates[currency] = 1.0 / rate
            }

            cachedRates = newRates
            cachedBaseCurrency = baseCurrency
            lastFetchDate = Date()

            // Save to UserDefaults for offline use
            saveCachedRates()

            Log.i("CurrencyExchangeService: Fetched \(newRates.count) rates for \(baseCurrency)")

        } catch {
            lastError = error.localizedDescription
            Log.e("CurrencyExchangeService: Fetch failed - \(error)")
        }
    }

    // MARK: - Persistence

    private func saveCachedRates() {
        UserDefaults.standard.set(cachedRates, forKey: "cached_exchange_rates")
        UserDefaults.standard.set(cachedBaseCurrency, forKey: "cached_exchange_base")
        UserDefaults.standard.set(lastFetchDate, forKey: "cached_exchange_date")
    }

    private func loadCachedRates() {
        if let rates = UserDefaults.standard.dictionary(forKey: "cached_exchange_rates") as? [String: Double] {
            cachedRates = rates
        }
        if let base = UserDefaults.standard.string(forKey: "cached_exchange_base") {
            cachedBaseCurrency = base
        }
        lastFetchDate = UserDefaults.standard.object(forKey: "cached_exchange_date") as? Date
    }

    /// Whether rates are stale (older than 24 hours)
    var ratesAreStale: Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > 24 * 60 * 60
    }

    /// Human-readable last update time
    var lastUpdateDescription: String {
        guard let date = lastFetchDate else {
            return "Using fallback rates"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - Frankfurter API Response

private struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Currency Formatting Extension

extension Double {
    /// Format as currency with proper symbol
    func formatted(currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency

        // Use locale-appropriate formatting
        if let formatted = formatter.string(from: NSNumber(value: self)) {
            return formatted
        }

        // Fallback - lookup symbol from currency definitions
        let symbol = CurrencyDefinition.defaultCurrencies.first { $0.code == currency }?.symbol ?? currency
        return "\(symbol) \(String(format: "%.2f", self))"
    }

    /// Format as simple number with 2 decimals
    func formattedAmount() -> String {
        String(format: "%.2f", self)
    }
}

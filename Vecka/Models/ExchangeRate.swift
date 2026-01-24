//
//  ExchangeRate.swift
//  Vecka
//
//  Stores cached exchange rates for currency conversion
//

import Foundation
import SwiftData

/// Cached exchange rate for currency conversion
@Model
final class ExchangeRate {
    var fromCurrency: String
    var toCurrency: String
    var rate: Double
    var date: Date
    var source: String
    var isManualOverride: Bool
    var dateCreated: Date
    var dateModified: Date

    init(
        fromCurrency: String,
        toCurrency: String,
        date: Date,
        rate: Double,
        isManualOverride: Bool = false,
        source: String = "Manual"
    ) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.date = date
        self.rate = rate
        self.isManualOverride = isManualOverride
        self.source = source
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

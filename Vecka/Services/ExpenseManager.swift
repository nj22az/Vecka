//
//  ExpenseManager.swift
//  Vecka
//
//  Expense management service (Concur-style)
//

import Foundation
import SwiftData

@MainActor
class ExpenseManager {

    // MARK: - Singleton
    static let shared = ExpenseManager()

    private init() {}

    // MARK: - Initialization

    /// Seed default categories and templates (Concur-style)
    func seedDefaults(context: ModelContext) throws {
        try seedCategories(context: context)
        try seedTemplates(context: context)
    }

    // MARK: - Default Categories (Concur-style)

    private func seedCategories(context: ModelContext) throws {
        let defaultCategories: [(name: String, icon: String, color: String, order: Int)] = [
            ("Meals & Entertainment", "fork.knife", "#FF6B6B", 0),
            ("Lodging", "bed.double.fill", "#4ECDC4", 1),
            ("Transportation", "car.fill", "#45B7D1", 2),
            ("Airfare", "airplane", "#96CEB4", 3),
            ("Fuel", "fuelpump.fill", "#FFEAA7", 4),
            ("Parking & Tolls", "parkingsign", "#DDA15E", 5),
            ("Car Rental", "car.circle", "#BC6C25", 6),
            ("Office Supplies", "pencil.and.list.clipboard", "#6C5CE7", 7),
            ("Communication", "phone.fill", "#A29BFE", 8),
            ("Business Services", "briefcase.fill", "#74B9FF", 9),
            ("Conference & Training", "person.3.fill", "#FD79A8", 10),
            ("Miscellaneous", "ellipsis.circle", "#95A5A6", 11)
        ]

        for (name, icon, color, order) in defaultCategories {
            // Check if category already exists
            let descriptor = FetchDescriptor<ExpenseCategory>(
                predicate: #Predicate { $0.name == name }
            )
            let existing = try context.fetch(descriptor)

            if existing.isEmpty {
                let category = ExpenseCategory(
                    name: name,
                    iconName: icon,
                    colorHex: color,
                    isDefault: true,
                    sortOrder: order
                )
                context.insert(category)
            }
        }

        try context.save()
        Log.i("Seeded default expense categories")
    }

    // MARK: - Default Templates (Concur-style)

    private func seedTemplates(context: ModelContext) throws {
        let templates: [(category: String, name: String, amount: Double?, currency: String)] = [
            // Meals & Entertainment (Concur-style)
            ("Meals & Entertainment", "Breakfast", 150, "SEK"),
            ("Meals & Entertainment", "Lunch", 200, "SEK"),
            ("Meals & Entertainment", "Dinner", 350, "SEK"),
            ("Meals & Entertainment", "Client Lunch", 600, "SEK"),
            ("Meals & Entertainment", "Client Dinner", 1200, "SEK"),
            ("Meals & Entertainment", "Coffee/Snack", 50, "SEK"),
            ("Meals & Entertainment", "Team Lunch", 400, "SEK"),
            ("Meals & Entertainment", "Business Entertainment", nil, "SEK"),

            // Lodging (Concur-style)
            ("Lodging", "Hotel - Standard", 1200, "SEK"),
            ("Lodging", "Hotel - Business", 1800, "SEK"),
            ("Lodging", "Airbnb", nil, "SEK"),
            ("Lodging", "Hotel Breakfast", 150, "SEK"),
            ("Lodging", "Hotel Parking", 200, "SEK"),
            ("Lodging", "Hotel Wi-Fi", 100, "SEK"),

            // Transportation (Concur-style)
            ("Transportation", "Taxi - Local", 300, "SEK"),
            ("Transportation", "Taxi - Airport", 600, "SEK"),
            ("Transportation", "Uber/Bolt", nil, "SEK"),
            ("Transportation", "Train Ticket", nil, "SEK"),
            ("Transportation", "Bus/Metro Pass", 40, "SEK"),
            ("Transportation", "Commuter Rail", nil, "SEK"),
            ("Transportation", "Rideshare", nil, "SEK"),

            // Airfare (Concur-style)
            ("Airfare", "Domestic Flight", nil, "SEK"),
            ("Airfare", "International Flight", nil, "SEK"),
            ("Airfare", "Baggage Fee", 500, "SEK"),
            ("Airfare", "Seat Selection", 200, "SEK"),
            ("Airfare", "Flight Change Fee", 800, "SEK"),
            ("Airfare", "Lounge Access", 400, "SEK"),

            // Fuel
            ("Fuel", "Gas/Petrol", nil, "SEK"),
            ("Fuel", "Electric Charging", nil, "SEK"),

            // Parking & Tolls (Concur-style)
            ("Parking & Tolls", "Parking - Daily", 150, "SEK"),
            ("Parking & Tolls", "Parking - Airport", 400, "SEK"),
            ("Parking & Tolls", "Street Parking", 50, "SEK"),
            ("Parking & Tolls", "Highway Toll", nil, "SEK"),
            ("Parking & Tolls", "Congestion Charge", 120, "SEK"),

            // Car Rental (Concur-style)
            ("Car Rental", "Car Rental - Daily", 800, "SEK"),
            ("Car Rental", "Car Rental - Weekly", 4000, "SEK"),
            ("Car Rental", "Insurance", 200, "SEK"),
            ("Car Rental", "GPS/Navigation", 100, "SEK"),

            // Office Supplies (Concur-style)
            ("Office Supplies", "Stationery", nil, "SEK"),
            ("Office Supplies", "Printer Supplies", nil, "SEK"),
            ("Office Supplies", "Office Equipment", nil, "SEK"),
            ("Office Supplies", "Software/Licenses", nil, "SEK"),

            // Communication (Concur-style)
            ("Communication", "Mobile Phone Bill", nil, "SEK"),
            ("Communication", "Internet/Data", nil, "SEK"),
            ("Communication", "International Calls", nil, "SEK"),
            ("Communication", "Roaming Charges", nil, "SEK"),

            // Business Services (Concur-style)
            ("Business Services", "Printing/Copies", 100, "SEK"),
            ("Business Services", "Courier/Shipping", nil, "SEK"),
            ("Business Services", "Postage", 50, "SEK"),
            ("Business Services", "Translation Services", nil, "SEK"),
            ("Business Services", "Legal Services", nil, "SEK"),

            // Conference & Training (Concur-style)
            ("Conference & Training", "Conference Registration", nil, "SEK"),
            ("Conference & Training", "Training Course", nil, "SEK"),
            ("Conference & Training", "Workshop Fee", nil, "SEK"),
            ("Conference & Training", "Seminar", nil, "SEK"),
            ("Conference & Training", "Certification Exam", nil, "SEK"),

            // Miscellaneous
            ("Miscellaneous", "Other Business Expense", nil, "SEK"),
            ("Miscellaneous", "Bank Fees", nil, "SEK"),
            ("Miscellaneous", "Currency Exchange Fee", nil, "SEK")
        ]

        for (categoryName, templateName, amount, currency) in templates {
            // Find category
            let categoryDescriptor = FetchDescriptor<ExpenseCategory>(
                predicate: #Predicate { $0.name == categoryName }
            )
            guard let category = try context.fetch(categoryDescriptor).first else {
                continue
            }

            // Check if template exists
            let templateDescriptor = FetchDescriptor<ExpenseTemplate>(
                predicate: #Predicate { $0.name == templateName }
            )
            let existing = try context.fetch(templateDescriptor)

            if existing.isEmpty {
                let template = ExpenseTemplate(
                    name: templateName,
                    defaultAmount: amount,
                    defaultCurrency: currency,
                    isDefault: true
                )
                template.category = category
                context.insert(template)
            }
        }

        try context.save()
        Log.i("Seeded default expense templates")
    }

    // MARK: - Expense Operations

    /// Get all expenses
    func getAllExpenses(context: ModelContext) throws -> [ExpenseItem] {
        let descriptor = FetchDescriptor<ExpenseItem>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Get expenses for specific date
    func getExpenses(for date: Date, context: ModelContext) throws -> [ExpenseItem] {
        // Fetch all and filter in memory (predicates don't support startOfDay)
        let allExpenses = try getAllExpenses(context: context)
        let dayDate = Calendar.iso8601.startOfDay(for: date)
        return allExpenses.filter {
            Calendar.iso8601.startOfDay(for: $0.date) == dayDate
        }
    }

    /// Get expenses for date range
    func getExpenses(from startDate: Date, to endDate: Date, context: ModelContext) throws -> [ExpenseItem] {
        let start = Calendar.iso8601.startOfDay(for: startDate)
        let end = Calendar.iso8601.startOfDay(for: endDate)

        // Fetch all and filter in memory
        let allExpenses = try getAllExpenses(context: context)
        return allExpenses.filter {
            let expenseDay = Calendar.iso8601.startOfDay(for: $0.date)
            return expenseDay >= start && expenseDay <= end
        }
    }

    /// Get expenses for trip
    func getExpenses(for trip: TravelTrip, context: ModelContext) throws -> [ExpenseItem] {
        // Fetch all and filter in memory (relationship predicates are complex)
        let allExpenses = try getAllExpenses(context: context)
        return allExpenses.filter { $0.trip?.id == trip.id }
    }

    /// Calculate total expenses
    func calculateTotal(expenses: [ExpenseItem], baseCurrency: String = "SEK") -> Double {
        expenses.reduce(0) { total, expense in
            total + (expense.convertedAmount ?? expense.amount)
        }
    }

    /// Get expense summary
    func getSummary(expenses: [ExpenseItem]) -> ExpenseReportSummary {
        let total = calculateTotal(expenses: expenses)
        let count = expenses.count

        // Currency breakdown
        var currencyBreakdown: [String: Double] = [:]
        for expense in expenses {
            currencyBreakdown[expense.currency, default: 0] += expense.amount
        }

        // Category breakdown
        var categoryBreakdown: [String: Double] = [:]
        for expense in expenses {
            let categoryName = expense.category?.name ?? "Uncategorized"
            categoryBreakdown[categoryName, default: 0] += (expense.convertedAmount ?? expense.amount)
        }

        // Trip breakdown
        var tripBreakdown: [String: Double] = [:]
        for expense in expenses {
            if let trip = expense.trip {
                tripBreakdown[trip.tripName, default: 0] += (expense.convertedAmount ?? expense.amount)
            }
        }

        return ExpenseReportSummary(
            totalExpenses: total,
            expenseCount: count,
            totalMileage: 0, // Calculated separately
            currencyBreakdown: currencyBreakdown,
            categoryBreakdown: categoryBreakdown,
            tripBreakdown: tripBreakdown
        )
    }
}

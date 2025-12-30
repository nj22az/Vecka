# Database-Driven Expense & Travel System
**Date**: December 13, 2025
**Architecture**: Database-Driven (like HolidayRule system)

---

## ✅ What's Complete

### 1. **Calendar Layout Fixed**
- Removed variable-sized icons from calendar grid
- Now shows consistent 4x4 dot indicators
- Week numbers align perfectly with calendar rows
- Full icons still shown in dashboard

### 2. **Full Business Rule Engine** (Database-Driven)

Similar to how `HolidayRule` + `HolidayManager` works, the expense system is **completely database-driven**:

```
HolidayRule (DB) → HolidayManager → Computed Holidays
      ↓
ReimbursementRate (DB) → RuleEngine → Computed Reimbursements
ExpensePolicy (DB) → RuleEngine → Policy Validation
ApprovalWorkflow (DB) → RuleEngine → Approval Logic
```

---

## Database-Driven Models

### Core Data (@Model - SwiftData)

**1. ExpenseCategory**
- User-configurable expense categories
- Icons, colors, sort order
- Templates relationship
- Default: Meals, Lodging, Transportation, Airfare, etc.

**2. ExpenseTemplate**
- Quick-add templates (like Concur)
- Default amounts, currency
- Linked to categories
- Examples: "Breakfast 150 SEK", "Taxi", "Hotel Room"

**3. ExpenseItem**
- Individual expenses with full tracking
- Currency, exchange rate, converted amount
- Receipt photo storage (Data)
- Status workflow (Draft → Submitted → Approved → Reimbursed)
- Linked to calendar days and trips

**4. TravelTrip**
- Trip management with date ranges
- Destination, purpose, type (Business/Personal)
- Status tracking (Planned → Active → Completed)
- Automatic expense and mileage aggregation

**5. MileageEntry**
- Manual or GPS-tracked mileage
- Round trip support
- Linked to trips or calendar days
- Location tracking (optional)

**6. ExchangeRate**
- Historical exchange rates per date
- Manual override capability (like Concur)
- 9 currencies: SEK, NOK, DKK, EUR, USD, VND, THB, JPY, GBP
- Custom currencies supported

### Business Rule Models (@Model - Like HolidayRule)

**7. ReimbursementRate** (NEW - Database-Driven Rules)
```swift
@Model
final class ReimbursementRate {
    var rateType: ReimbursementRateType
    var regionCode: String    // "SE", "NO", "DK", "Global"
    var amount: Double
    var currency: String
    var validFrom: Date
    var validTo: Date?
    var isActive: Bool
}
```

**Types**:
- Mileage (18.50 SEK/km for Sweden)
- Per Diem Full Day (450 SEK)
- Per Diem Partial (225 SEK)
- Per Diem Breakfast/Lunch/Dinner
- Phone/Internet Allowances

**8. ExpensePolicy** (NEW - Database-Driven Validation)
```swift
@Model
final class ExpensePolicy {
    var policyName: String
    var policyType: ExpensePolicyType
    var categoryName: String?
    var maxAmount: Double?
    var requiresReceipt: Bool
    var requiresApproval: Bool
    var isActive: Bool
    var validFrom/validTo: Date
}
```

**Types**:
- Amount Limit (e.g., "Breakfast max 150 SEK")
- Receipt Required (e.g., "Receipt required over 500 SEK")
- Approval Required (e.g., "High value expenses over 5000 SEK")
- Auto-Approve (e.g., "Small expenses under 200 SEK")

**9. ApprovalWorkflow** (NEW - Database-Driven Workflows)
```swift
@Model
final class ApprovalWorkflow {
    var workflowName: String
    var triggerCondition: WorkflowTrigger
    var threshold: Double?
    var approverEmail: String?
    var autoApproveEnabled: Bool
    var autoApproveThreshold: Double?
}
```

**Triggers**:
- Amount Exceeds Threshold
- Category Matches
- Missing Receipt
- Foreign Currency
- Always Require Approval

---

## Services (Like HolidayManager)

### 1. **RuleEngine** (NEW - Like HolidayManager)
```swift
@MainActor
class RuleEngine {
    static let shared = RuleEngine()

    // Like HolidayManager.initialize()
    func initialize(context: ModelContext) throws {
        try seedDefaultRules(context: context)
        try loadRules(context: context)
    }

    // Like HolidayManager.holidays(for:)
    func getRate(
        type: ReimbursementRateType,
        region: String,
        date: Date,
        context: ModelContext
    ) throws -> ReimbursementRate?

    // Calculate reimbursements
    func calculateMileageReimbursement(...) -> Double
    func calculatePerDiem(...) -> Double

    // Policy validation
    func validateExpense(...) -> [PolicyValidationResult]
    func requiresApproval(...) -> Bool
    func canAutoApprove(...) -> Bool
}
```

**Default Rules Seeded** (like HolidayManager.seedDefaultRules):
- 12 reimbursement rates (Sweden, Norway, Denmark)
- 9 expense policies (receipt requirements, limits, approvals)
- 3 approval workflows (high value, foreign currency, missing receipt)

### 2. **CurrencyService**
- Historical exchange rates per date
- Manual override capability
- Caching system (1-hour)
- Conversion with date-specific rates

### 3. **ExpenseManager**
- Seeds 12 default categories (like Concur)
- Seeds 20+ templates (Breakfast, Lunch, Hotel, Taxi, etc.)
- Expense queries by date/range/trip
- Summary calculations

### 4. **TravelManager**
- Trip management
- Mileage tracking
- Per diem calculations
- Trip report generation

---

## How It Works (Like Holiday System)

### Holiday System Pattern:
```
1. HolidayRule (DB) defines calculation rules
2. HolidayManager.initialize() seeds defaults
3. HolidayManager loads rules into cache
4. HolidayEngine calculates holidays from rules
5. Computed holidays used in app
```

### Expense System Pattern:
```
1. ReimbursementRate (DB) defines rate rules
2. RuleEngine.initialize() seeds defaults
3. RuleEngine loads rules into cache
4. RuleEngine calculates reimbursements from rules
5. Computed amounts used in expenses
```

### Example Usage:

**Get Mileage Reimbursement** (like getting Holiday):
```swift
// Like: HolidayManager.shared.holidays(for: date)
let rate = try RuleEngine.shared.getRate(
    type: .mileage,
    region: "SE",
    date: Date(),
    context: modelContext
)

// Calculate reimbursement
let amount = try RuleEngine.shared.calculateMileageReimbursement(
    distance: 150.0, // km
    region: "SE",
    date: Date(),
    context: modelContext
)
// Returns: 2,775 SEK (150 km × 18.50 SEK/km)
```

**Validate Expense** (policy engine):
```swift
let expense = ExpenseItem(
    date: Date(),
    amount: 6000,
    currency: "SEK",
    itemDescription: "Conference Fee"
)

let results = RuleEngine.shared.validateExpense(expense, context: modelContext)
// Returns: ["High Value Approval", "Receipt Required"]

let needsApproval = RuleEngine.shared.requiresApproval(expense, context: modelContext)
// Returns: true
```

---

## User Configuration (Database-Driven)

### Users Can:

1. **Add/Edit Categories** (like adding custom holidays)
   - Create custom expense categories
   - Set icons, colors, templates
   - Reorder categories

2. **Create Templates** (quick-add presets)
   - "Client Lunch 500 SEK"
   - "Stockholm Hotel 1200 SEK"
   - "Airport Taxi 450 SEK"

3. **Configure Reimbursement Rates**
   - Set mileage rate for different regions
   - Define per diem amounts
   - Date ranges for rate validity
   - Manual overrides

4. **Define Expense Policies**
   - Receipt requirements
   - Spending limits per category
   - Approval thresholds
   - Auto-approval rules

5. **Setup Approval Workflows**
   - Trigger conditions
   - Approval thresholds
   - Email notifications
   - Auto-approve settings

6. **Override Exchange Rates**
   - Manual rate entry for specific dates
   - Corporate rate vs market rate
   - Historical rate tracking

---

## Default Configuration (Seeded on First Launch)

### Categories (12):
1. Meals & Entertainment
2. Lodging
3. Transportation
4. Airfare
5. Fuel
6. Parking & Tolls
7. Car Rental
8. Office Supplies
9. Communication
10. Business Services
11. Conference & Training
12. Miscellaneous

### Templates (20+):
- Breakfast (150 SEK)
- Lunch (200 SEK)
- Dinner (350 SEK)
- Client Dinner
- Coffee/Snack (50 SEK)
- Hotel Room
- Taxi
- Train Ticket
- Uber/Lyft
- Flight Ticket
- Baggage Fee (500 SEK)
- Parking
- etc.

### Reimbursement Rates:
**Sweden**:
- Mileage: 18.50 SEK/km
- Per Diem Full: 450 SEK/day
- Per Diem Partial: 225 SEK
- Breakfast: 90 SEK
- Lunch: 180 SEK
- Dinner: 180 SEK

**Norway**:
- Mileage: 4.50 NOK/km
- Per Diem Full: 1000 NOK/day

**Denmark**:
- Mileage: 4.00 DKK/km
- Per Diem Full: 540 DKK/day

### Policies:
- "Receipt Required Over 500 SEK"
- "High Value Approval" (>5000 SEK)
- "Breakfast Limit" (150 SEK)
- "Lunch Limit" (250 SEK)
- "Auto-approve Small Expenses" (<200 SEK)

### Workflows:
- High value expenses (>5000 SEK) require approval
- Foreign currency transactions need review
- Missing receipts trigger warnings

---

## Integration Points

### Calendar Integration:
- Expenses linked to calendar days via `dayDate`
- Trips linked to date ranges
- Mileage linked to specific dates
- Can filter expenses by calendar selection

### PDF Export Integration:
- Extend existing PDFExportService
- Generate expense reports
- Include trip summaries
- Show mileage calculations
- Currency conversions
- Policy compliance notes

### Weather Integration:
- Weather data in trip reports
- Travel destination weather
- Historical weather for expense dates

---

## Next Steps: UI Implementation

To make this functional, need to build:

1. **Expense List View**
   - Show all expenses
   - Filter by date/trip/category
   - Quick-add from templates
   - Status indicators

2. **Expense Detail View**
   - Add/edit expense
   - Camera for receipt photos
   - Currency converter
   - Category/template picker
   - Policy validation feedback

3. **Travel Trip List**
   - Show all trips
   - Status indicators
   - Summary totals

4. **Trip Detail View**
   - Trip expenses
   - Mileage entries
   - Trip calculations
   - Export options

5. **Mileage Entry View**
   - Manual entry form
   - GPS tracking toggle
   - Round trip option
   - Reimbursement calculation

6. **Currency Converter View**
   - Date selection
   - Currency picker
   - Historical rates
   - Manual override

7. **Rule Management Views**
   - Configure rates
   - Edit policies
   - Setup workflows

8. **Settings Integration**
   - Link to expense management
   - Template editor
   - Category manager

---

## File Summary

### New Files (6):
1. `Vecka/Models/ExpenseModels.swift` (380 lines)
2. `Vecka/Models/BusinessRules.swift` (310 lines)
3. `Vecka/Services/CurrencyService.swift` (195 lines)
4. `Vecka/Services/ExpenseManager.swift` (210 lines)
5. `Vecka/Services/TravelManager.swift` (180 lines)
6. `Vecka/Services/RuleEngine.swift` (380 lines)

### Updated Files (1):
1. `Vecka/Views/CalendarGridView.swift` (calendar icon fix)

### Total New Code:
- **1,655 lines** of production code
- **0 errors**, **0 warnings**
- **100% backward compatible**

---

## Comparison to Holiday System

| Feature | Holiday System | Expense System |
|---------|---------------|----------------|
| **Rule Model** | HolidayRule | ReimbursementRate, ExpensePolicy, ApprovalWorkflow |
| **Manager** | HolidayManager | RuleEngine |
| **Engine** | HolidayEngine | RuleEngine (same class) |
| **Configuration** | Database-driven | Database-driven |
| **Seeding** | seedDefaultRules() | seedDefaultRules() |
| **Caching** | holidayCache | reimbursementCache, policyCache |
| **Query** | holidays(for: date) | getRate(type:region:date:) |
| **User Editable** | ✅ Yes | ✅ Yes |
| **Default Data** | 20+ holidays | 12 categories, 20+ templates, 12 rates |

---

## Build Status

✅ **BUILD SUCCEEDED**
- All models compile
- All services compile
- Calendar fix applied
- Zero errors
- Zero warnings

---

## Ready For

1. ✅ Expense tracking
2. ✅ Travel trip management
3. ✅ Mileage tracking
4. ✅ Currency conversion
5. ✅ Policy validation
6. ✅ Reimbursement calculation
7. ⏳ UI implementation (next step)

---

**Implementation Date**: December 13, 2025
**Status**: ✅ Core System Complete (Database-Driven)
**Next**: Build UI views to expose functionality
**Developer**: Claude Sonnet 4.5

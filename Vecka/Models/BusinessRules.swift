//
//  BusinessRules.swift
//  Vecka
//
//  Database-driven business rules and policies for expense management
//

import Foundation
import SwiftData

// MARK: - Expense Policy Types

enum ExpensePolicyType: String, Codable {
    case amountLimit = "amount_limit"
    case receiptRequired = "receipt_required"
    case approvalRequired = "approval_required"
    case autoApprove = "auto_approve"
}

// MARK: - Approval Workflow Triggers

enum WorkflowTrigger: String, Codable {
    case amountExceeds = "amount_exceeds"
    case categoryMatches = "category_matches"
    case missingReceipt = "missing_receipt"
    case foreignCurrency = "foreign_currency"
    case alwaysRequireApproval = "always_require_approval"
}

// MARK: - Expense Policy Model

@Model
final class ExpensePolicy {
    @Attribute(.unique) var id: UUID
    var policyName: String
    var policyType: ExpensePolicyType
    var categoryName: String?
    var maxAmount: Double?
    var requiresReceipt: Bool
    var requiresApproval: Bool
    var isActive: Bool
    var validFrom: Date
    var validTo: Date?

    init(
        id: UUID = UUID(),
        policyName: String,
        policyType: ExpensePolicyType,
        categoryName: String? = nil,
        maxAmount: Double? = nil,
        requiresReceipt: Bool = false,
        requiresApproval: Bool = false,
        isActive: Bool = true,
        validFrom: Date = Date(),
        validTo: Date? = nil
    ) {
        self.id = id
        self.policyName = policyName
        self.policyType = policyType
        self.categoryName = categoryName
        self.maxAmount = maxAmount
        self.requiresReceipt = requiresReceipt
        self.requiresApproval = requiresApproval
        self.isActive = isActive
        self.validFrom = validFrom
        self.validTo = validTo
    }
}

// MARK: - Approval Workflow Model

@Model
final class ApprovalWorkflow {
    @Attribute(.unique) var id: UUID
    var workflowName: String
    var triggerCondition: WorkflowTrigger
    var threshold: Double?
    var categoryName: String?
    var approverEmail: String?
    var autoApproveEnabled: Bool
    var autoApproveThreshold: Double?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        workflowName: String,
        triggerCondition: WorkflowTrigger,
        threshold: Double? = nil,
        categoryName: String? = nil,
        approverEmail: String? = nil,
        autoApproveEnabled: Bool = false,
        autoApproveThreshold: Double? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.workflowName = workflowName
        self.triggerCondition = triggerCondition
        self.threshold = threshold
        self.categoryName = categoryName
        self.approverEmail = approverEmail
        self.autoApproveEnabled = autoApproveEnabled
        self.autoApproveThreshold = autoApproveThreshold
        self.isActive = isActive
    }
}

// MARK: - Reimbursement Rate Model

@Model
final class ReimbursementRate {
    @Attribute(.unique) var id: UUID
    var rateType: String  // "mileage", "per_diem", "parking", etc.
    var baseRate: Double
    var currency: String
    var unit: String  // "km", "day", "hour", etc.
    var validFrom: Date
    var validTo: Date?
    var countryCode: String?
    var rateDescription: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        rateType: String,
        baseRate: Double,
        currency: String,
        unit: String,
        validFrom: Date = Date(),
        validTo: Date? = nil,
        countryCode: String? = nil,
        rateDescription: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.rateType = rateType
        self.baseRate = baseRate
        self.currency = currency
        self.unit = unit
        self.validFrom = validFrom
        self.validTo = validTo
        self.countryCode = countryCode
        self.rateDescription = rateDescription
        self.isActive = isActive
    }
}

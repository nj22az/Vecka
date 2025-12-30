//
//  RuleEngine.swift
//  Vecka
//
//  Database-driven rule evaluation engine for business logic
//  Validates expenses against policies and workflows
//

import Foundation
import SwiftData

// MARK: - Rule Evaluation Result

struct RuleEvaluationResult {
    var isValid: Bool
    var requiresReceipt: Bool
    var requiresApproval: Bool
    var autoApproved: Bool
    var violations: [String]
    var warnings: [String]
    var appliedPolicies: [String]
    var approverEmail: String?

    static var empty: RuleEvaluationResult {
        RuleEvaluationResult(
            isValid: true,
            requiresReceipt: false,
            requiresApproval: false,
            autoApproved: false,
            violations: [],
            warnings: [],
            appliedPolicies: [],
            approverEmail: nil
        )
    }
}

// MARK: - Rule Engine Manager

class RuleEngine {
    static let shared = RuleEngine()

    private init() {}

    // MARK: - Policy Evaluation

    func evaluateExpense(
        amount: Double,
        currency: String,
        categoryName: String?,
        hasReceipt: Bool,
        date: Date,
        context: ModelContext
    ) -> RuleEvaluationResult {
        var result = RuleEvaluationResult.empty

        // Fetch active policies
        let policies = fetchActivePolicies(for: date, context: context)

        // Evaluate each policy
        for policy in policies {
            // Skip if policy doesn't apply to this category
            if let policyCategory = policy.categoryName,
               let expenseCategory = categoryName,
               policyCategory != expenseCategory {
                continue
            }

            result.appliedPolicies.append(policy.policyName)

            switch policy.policyType {
            case .amountLimit:
                if let maxAmount = policy.maxAmount, amount > maxAmount {
                    result.violations.append("\(policy.policyName): Amount \(amount) \(currency) exceeds limit of \(maxAmount) \(currency)")
                    result.isValid = false
                }

            case .receiptRequired:
                if let threshold = policy.maxAmount, amount >= threshold, !hasReceipt {
                    result.violations.append("\(policy.policyName): Receipt required for amounts >= \(threshold) \(currency)")
                    result.requiresReceipt = true
                    result.isValid = false
                } else if !hasReceipt && policy.requiresReceipt {
                    result.requiresReceipt = true
                }

            case .approvalRequired:
                if policy.requiresApproval {
                    result.requiresApproval = true
                }

            case .autoApprove:
                if let threshold = policy.maxAmount, amount < threshold, hasReceipt {
                    result.autoApproved = true
                }
            }
        }

        // Evaluate workflows
        let workflows = fetchActiveWorkflows(context: context)
        for workflow in workflows {
            evaluateWorkflow(workflow, amount: amount, currency: currency, categoryName: categoryName, hasReceipt: hasReceipt, result: &result)
        }

        return result
    }

    // MARK: - Workflow Evaluation

    private func evaluateWorkflow(
        _ workflow: ApprovalWorkflow,
        amount: Double,
        currency: String,
        categoryName: String?,
        hasReceipt: Bool,
        result: inout RuleEvaluationResult
    ) {
        var triggered = false

        switch workflow.triggerCondition {
        case .amountExceeds:
            if let threshold = workflow.threshold, amount > threshold {
                triggered = true
            }

        case .categoryMatches:
            if let workflowCategory = workflow.categoryName,
               let expenseCategory = categoryName,
               workflowCategory == expenseCategory {
                triggered = true
            }

        case .missingReceipt:
            if !hasReceipt {
                triggered = true
            }

        case .foreignCurrency:
            if currency != "SEK" && currency != "USD" {
                triggered = true
            }

        case .alwaysRequireApproval:
            triggered = true
        }

        if triggered {
            result.appliedPolicies.append(workflow.workflowName)

            if workflow.autoApproveEnabled,
               let autoThreshold = workflow.autoApproveThreshold,
               amount < autoThreshold,
               hasReceipt {
                result.autoApproved = true
            } else {
                result.requiresApproval = true
                if let email = workflow.approverEmail {
                    result.approverEmail = email
                }
            }
        }
    }

    // MARK: - Reimbursement Calculation

    func calculateReimbursement(
        rateType: String,
        quantity: Double,
        date: Date,
        countryCode: String? = nil,
        context: ModelContext
    ) -> (amount: Double, currency: String)? {
        let descriptor = FetchDescriptor<ReimbursementRate>(
            predicate: #Predicate<ReimbursementRate> { rate in
                rate.rateType == rateType &&
                rate.isActive &&
                rate.validFrom <= date &&
                (rate.validTo == nil || rate.validTo! >= date)
            },
            sortBy: [SortDescriptor(\.validFrom, order: .reverse)]
        )

        do {
            let rates = try context.fetch(descriptor)

            // Prefer country-specific rate if available
            if let countryCode = countryCode,
               let countryRate = rates.first(where: { $0.countryCode == countryCode }) {
                return (countryRate.baseRate * quantity, countryRate.currency)
            }

            // Fallback to general rate
            if let generalRate = rates.first(where: { $0.countryCode == nil }) {
                return (generalRate.baseRate * quantity, generalRate.currency)
            }
        } catch {
            Log.e("Failed to fetch reimbursement rates: \(error)")
        }

        return nil
    }

    // MARK: - Database Queries

    private func fetchActivePolicies(for date: Date, context: ModelContext) -> [ExpensePolicy] {
        let descriptor = FetchDescriptor<ExpensePolicy>(
            predicate: #Predicate<ExpensePolicy> { policy in
                policy.isActive &&
                policy.validFrom <= date &&
                (policy.validTo == nil || policy.validTo! >= date)
            }
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            Log.e("Failed to fetch expense policies: \(error)")
            return []
        }
    }

    private func fetchActiveWorkflows(context: ModelContext) -> [ApprovalWorkflow] {
        let descriptor = FetchDescriptor<ApprovalWorkflow>(
            predicate: #Predicate<ApprovalWorkflow> { workflow in
                workflow.isActive
            }
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            Log.e("Failed to fetch approval workflows: \(error)")
            return []
        }
    }

    // MARK: - Seed Default Rules

    func seedDefaultRules(context: ModelContext) {
        // Check if already seeded
        let policyDescriptor = FetchDescriptor<ExpensePolicy>()
        if let existingCount = try? context.fetchCount(policyDescriptor), existingCount > 0 {
            return
        }

        // Swedish expense policies
        let receiptPolicy = ExpensePolicy(
            policyName: "Receipt Required Over 500 SEK",
            policyType: .receiptRequired,
            maxAmount: 500.0,
            requiresReceipt: true
        )

        let mealLimit = ExpensePolicy(
            policyName: "Breakfast Limit 150 SEK",
            policyType: .amountLimit,
            categoryName: "Meals",
            maxAmount: 150.0
        )

        let approvalPolicy = ExpensePolicy(
            policyName: "High Value Approval Over 5000 SEK",
            policyType: .approvalRequired,
            maxAmount: 5000.0,
            requiresApproval: true
        )

        let autoApprovePolicy = ExpensePolicy(
            policyName: "Auto-Approve Small Expenses Under 200 SEK",
            policyType: .autoApprove,
            maxAmount: 200.0
        )

        context.insert(receiptPolicy)
        context.insert(mealLimit)
        context.insert(approvalPolicy)
        context.insert(autoApprovePolicy)

        // Default workflows
        let highValueWorkflow = ApprovalWorkflow(
            workflowName: "High Value Expense Approval",
            triggerCondition: .amountExceeds,
            threshold: 5000.0,
            approverEmail: "manager@example.com"
        )

        let foreignCurrencyWorkflow = ApprovalWorkflow(
            workflowName: "Foreign Currency Review",
            triggerCondition: .foreignCurrency,
            autoApproveEnabled: true,
            autoApproveThreshold: 1000.0
        )

        context.insert(highValueWorkflow)
        context.insert(foreignCurrencyWorkflow)

        // Swedish reimbursement rates (2025)
        let mileageRate = ReimbursementRate(
            rateType: "mileage",
            baseRate: 2.50,
            currency: "SEK",
            unit: "km",
            countryCode: "SE",
            rateDescription: "Swedish standard mileage rate 2025"
        )

        let perDiemRate = ReimbursementRate(
            rateType: "per_diem",
            baseRate: 450.0,
            currency: "SEK",
            unit: "day",
            countryCode: "SE",
            rateDescription: "Swedish standard per diem 2025"
        )

        context.insert(mileageRate)
        context.insert(perDiemRate)

        do {
            try context.save()
            Log.i("RuleEngine: Seeded default business rules")
        } catch {
            Log.e("RuleEngine: Failed to seed default rules: \(error)")
        }
    }
}

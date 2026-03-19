//
//  SpecialDayEditor.swift
//  Vecka
//
//  情報デザイン: Edit/create/delete logic for special days.
//  Extracted from SpecialDaysListView for focused component architecture.
//
//  Responsibilities:
//  - Helper structs EditingSpecialDay and DeletedSpecialDay
//  - Data operations: create, update, delete with undo
//  - Editability check
//  - Editor routing (holiday editor, contact editor, memo editor)
//

import SwiftUI
import SwiftData

// MARK: - Helper Types

struct EditingSpecialDay: Identifiable {
    let id: String
    let ruleID: String
    let name: String
    let date: Date
    let type: SpecialDayType
    let symbolName: String?
    let iconColor: String?
    let notes: String?
    let region: String
}

struct DeletedSpecialDay {
    let ruleID: String
    let name: String
    let date: Date
    let type: SpecialDayType
    let symbol: String
    let iconColor: String?
    let notes: String?
    let region: String
}

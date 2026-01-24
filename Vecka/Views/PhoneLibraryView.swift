//
//  PhoneLibraryView.swift
//  Vecka
//
//  iPhone Library tab - Full-featured
//  情報デザイン (Jōhō Dezain) - Japanese Packaging Style
//

import SwiftUI
import SwiftData

struct PhoneLibraryView: View {
    // Unified memo query - filter by type in computed properties
    @Query private var memos: [Memo]
    @Query private var holidays: [HolidayRule]
    @Query private var contacts: [Contact]

    // Computed: Filter memos by type
    private var notes: [Memo] {
        memos.filter { $0.type == .note }
    }

    private var trips: [Memo] {
        memos.filter { $0.type == .trip }
    }

    private var expenses: [Memo] {
        memos.filter { $0.type == .expense }
    }

    private var countdowns: [Memo] {
        memos.filter { $0.type == .countdown }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Compartmentalized header (iPad ContactListView pattern)
                libraryHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // 情報デザイン: All entry types accessible from iPhone Library
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Special Days (Holidays, Observances, etc.)
                    NavigationLink {
                        SpecialDaysListView(isInMonthDetail: .constant(false))
                    } label: {
                        JohoListRow(
                            title: "Special Days",
                            subtitle: specialDaysSubtitle,
                            icon: "star.fill",
                            zone: .holidays,
                            badge: totalSpecialDaysCount > 0 ? "\(totalSpecialDaysCount)" : nil
                        )
                    }
                    .buttonStyle(.plain)

                    // Notes
                    NavigationLink {
                        NotesListView()
                    } label: {
                        JohoListRow(
                            title: Localization.notes,
                            subtitle: notesSubtitle,
                            icon: "note.text",
                            zone: .notes,
                            badge: notes.isEmpty ? nil : "\(notes.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    // Contacts
                    NavigationLink {
                        ContactListView()
                    } label: {
                        JohoListRow(
                            title: Localization.contacts,
                            subtitle: contactsSubtitle,
                            icon: "person.2",
                            zone: .contacts,
                            badge: contacts.isEmpty ? nil : "\(contacts.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    // Events (Countdowns)
                    NavigationLink {
                        CountdownListView()
                    } label: {
                        JohoListRow(
                            title: "Events",
                            subtitle: eventsSubtitle,
                            icon: "calendar.badge.clock",
                            zone: .events,
                            badge: nil  // Custom countdowns stored in UserDefaults
                        )
                    }
                    .buttonStyle(.plain)

                    // Trips
                    NavigationLink {
                        TripListView()
                    } label: {
                        JohoListRow(
                            title: Localization.trips,
                            subtitle: tripsSubtitle,
                            icon: "airplane",
                            zone: .trips,
                            badge: trips.isEmpty ? nil : "\(trips.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    // Expenses
                    NavigationLink {
                        ExpenseListView()
                    } label: {
                        JohoListRow(
                            title: Localization.expenses,
                            subtitle: expensesSubtitle,
                            icon: "dollarsign.circle",
                            zone: .expenses,
                            badge: expenses.isEmpty ? nil : "\(expenses.count)"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.bottom, JohoDimensions.spacingXL)
            }
        }
        .johoBackground()
        .johoNavigation(title: "")
    }

    // MARK: - Header (情報デザイン: Compartmentalized like iPad ContactListView)

    private var libraryHeader: some View {
        HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
            // Icon zone (gold/yellow for Library - matches sidebar accent)
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .johoTouchTarget(52)
                .background(Color(hex: "FFD700"))  // Gold - Library accent
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )

            // Title and stats zone
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)

                Text(librarySubtitle)
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer()
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    private var librarySubtitle: String {
        let totalItems = notes.count + contacts.count + trips.count + expenses.count + holidays.count
        return "\(totalItems) items across \(6) categories"
    }

    // MARK: - Computed Properties

    private var totalSpecialDaysCount: Int {
        holidays.count + trips.count + expenses.count
    }

    private var notesSubtitle: String {
        if notes.isEmpty {
            return Localization.noNotesYet
        } else {
            return notes.count == 1 ? "1 note" : "\(notes.count) notes"
        }
    }

    private var specialDaysSubtitle: String {
        let redDays = holidays.filter { $0.isBankHoliday }.count
        let observances = holidays.filter { !$0.isBankHoliday }.count
        var parts: [String] = []
        if redDays > 0 { parts.append("\(redDays) holidays") }
        if observances > 0 { parts.append("\(observances) observances") }
        if trips.count > 0 { parts.append("\(trips.count) trips") }
        if expenses.count > 0 { parts.append("\(expenses.count) expenses") }
        return parts.isEmpty ? "Holidays, trips & expenses" : parts.joined(separator: " • ")
    }

    private var contactsSubtitle: String {
        if contacts.isEmpty {
            return Localization.noContactsSaved
        } else {
            return "\(contacts.count) contacts"
        }
    }

    private var eventsSubtitle: String {
        return "Custom countdowns & events"
    }

    private var tripsSubtitle: String {
        if trips.isEmpty {
            return "Track your travels"
        } else {
            return trips.count == 1 ? "1 trip" : "\(trips.count) trips"
        }
    }

    private var expensesSubtitle: String {
        if expenses.isEmpty {
            return "Track your spending"
        } else {
            return expenses.count == 1 ? "1 expense" : "\(expenses.count) expenses"
        }
    }
}

#Preview {
    NavigationStack {
        PhoneLibraryView()
            .modelContainer(for: [
                Memo.self,
                HolidayRule.self,
                Contact.self
            ])
    }
}

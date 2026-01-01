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
    // Data queries for counts
    @Query private var notes: [DailyNote]
    @Query private var holidays: [HolidayRule]
    @Query private var trips: [TravelTrip]
    @Query private var expenses: [ExpenseItem]
    @Query private var contacts: [Contact]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page header with badge (情報デザイン: WHITE container)
                JohoPageHeader(
                    title: Localization.library,
                    badge: "LIBRARY"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Notes Section
                VStack(spacing: JohoDimensions.spacingSM) {
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
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Special Days Section (Holidays, Observances, Events, Trips, Expenses)
                VStack(spacing: JohoDimensions.spacingSM) {
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
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Contacts Section
                VStack(spacing: JohoDimensions.spacingSM) {
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
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.bottom, JohoDimensions.spacingXL)
            }
        }
        .johoBackground()
        .johoNavigation(title: "")
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
        let redDays = holidays.filter { $0.isRedDay }.count
        let observances = holidays.filter { !$0.isRedDay }.count
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
}

#Preview {
    NavigationStack {
        PhoneLibraryView()
            .modelContainer(for: [
                DailyNote.self,
                HolidayRule.self,
                TravelTrip.self,
                ExpenseItem.self,
                Contact.self
            ])
    }
}

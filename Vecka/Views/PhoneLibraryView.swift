//
//  PhoneLibraryView.swift
//  Vecka
//
//  iPhone Library tab - Full-featured
//  Slate design language
//

import SwiftUI

struct PhoneLibraryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Notes & Holidays Section
                VStack(spacing: 0) {
                    sectionHeader(Localization.holidaysSection)

                    VStack(spacing: 1) {
                        libraryRow(Localization.notes, icon: "note.text", destination: NotesListView())
                        libraryRow(Localization.holidays, icon: "star.fill", destination: HolidayListView())
                        libraryRow(Localization.observances, icon: "leaf", destination: ObservancesListView())
                    }
                    .background(SlateColors.mediumSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Features Section
                VStack(spacing: 0) {
                    sectionHeader(Localization.features)

                    VStack(spacing: 1) {
                        libraryRow(Localization.contacts, icon: "person.2", destination: ContactListView())
                        libraryRow(Localization.expenses, icon: "creditcard", destination: ExpenseListView())
                        libraryRow(Localization.trips, icon: "car", destination: TripListView())
                        libraryRow(Localization.weather, icon: "cloud.sun", destination: WeatherForecastView())
                    }
                    .background(SlateColors.mediumSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.small)
        }
        .background(SlateColors.deepSlate)
        .navigationTitle(Localization.library)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlateColors.tertiaryText)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, Spacing.extraSmall)
        .padding(.bottom, Spacing.small)
    }

    private func libraryRow<Destination: View>(_ title: String, icon: String, destination: Destination) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(SlateColors.sidebarActiveBar)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundStyle(SlateColors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlateColors.tertiaryText)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.medium)
            .background(SlateColors.lightSlate.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PhoneLibraryView()
    }
}

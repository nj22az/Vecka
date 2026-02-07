//
//  ContactPickerSheet.swift
//  Vecka
//
//  情報デザイン: Contact selection sheet for birthday-memo linking
//  Purple zone - people & connections
//

import SwiftUI
import SwiftData

// MARK: - Contact Picker Sheet

/// Searchable contact list for selecting a contact to merge with
struct ContactPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    @Query(sort: \Contact.familyName) private var allContacts: [Contact]

    let excludeContact: Contact
    let onSelect: (Contact) -> Void

    @State private var searchText = ""

    private var filteredContacts: [Contact] {
        let available = allContacts.filter { $0.id != excludeContact.id }

        if searchText.isEmpty {
            return available
        }

        let search = searchText.lowercased()
        return available.filter { contact in
            contact.displayName.lowercased().contains(search) ||
            contact.phoneNumbers.contains { $0.value.contains(search) } ||
            contact.emailAddresses.contains { $0.value.lowercased().contains(search) }
        }
    }

    private let accentColor = PageHeaderColor.contacts.accent

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar (情報デザイン: simple black border)
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))

                    TextField("Search contacts...", text: $searchText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
                .padding(JohoDimensions.spacingMD)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: 1.5)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.vertical, JohoDimensions.spacingSM)

                // Contact list
                if filteredContacts.isEmpty {
                    // Empty state
                    VStack(spacing: JohoDimensions.spacingMD) {
                        Spacer()

                        Image(systemName: searchText.isEmpty ? "person.crop.circle.badge.questionmark" : "magnifyingglass")
                            .font(.system(size: 40, weight: .light, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.3))

                        Text(searchText.isEmpty ? "No other contacts available" : "No contacts match '\(searchText)'")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredContacts, id: \.id) { contact in
                                contactRow(contact)

                                if contact.id != filteredContacts.last?.id {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }
                }
            }
            .johoBackground()
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func contactRow(_ contact: Contact) -> some View {
        Button {
            onSelect(contact)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Avatar (情報デザイン: icon zone with semantic color)
                ZStack {
                    if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(contact.initials)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
                .johoTouchTarget()
                .background(accentColor.opacity(0.2))
                .clipShape(Circle())
                .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)

                    // Subtitle: phone or email
                    if let phone = contact.phoneNumbers.first?.value {
                        Text(phone)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .lineLimit(1)
                    } else if let email = contact.emailAddresses.first?.value {
                        Text(email)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.3))
            }
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Contact Picker") {
    ContactPickerSheet(
        excludeContact: Contact(givenName: "Test", familyName: "User"),
        onSelect: { _ in }
    )
    .modelContainer(for: Contact.self, inMemory: true)
}

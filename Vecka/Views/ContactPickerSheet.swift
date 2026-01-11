//
//  ContactPickerSheet.swift
//  Vecka
//
//  情報デザイン: Contact selection sheet for manual merge
//  Purple zone - people & connections
//

import SwiftUI
import SwiftData

// MARK: - Contact Picker Sheet

/// Searchable contact list for selecting a contact to merge with
struct ContactPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    TextField("Search contacts...", text: $searchText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: 1.5)
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
                            .foregroundStyle(JohoColors.black.opacity(0.3))

                        Text(searchText.isEmpty ? "No other contacts available" : "No contacts match '\(searchText)'")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))

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
                    .foregroundStyle(JohoColors.black)
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
                            .foregroundStyle(JohoColors.black)
                    }
                }
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.2))
                .clipShape(Circle())
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    // Subtitle: phone or email
                    if let phone = contact.phoneNumbers.first?.value {
                        Text(phone)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .lineLimit(1)
                    } else if let email = contact.emailAddresses.first?.value {
                        Text(email)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.3))
            }
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Manual Merge Sheet

/// Simplified merge sheet for manual merges (doesn't require DuplicateSuggestion)
struct ManualMergeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let contact1: Contact
    let contact2: Contact
    let onMerged: () -> Void

    @State private var selectedPrimary: Contact?

    private let accentColor = PageHeaderColor.contacts.accent
    private let warningColor = JohoColors.cyan

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header info
                    VStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .frame(width: 72, height: 72)
                            .background(accentColor.opacity(0.2))
                            .clipShape(Squircle(cornerRadius: 16))
                            .overlay(
                                Squircle(cornerRadius: 16)
                                    .stroke(JohoColors.black, lineWidth: 2)
                            )

                        Text("MERGE CONTACTS")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)

                        Text("Select which contact to keep as primary")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, JohoDimensions.spacingSM)

                    // Contact selection cards
                    VStack(spacing: JohoDimensions.spacingSM) {
                        Text("TAP TO SELECT PRIMARY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, JohoDimensions.spacingMD)

                        contactCard(contact: contact1, isSelected: selectedPrimary?.id == contact1.id) {
                            selectedPrimary = contact1
                        }

                        contactCard(contact: contact2, isSelected: selectedPrimary?.id == contact2.id) {
                            selectedPrimary = contact2
                        }
                    }

                    // Merge preview
                    if let primary = selectedPrimary {
                        let secondary = primary.id == contact1.id ? contact2 : contact1

                        VStack(spacing: JohoDimensions.spacingSM) {
                            Divider()

                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(warningColor)

                                    Text("MERGE PREVIEW")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black.opacity(0.6))
                                }

                                Text("'\(secondary.displayName)' will be deleted.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black)

                                Text("Their data (phone, email, address, notes) will be added to '\(primary.displayName)'.")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                            .padding(JohoDimensions.spacingMD)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(warningColor.opacity(0.15))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: 1)
                            )
                        }
                    }

                    Spacer(minLength: JohoDimensions.spacingXL)

                    // Merge button
                    Button {
                        performMerge()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text("Merge Contacts")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedPrimary != nil ? accentColor : JohoColors.black.opacity(0.1))
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: 2)
                        )
                    }
                    .disabled(selectedPrimary == nil)
                    .padding(.bottom, JohoDimensions.spacingLG)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("Merge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                }
            }
        }
    }

    @ViewBuilder
    private func contactCard(contact: Contact, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? accentColor : JohoColors.black.opacity(0.3))

                // Avatar
                ZStack {
                    if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(contact.initials)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                    }
                }
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.2))
                .clipShape(Circle())
                .overlay(Circle().stroke(JohoColors.black, lineWidth: isSelected ? 2 : 1.5))

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    // Details count
                    let details: [String] = [
                        contact.phoneNumbers.isEmpty ? nil : "\(contact.phoneNumbers.count) phone",
                        contact.emailAddresses.isEmpty ? nil : "\(contact.emailAddresses.count) email",
                        contact.birthday != nil ? "birthday" : nil
                    ].compactMap { $0 }

                    if !details.isEmpty {
                        Text(details.joined(separator: " • "))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Primary badge
                if isSelected {
                    Text("PRIMARY")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                }
            }
            .padding(JohoDimensions.spacingMD)
            .background(isSelected ? accentColor.opacity(0.15) : JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func performMerge() {
        guard let primary = selectedPrimary else { return }
        let secondary = primary.id == contact1.id ? contact2 : contact1

        DuplicateContactManager.shared.manualMerge(
            primary: primary,
            secondary: secondary,
            modelContext: modelContext
        )

        HapticManager.notification(.success)
        dismiss()
        onMerged()
    }
}

#Preview("Contact Picker") {
    ContactPickerSheet(
        excludeContact: Contact(givenName: "Test", familyName: "User"),
        onSelect: { _ in }
    )
    .modelContainer(for: Contact.self, inMemory: true)
}

#Preview("Manual Merge") {
    ManualMergeSheet(
        contact1: Contact(givenName: "John", familyName: "Smith"),
        contact2: Contact(givenName: "J.", familyName: "Smith"),
        onMerged: {}
    )
    .modelContainer(for: Contact.self, inMemory: true)
}

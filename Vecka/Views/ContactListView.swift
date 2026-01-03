//
//  ContactListView.swift
//  Vecka
//
//  Contact list with 情報デザイン (Jōhō Dezain) styling
//  Purple zone - people & connections
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI

struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    private var contactsManager = ContactsManager.shared

    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var showingImportSheet = false
    @State private var showingContactPicker = false
    @State private var selectedContact: Contact?
    @State private var editingContact: Contact?
    @State private var showingDuplicateReview = false
    @State private var duplicateSuggestionCount = 0

    // Duplicate detection manager
    private let duplicateManager = DuplicateContactManager.shared

    // 情報デザイン accent color for Contacts (Warm Brown - from PageHeaderColor)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    // Stats for header subtitle
    private var contactsWithPhone: Int {
        contacts.filter { !$0.phoneNumbers.isEmpty }.count
    }
    private var contactsWithEmail: Int {
        contacts.filter { !$0.emailAddresses.isEmpty }.count
    }
    private var contactsWithBirthday: Int {
        contacts.filter { $0.birthday != nil }.count
    }

    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(searchText) ||
            contact.organizationName?.localizedCaseInsensitiveContains(searchText) == true ||
            contact.emailAddresses.contains { $0.value.localizedCaseInsensitiveContains(searchText) } ||
            contact.phoneNumbers.contains { $0.value.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedContacts: [String: [Contact]] {
        Dictionary(grouping: filteredContacts) { contact in
            let firstLetter = contact.familyName.isEmpty ?
                (contact.givenName.isEmpty ? "#" : String(contact.givenName.prefix(1).uppercased())) :
                String(contact.familyName.prefix(1).uppercased())
            return firstLetter.uppercased()
        }
    }

    var sortedSections: [String] {
        groupedContacts.keys.sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                // 情報デザイン Header (like Special Days page)
                contactsHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // Duplicate suggestion banner (情報デザイン: non-aggressive warning)
                if duplicateSuggestionCount > 0 {
                    DuplicateSuggestionBanner(suggestionCount: duplicateSuggestionCount) {
                        showingDuplicateReview = true
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // MAIN CONTENT CONTAINER (情報デザイン: All content in white container)
                VStack(spacing: 0) {
                    // Search field row
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(JohoColors.black)

                        TextField("Search contacts", text: $searchText)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(JohoColors.black)
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)

                    // Horizontal divider
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(height: 1.5)

                    // Content area
                    if contacts.isEmpty {
                        // Empty state (情報デザイン compliant)
                        contactsEmptyState
                    } else {
                        // Contact list
                        contactsListContent
                    }
                }
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddContact) {
            JohoContactEditorSheet(mode: .contact)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingImportSheet) {
            ContactImportView()
        }
        .sheet(item: $selectedContact) { contact in
            NavigationStack {
                ContactDetailView(contact: contact)
            }
        }
        .sheet(item: $editingContact) { contact in
            JohoContactEditorSheet(mode: .contact, existingContact: contact)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingDuplicateReview) {
            DuplicateReviewSheet()
                .onDisappear {
                    loadDuplicateSuggestions()
                }
        }
        .onAppear {
            loadDuplicateSuggestions()
        }
        .onChange(of: contacts.count) { _, _ in
            // Rescan when contacts change
            Task {
                await duplicateManager.scanForDuplicates(contacts: contacts, modelContext: modelContext)
                loadDuplicateSuggestions()
            }
        }
    }

    // MARK: - Duplicate Detection

    private func loadDuplicateSuggestions() {
        let suggestions = duplicateManager.loadPendingSuggestions(modelContext: modelContext)
        duplicateSuggestionCount = suggestions.count
    }

    // MARK: - Contacts Page Header (情報デザイン: Golden Standard Pattern)

    private var contactsHeader: some View {
        VStack(spacing: 0) {
            // MAIN ROW: Icon + Title | WALL | Import button
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone with Contacts accent color (Warm Brown)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PageHeaderColor.contacts.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.contacts.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text("CONTACTS")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Import button
                Button {
                    showingImportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(PageHeaderColor.contacts.accent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, JohoDimensions.spacingSM)
            }
            .frame(minHeight: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // STATS ROW: Contact counts with indicators
            HStack(spacing: JohoDimensions.spacingMD) {
                // Total contacts
                HStack(spacing: 4) {
                    JohoIndicatorCircle(color: PageHeaderColor.contacts.accent, size: .small)
                    Text("\(contacts.count)")
                        .font(JohoFont.labelSmall.bold())
                        .foregroundStyle(JohoColors.black)
                    Text("total")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                if contactsWithPhone > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                        Text("\(contactsWithPhone)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }
                }

                if contactsWithBirthday > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SpecialDayType.birthday.accentColor)
                        Text("\(contactsWithBirthday)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Empty State (情報デザイン: Black text in white container)

    private var contactsEmptyState: some View {
        VStack(spacing: JohoDimensions.spacingLG) {
            Spacer()
                .frame(height: JohoDimensions.spacingXL)

            // Icon in bordered box
            Image(systemName: "person.2.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 80, height: 80)
                .background(PageHeaderColor.contacts.lightBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: 2)
                )

            // Title and subtitle (BLACK text)
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("NO CONTACTS")
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)

                Text("Import from your address book or add contacts manually")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Import button (情報デザイン: bento row style with clear compartments)
            Button {
                showingImportSheet = true
            } label: {
                HStack(spacing: 0) {
                    // LEFT COMPARTMENT: Icon zone
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 56, height: 56)
                        .background(PageHeaderColor.contacts.lightBackground)

                    // VERTICAL WALL (full height)
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)

                    // RIGHT COMPARTMENT: Label
                    Text("IMPORT FROM ADDRESS BOOK")
                        .font(JohoFont.bodySmall.bold())
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .padding(.trailing, JohoDimensions.spacingMD)
                }
                .frame(height: 56)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()
                .frame(height: JohoDimensions.spacingXL)
        }
        .frame(minHeight: 300)
    }

    // MARK: - Contact List Content (情報デザイン: Clean grouped list with right index)

    private var contactsListContent: some View {
        HStack(spacing: 0) {
            // Main list area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(sortedSections, id: \.self) { section in
                            Section {
                                ForEach(groupedContacts[section] ?? []) { contact in
                                    Button {
                                        selectedContact = contact
                                    } label: {
                                        compactContactRow(for: contact)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button { selectedContact = contact } label: {
                                            Label("View", systemImage: "person.fill")
                                        }
                                        Button { editingContact = contact } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        if let phone = contact.phoneNumbers.first {
                                            Button {
                                                if let url = URL(string: "tel:\(phone.value)") {
                                                    UIApplication.shared.open(url)
                                                }
                                            } label: {
                                                Label("Call", systemImage: "phone.fill")
                                            }
                                        }
                                        Divider()
                                        Button(role: .destructive) { deleteContact(contact) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                sectionHeader(letter: section)
                                    .id(section)
                            }
                        }
                    }
                }
                .onChange(of: selectedLetter) { _, letter in
                    if let letter = letter {
                        withAnimation {
                            proxy.scrollTo(letter, anchor: .top)
                        }
                        selectedLetter = nil
                    }
                }
            }

            // Right alphabet index (情報デザイン: minimal vertical strip)
            VStack(spacing: 1) {
                ForEach(sortedSections, id: \.self) { letter in
                    Button {
                        selectedLetter = letter
                        HapticManager.selection()
                    } label: {
                        Text(letter)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 18, height: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, JohoDimensions.spacingSM)
            .padding(.trailing, 4)
        }
    }

    @State private var selectedLetter: String?

    // MARK: - Section Header (情報デザイン: Clean letter header)

    private func sectionHeader(letter: String) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(letter)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .frame(width: 24, height: 24)
                .background(JohoColors.black)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Rectangle()
                .fill(JohoColors.black.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(JohoColors.white)
    }

    // MARK: - Kudo-Style Contact Row (情報デザイン: Photo + Name | Birthday | Chevron)

    private func compactContactRow(for contact: Contact) -> some View {
        HStack(spacing: 0) {
            // PHOTO COMPARTMENT (48pt)
            JohoContactAvatar(contact: contact, size: 48)
                .padding(.trailing, JohoDimensions.spacingSM)

            // NAME COMPARTMENT (flexible)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                // Alias/Organization as subtitle
                if let org = contact.organizationName, !org.isEmpty {
                    Text(org)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // BIRTHDAY COMPARTMENT (64pt) - Kudo-style
            birthdayCompartment(for: contact)
                .frame(width: 64)

            // CHEVRON COMPARTMENT (24pt)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JohoColors.black.opacity(0.4))
                .frame(width: 24)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .frame(height: 64)
    }

    // MARK: - Birthday Compartment (Kudo-style: Date + Cake icon)

    @ViewBuilder
    private func birthdayCompartment(for contact: Contact) -> some View {
        if let birthday = contact.birthday, contact.hasBirthdayForStarPage {
            VStack(spacing: 2) {
                Text(birthday.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(SpecialDayType.birthday.accentColor)
            }
        } else {
            Text("—")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.3))
        }
    }

    // MARK: - Contact Row (情報デザイン: Bento style with compartments)

    private func contactRow(for contact: Contact) -> some View {
        HStack(spacing: 0) {
            // LEFT: Avatar compartment
            JohoContactAvatar(contact: contact, size: 44)
                .padding(.horizontal, JohoDimensions.spacingSM)

            // WALL
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .padding(.vertical, JohoDimensions.spacingSM)

            // CENTER: Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(JohoFont.body.bold())
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                if let org = contact.organizationName, !org.isEmpty {
                    Text(org)
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            Spacer()

            // RIGHT: Quick info indicators
            HStack(spacing: 4) {
                if !contact.phoneNumbers.isEmpty {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                if !contact.emailAddresses.isEmpty {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                if contact.birthday != nil {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SpecialDayType.birthday.accentColor)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .padding(.trailing, JohoDimensions.spacingSM)
        }
        .frame(height: 56)
        .background(JohoColors.inputBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    /// 情報デザイン: Compact subtitle showing contact stats
    private var contactsSubtitle: String {
        var parts: [String] = []
        parts.append("\(contacts.count) contact\(contacts.count == 1 ? "" : "s")")

        var details: [String] = []
        if contactsWithPhone > 0 { details.append("\(contactsWithPhone) phone") }
        if contactsWithBirthday > 0 { details.append("\(contactsWithBirthday) birthday\(contactsWithBirthday == 1 ? "" : "s")") }

        if !details.isEmpty {
            parts.append("• " + details.joined(separator: " • "))
        }

        return parts.joined(separator: " ")
    }

    private func deleteContact(_ contact: Contact) {
        modelContext.delete(contact)
        try? modelContext.save()
    }
}

// MARK: - 情報デザイン Circular Contact Avatar (iOS Contacts style)

/// Circular contact avatar with photo or initials - like iOS Contacts
/// Uses 情報デザイン styling: black border, Warm Brown accent for initials
struct JohoContactAvatar: View {
    let contact: Contact
    var size: CGFloat = 56

    // 情報デザイン accent color for contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    private var fontSize: CGFloat {
        size * 0.4
    }

    private var borderWidth: CGFloat {
        size >= 80 ? JohoDimensions.borderThick : JohoDimensions.borderMedium
    }

    var body: some View {
        Group {
            if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                // Photo available - circular frame with black border
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(JohoColors.black, lineWidth: borderWidth)
                    )
            } else {
                // No photo - show initials with purple background
                ZStack {
                    Circle()
                        .fill(accentColor)

                    Text(contact.initials.isEmpty ? "?" : contact.initials)
                        .font(.system(size: fontSize, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                }
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(JohoColors.black, lineWidth: borderWidth)
                )
            }
        }
    }
}

// MARK: - 情報デザイン Contact Row with Circular Photo

/// A contact row that displays circular photo (or initials), name, organization, and quick contact info
struct JohoContactRow: View {
    let contact: Contact

    // 情報デザイン accent color for contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    private var primaryPhone: String? {
        contact.phoneNumbers.first?.value
    }

    private var primaryEmail: String? {
        contact.emailAddresses.first?.value
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Circular photo avatar (like iOS Contacts)
            JohoContactAvatar(contact: contact, size: 56)

            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(contact.displayName)
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                // Organization (if any)
                if let org = contact.organizationName, !org.isEmpty {
                    Text(org)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }

                // Quick contact info pills (情報デザイン colored pills)
                HStack(spacing: JohoDimensions.spacingSM) {
                    if primaryPhone != nil {
                        contactInfoPill(icon: "phone.fill", text: "PHONE", color: accentColor)
                    }

                    if primaryEmail != nil {
                        contactInfoPill(icon: "envelope.fill", text: "EMAIL", color: accentColor)
                    }

                    if contact.birthday != nil {
                        contactInfoPill(icon: "gift.fill", text: "BDAY", color: SpecialDayType.birthday.accentColor)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JohoColors.black)
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    @ViewBuilder
    private func contactInfoPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(JohoColors.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}

struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var contactsManager = ContactsManager.shared

    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var showingIOSContactPicker = false

    // 情報デザイン accent color for Contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Header with Close button (情報デザイン: floating buttons outside card)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingMD)
                                .background(JohoColors.white)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                    // MAIN CONTENT CARD (情報デザイン: All content in WHITE container)
                    VStack(spacing: 0) {
                        // Title with icon indicator
                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Icon zone
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(accentColor)
                                .frame(width: 40, height: 40)
                                .background(PageHeaderColor.contacts.lightBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
                                )

                            Text("IMPORT CONTACTS")
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Horizontal divider
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(height: 1.5)

                        // Import options (情報デザイン: bento rows)
                        VStack(spacing: JohoDimensions.spacingSM) {
                            // Import All option
                            Button {
                                importAllContacts()
                            } label: {
                                importOptionRow(
                                    icon: "person.2.fill",
                                    title: "Import All Contacts",
                                    subtitle: "From your address book"
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isImporting || contactsManager.authorizationStatus != .authorized)
                            .opacity((isImporting || contactsManager.authorizationStatus != .authorized) ? 0.5 : 1.0)

                            // Select Contacts option
                            Button {
                                showingIOSContactPicker = true
                            } label: {
                                importOptionRow(
                                    icon: "person.badge.plus",
                                    title: "Select Contacts",
                                    subtitle: "Choose specific contacts"
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isImporting || contactsManager.authorizationStatus != .authorized)
                            .opacity((isImporting || contactsManager.authorizationStatus != .authorized) ? 0.5 : 1.0)
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Permission warning if needed
                        if contactsManager.authorizationStatus != .authorized {
                            // Divider
                            Rectangle()
                                .fill(JohoColors.black)
                                .frame(height: 1.5)

                            // Warning section (情報デザイン: white background with warning indicator)
                            VStack(spacing: JohoDimensions.spacingMD) {
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    // Warning icon
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(JohoColors.red)
                                        .frame(width: 32, height: 32)
                                        .background(JohoColors.redLight)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

                                    JohoPill(text: "PERMISSION REQUIRED", style: .whiteOnBlack, size: .small)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Contacts access is required to import from your address book.")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Grant permission button
                                Button {
                                    requestPermission()
                                } label: {
                                    HStack(spacing: 0) {
                                        // Icon zone
                                        Image(systemName: "person.badge.key")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(JohoColors.red)
                                            .frame(width: 44, height: 44)
                                            .background(JohoColors.redLight)

                                        // Wall
                                        Rectangle()
                                            .fill(JohoColors.black)
                                            .frame(width: 1.5)

                                        // Label
                                        Text("GRANT PERMISSION")
                                            .font(JohoFont.bodySmall.bold())
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.horizontal, JohoDimensions.spacingMD)

                                        Spacer()

                                        // Chevron
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.trailing, JohoDimensions.spacingMD)
                                    }
                                    .frame(height: 48)
                                    .background(JohoColors.white)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                            .stroke(JohoColors.black, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(JohoDimensions.spacingMD)
                        }

                        // Status message if available
                        if let message = importMessage {
                            // Divider
                            Rectangle()
                                .fill(JohoColors.black)
                                .frame(height: 1.5)

                            HStack(spacing: JohoDimensions.spacingSM) {
                                Image(systemName: message.contains("Success") ? "checkmark.circle.fill" : "info.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(message.contains("Success") ? JohoColors.green : accentColor)

                                Text(message)
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black)

                                Spacer()
                            }
                            .padding(JohoDimensions.spacingMD)
                        }
                    }
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
                .padding(.bottom, JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if isImporting {
                    VStack(spacing: JohoDimensions.spacingMD) {
                        ProgressView()
                            .tint(JohoColors.white)

                        Text("Importing...")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.white)
                    }
                    .padding(JohoDimensions.spacingXL)
                    .background(JohoColors.black.opacity(0.9))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                }
            }
            .sheet(isPresented: $showingIOSContactPicker) {
                IOSContactPickerView { selectedContacts in
                    importSelectedContacts(selectedContacts)
                }
            }
        }
    }

    // MARK: - Import Option Row (情報デザイン: Bento style)

    private func importOptionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 0) {
            // Icon zone (with left padding for breathing room)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(PageHeaderColor.contacts.lightBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: 1.5)
                )
                .padding(.leading, JohoDimensions.spacingSM)

            // Wall (full height, no vertical padding)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .padding(.leading, JohoDimensions.spacingSM)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body.bold())
                    .foregroundStyle(JohoColors.black)

                Text(subtitle)
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .padding(.trailing, JohoDimensions.spacingMD)
        }
        .frame(height: 56)
        .background(JohoColors.inputBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    private func requestPermission() {
        Task {
            do {
                let granted = try await contactsManager.requestAccess()
                if granted {
                    importMessage = "Permission granted. You can now import contacts."
                } else {
                    importMessage = "Permission denied. Please enable in Settings."
                }
            } catch {
                importMessage = "Error requesting permission: \(error.localizedDescription)"
            }
        }
    }

    private func importAllContacts() {
        isImporting = true
        importMessage = nil

        Task {
            do {
                let count = try await contactsManager.importAllContacts(to: modelContext)
                await MainActor.run {
                    importMessage = "Successfully imported \(count) contacts"
                    isImporting = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    importMessage = "Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }

    private func importSelectedContacts(_ cnContacts: [CNContact]) {
        isImporting = true
        importMessage = nil

        Task {
            do {
                try await contactsManager.importContacts(cnContacts, to: modelContext)
                await MainActor.run {
                    importMessage = "Successfully imported \(cnContacts.count) contacts"
                    isImporting = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    importMessage = "Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}

struct IOSContactPickerView: UIViewControllerRepresentable {
    let onContactsSelected: ([CNContact]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactsSelected: onContactsSelected)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactsSelected: ([CNContact]) -> Void

        init(onContactsSelected: @escaping ([CNContact]) -> Void) {
            self.onContactsSelected = onContactsSelected
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            onContactsSelected(contacts)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // User cancelled
        }
    }
}

// MARK: - 情報デザイン Add Contact Sheet

/// 情報デザイン compliant sheet for adding a Contact (Birthday is part of Contact)
struct JohoAddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectContact: () -> Void

    // 情報デザイン accent color for contacts (Warm Brown)
    private var contactColor: Color { PageHeaderColor.contacts.accent }

    var body: some View {
        VStack(spacing: 0) {
            // 情報デザイン Header - Bold BLACK with thick border
            HStack {
                Text("ADD")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(JohoColors.white)

                Spacer()

                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(JohoColors.white)
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(JohoColors.black)
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, 12)
            .background(JohoColors.black)

            // Entry list with thick BLACK borders between rows
            VStack(spacing: 0) {
                // Contact option (Birthday is part of Contact - set in editor)
                Button {
                    HapticManager.selection()
                    onSelectContact()
                } label: {
                    johoInputRow(
                        icon: "person.fill",
                        code: "CTT",
                        label: "CONTACT",
                        meta: "PERSON",
                        color: contactColor
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingLG)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(160)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }

    @ViewBuilder
    private func johoInputRow(icon: String, code: String, label: String, meta: String, color: Color) -> some View {
        HStack(spacing: 12) {
            // 情報デザイン: Colored circle with BLACK border + Icon
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.white)
            }

            // Code badge - BLACK border around colored pill
            Text(code)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Squircle(cornerRadius: 4))
                .overlay(
                    Squircle(cornerRadius: 4)
                        .stroke(JohoColors.black, lineWidth: 1.5)
                )

            // Label - bold rounded for 情報デザイン
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Spacer()

            // Arrow - bold BLACK
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JohoColors.black)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, 10)
        .background(JohoColors.white)
    }
}

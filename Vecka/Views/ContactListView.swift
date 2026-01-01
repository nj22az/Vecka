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

    // 情報デザイン accent color for Contacts (purple)
    private let accentColor = Color(hex: "805AD5")

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
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン Header (like Special Days page)
                contactsHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

                // Search field (情報デザイン inline style with thick border)
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
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                if contacts.isEmpty {
                    // Empty state
                    JohoEmptyState(
                        title: "No Contacts",
                        message: "Import from your address book or add contacts manually",
                        icon: "person.3.fill",
                        zone: .contacts
                    )
                    .padding(.top, JohoDimensions.spacingXL)

                    Button {
                        showingImportSheet = true
                    } label: {
                        JohoListRow(
                            title: "Import from Address Book",
                            icon: "square.and.arrow.down",
                            zone: .contacts,
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, JohoDimensions.spacingLG)
                } else {
                    // Grouped contacts by section letter
                    ForEach(sortedSections, id: \.self) { section in
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            // Section header pill (情報デザイン)
                            JohoPill(text: section, style: .whiteOnBlack, size: .medium)
                                .padding(.horizontal, JohoDimensions.spacingLG)

                            // Contact rows in this section
                            VStack(spacing: JohoDimensions.spacingSM) {
                                ForEach(groupedContacts[section] ?? []) { contact in
                                    Button {
                                        selectedContact = contact
                                    } label: {
                                        JohoContactRow(contact: contact)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            selectedContact = contact
                                        } label: {
                                            Label("View", systemImage: "person.fill")
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

                                        if let email = contact.emailAddresses.first {
                                            Button {
                                                if let url = URL(string: "mailto:\(email.value)") {
                                                    UIApplication.shared.open(url)
                                                }
                                            } label: {
                                                Label("Email", systemImage: "envelope.fill")
                                            }
                                        }

                                        Divider()

                                        Button(role: .destructive) {
                                            deleteContact(contact)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, JohoDimensions.spacingLG)
                        }
                    }
                }
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
    }

    // MARK: - 情報デザイン Header (like Special Days)

    private var contactsHeader: some View {
        HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
            // Icon zone (情報デザイン: purple for contacts)
            Image(systemName: "person.2.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(JohoColors.white)
                .frame(width: 52, height: 52)
                .background(accentColor)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )

            // Title and stats
            VStack(alignment: .leading, spacing: 2) {
                Text("Contacts")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                // Stats subtitle (情報デザイン: compact info)
                Text(contactsSubtitle)
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Import from address book button (情報デザイン: squircle button)
            Button {
                showingImportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
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
/// Uses 情報デザイン styling: black border, purple accent for initials
struct JohoContactAvatar: View {
    let contact: Contact
    var size: CGFloat = 56

    // 情報デザイン accent color for contacts (purple)
    private let accentColor = Color(hex: "805AD5")

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

    // 情報デザイン accent color for contacts (purple)
    private let accentColor = Color(hex: "805AD5")

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Page header
                    JohoPageHeader(
                        title: "Import Contacts",
                        badge: "IMPORT"
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingLG)

                    // Import options section
                    JohoSectionBox(
                        title: "Import Options",
                        zone: .contacts,
                        icon: "square.and.arrow.down"
                    ) {
                        VStack(spacing: JohoDimensions.spacingSM) {
                            Button {
                                importAllContacts()
                            } label: {
                                HStack(spacing: JohoDimensions.spacingMD) {
                                    JohoIconBadge(icon: "person.2.fill", zone: .contacts, size: 40)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Import All Contacts")
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)

                                        Text("From your address book")
                                            .font(JohoFont.bodySmall)
                                            .foregroundStyle(JohoColors.black.opacity(0.6))
                                    }

                                    Spacer()

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
                            .buttonStyle(.plain)
                            .disabled(isImporting || contactsManager.authorizationStatus != .authorized)
                            .opacity((isImporting || contactsManager.authorizationStatus != .authorized) ? 0.5 : 1.0)

                            Button {
                                showingIOSContactPicker = true
                            } label: {
                                HStack(spacing: JohoDimensions.spacingMD) {
                                    JohoIconBadge(icon: "person.badge.plus", zone: .contacts, size: 40)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Select Contacts to Import")
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)

                                        Text("Choose specific contacts")
                                            .font(JohoFont.bodySmall)
                                            .foregroundStyle(JohoColors.black.opacity(0.6))
                                    }

                                    Spacer()

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
                            .buttonStyle(.plain)
                            .disabled(isImporting || contactsManager.authorizationStatus != .authorized)
                            .opacity((isImporting || contactsManager.authorizationStatus != .authorized) ? 0.5 : 1.0)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Permission request if needed
                    if contactsManager.authorizationStatus != .authorized {
                        JohoSectionBox(
                            title: "Permission Required",
                            zone: .warning,
                            icon: "exclamationmark.triangle.fill"
                        ) {
                            VStack(spacing: JohoDimensions.spacingMD) {
                                Text("Contacts access is required to import from your address book.")
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black)

                                Button {
                                    requestPermission()
                                } label: {
                                    JohoListRow(
                                        title: "Grant Contacts Permission",
                                        icon: "person.badge.key",
                                        zone: .warning,
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // Status message
                    if let message = importMessage {
                        JohoSectionBox(
                            title: "Status",
                            zone: .contacts,
                            icon: "checkmark.circle.fill"
                        ) {
                            Text(message)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }
                }
                .padding(.bottom, JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                // Inline header with close button (情報デザイン)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        JohoActionButton(icon: "xmark")
                    }

                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
            }
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
                try contactsManager.importContacts(cnContacts, to: modelContext)
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

// MARK: - 情報デザイン Add Contact Sheet (Birthday vs Contact picker)

/// 情報デザイン compliant sheet for choosing to add a Contact or Birthday
struct JohoAddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectContact: () -> Void
    let onSelectBirthday: () -> Void

    // 情報デザイン accent color for contacts (purple)
    private let contactColor = Color(hex: "805AD5")
    private let birthdayColor = SpecialDayType.birthday.accentColor

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
                // Contact option
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

                // Thick BLACK divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: JohoDimensions.borderMedium)

                // Birthday option
                Button {
                    HapticManager.selection()
                    onSelectBirthday()
                } label: {
                    johoInputRow(
                        icon: "birthday.cake.fill",
                        code: "BDY",
                        label: "BIRTHDAY",
                        meta: "CONTACT",
                        color: birthdayColor
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
        .presentationDetents([.height(200)])
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

//
//  ContactDetailView.swift
//  Vecka
//
//  Contact detail view with 情報デザイン (Jōhō Dezain) styling
//  Purple zone - people & connections
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - 情報デザイン Contact Detail View

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let contact: Contact

    @State private var showingEditor = false
    @State private var showingQRCode = false
    @State private var showingVCardShare = false
    @State private var vcardURL: URL?

    // 情報デザイン accent color for contacts (purple)
    private let accentColor = Color(hex: "805AD5")

    init(contact: Contact) {
        self.contact = contact
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Hero avatar section (circular photo, 情報デザイン bento style)
                heroAvatarSection

                // Quick action buttons (情報デザイン: white bg with colored icons)
                quickActionsSection

                // Phone section
                if !contact.phoneNumbers.isEmpty {
                    phoneSection
                }

                // Email section
                if !contact.emailAddresses.isEmpty {
                    emailSection
                }

                // Address section
                if !contact.postalAddresses.isEmpty {
                    addressSection
                }

                // Birthday section
                if contact.birthday != nil {
                    birthdaySection
                }

                // Notes section
                if let note = contact.note, !note.isEmpty {
                    notesSection(note: note)
                }

                // Share actions section
                shareActionsSection
            }
            .padding(JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            // Header with close and edit buttons
            HStack {
                closeButton
                Spacer()
                editButton
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingSM)
        }
        .sheet(isPresented: $showingEditor) {
            JohoContactEditorSheet(mode: .contact, existingContact: contact)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(contact: contact)
        }
        .sheet(isPresented: $showingVCardShare) {
            if let url = vcardURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Hero Avatar Section (情報デザイン: White card with circular photo)

    private var heroAvatarSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // Circular avatar (like iOS Contacts)
            JohoContactAvatar(contact: contact, size: 100)

            // Name
            Text(contact.displayName)
                .font(JohoFont.displayMedium)
                .foregroundStyle(JohoColors.black)
                .multilineTextAlignment(.center)

            // Organization (if any)
            if let org = contact.organizationName, !org.isEmpty {
                Text(org)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Quick Actions Section (情報デザイン: white card with action buttons)

    private var quickActionsSection: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Call button
            if let phone = contact.phoneNumbers.first {
                johoQuickActionButton(
                    icon: "phone.fill",
                    label: "CALL",
                    color: JohoColors.green
                ) {
                    if let url = URL(string: "tel:\(phone.value)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // Message button
            if let phone = contact.phoneNumbers.first {
                johoQuickActionButton(
                    icon: "message.fill",
                    label: "MESSAGE",
                    color: JohoColors.cyan
                ) {
                    if let url = URL(string: "sms:\(phone.value)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // Email button
            if let email = contact.emailAddresses.first {
                johoQuickActionButton(
                    icon: "envelope.fill",
                    label: "EMAIL",
                    color: accentColor
                ) {
                    if let url = URL(string: "mailto:\(email.value)") {
                        UIApplication.shared.open(url)
                    }
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
    }

    @ViewBuilder
    private func johoQuickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: JohoDimensions.spacingXS) {
                // Icon with white background, colored border (情報デザイン compliant)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phone Section (情報デザイン: white card with header pill)

    private var phoneSection: some View {
        johoDetailSection(title: "PHONE", icon: "phone.fill") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(contact.phoneNumbers, id: \.id) { phone in
                    johoInfoRow(
                        label: phone.label.uppercased(),
                        value: phone.value,
                        actions: [
                            ("phone.fill", JohoColors.green, { callPhone(phone.value) }),
                            ("message.fill", JohoColors.cyan, { messagePhone(phone.value) })
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        johoDetailSection(title: "EMAIL", icon: "envelope.fill") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(contact.emailAddresses, id: \.id) { email in
                    johoInfoRow(
                        label: email.label.uppercased(),
                        value: email.value,
                        actions: [
                            ("envelope.fill", accentColor, { sendEmail(email.value) })
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Address Section

    private var addressSection: some View {
        johoDetailSection(title: "ADDRESS", icon: "mappin") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(contact.postalAddresses, id: \.id) { address in
                    HStack(alignment: .top, spacing: JohoDimensions.spacingMD) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(address.label.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))

                            Text(address.formattedAddress)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                        }

                        Spacer()

                        // Open in Maps
                        Button {
                            openInMaps(address.formattedAddress)
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.orange)
                                .frame(width: 36, height: 36)
                                .background(JohoColors.white)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                    )
                }
            }
        }
    }

    // MARK: - Birthday Section

    private var birthdaySection: some View {
        johoDetailSection(title: "BIRTHDAY", icon: "gift.fill", iconColor: SpecialDayType.birthday.accentColor) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let birthday = contact.birthday {
                        Text(birthday.formatted(.dateTime.month(.wide).day()))
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)

                        // Age calculation
                        if let age = calculateAge(from: birthday) {
                            Text("\(age) years old")
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }
                }

                Spacer()

                // Birthday cake icon
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(SpecialDayType.birthday.accentColor)
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )
        }
    }

    private func calculateAge(from birthday: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }

    // MARK: - Notes Section

    private func notesSection(note: String) -> some View {
        johoDetailSection(title: "NOTES", icon: "doc.text", iconColor: JohoColors.yellow) {
            Text(note)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                )
        }
    }

    // MARK: - Share Actions Section

    private var shareActionsSection: some View {
        johoDetailSection(title: "SHARE", icon: "square.and.arrow.up") {
            VStack(spacing: JohoDimensions.spacingSM) {
                // QR Code
                Button {
                    showingQRCode = true
                } label: {
                    johoActionRow(icon: "qrcode", title: "Share as QR Code")
                }
                .buttonStyle(.plain)

                // vCard
                Button {
                    generateAndShareVCard()
                } label: {
                    johoActionRow(icon: "square.and.arrow.up", title: "Share as vCard")
                }
                .buttonStyle(.plain)

                // Export to iOS Contacts
                Button {
                    exportToIOSContacts()
                } label: {
                    johoActionRow(icon: "person.badge.plus", title: "Export to iOS Contacts")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 情報デザイン Section Container (white card with header pill)

    @ViewBuilder
    private func johoDetailSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color = Color(hex: "805AD5"),
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Header row with pill and icon
            HStack(spacing: JohoDimensions.spacingSM) {
                JohoPill(text: title, style: .whiteOnBlack, size: .medium)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)

                Spacer()
            }

            // Content
            content()
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    @ViewBuilder
    private func johoActionRow(icon: String, title: String) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 36, height: 36)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: 1.5)
                )

            Text(title)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)

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
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    // MARK: - Info Row Helper (情報デザイン: white background with colored action icons)

    @ViewBuilder
    private func johoInfoRow(label: String, value: String, actions: [(String, Color, () -> Void)]) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Text(value)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
            }

            Spacer()

            // Action buttons with semantic colors
            HStack(spacing: JohoDimensions.spacingSM) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.2) {
                        Image(systemName: action.0)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(action.1)
                            .frame(width: 36, height: 36)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    // MARK: - Control Buttons

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 36, height: 36)
                .background(JohoColors.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
        }
    }

    private var editButton: some View {
        Button { showingEditor = true } label: {
            Image(systemName: "pencil")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 36, height: 36)
                .background(accentColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
        }
    }

    // MARK: - Actions

    private func callPhone(_ number: String) {
        if let url = URL(string: "tel:\(number)") {
            UIApplication.shared.open(url)
        }
    }

    private func messagePhone(_ number: String) {
        if let url = URL(string: "sms:\(number)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    private func openInMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func generateAndShareVCard() {
        let vcard = contact.toVCard()
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(contact.displayName).vcf"
        let url = tempDir.appendingPathComponent(filename)

        do {
            try vcard.write(to: url, atomically: true, encoding: .utf8)
            vcardURL = url
            showingVCardShare = true
        } catch {
            print("Failed to create vCard file: \(error)")
        }
    }

    private func exportToIOSContacts() {
        Task {
            do {
                try ContactsManager.shared.exportToIOSContacts(contact)
                HapticManager.notification(.success)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}

// MARK: - 情報デザイン Contact Editor Sheet

/// Editor mode determines UI focus
enum JohoContactEditorMode {
    case birthday   // From Special Days - birthday-focused, pink accent
    case contact    // From Contacts - full contact, purple accent

    var title: String {
        switch self {
        case .birthday: return "New Birthday"
        case .contact: return "New Contact"
        }
    }

    var icon: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .contact: return "person.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .birthday: return SpecialDayType.birthday.accentColor
        case .contact: return Color(hex: "805AD5")  // Purple - people & contacts
        }
    }
}

/// 情報デザイン compliant contact editor (unified for birthday and contact creation)
struct JohoContactEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: JohoContactEditorMode
    let existingContact: Contact?

    // Form fields
    @State private var firstName: String
    @State private var lastName: String
    @State private var company: String
    @State private var phone: String
    @State private var email: String
    @State private var notes: String

    // Birthday fields
    @State private var hasBirthday: Bool
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Photo picker (circular avatar like iOS Contacts)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    private var accentColor: Color { mode.accentColor }

    private var isEditing: Bool { existingContact != nil }

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Year range for birthday picker (1900 to current year)
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1920...currentYear).reversed())
    }

    init(mode: JohoContactEditorMode = .contact, existingContact: Contact? = nil) {
        self.mode = mode
        self.existingContact = existingContact

        let calendar = Calendar.current
        let now = Date()

        // Initialize form fields from existing contact or defaults
        if let contact = existingContact {
            _firstName = State(initialValue: contact.givenName)
            _lastName = State(initialValue: contact.familyName)
            _company = State(initialValue: contact.organizationName ?? "")
            _phone = State(initialValue: contact.phoneNumbers.first?.value ?? "")
            _email = State(initialValue: contact.emailAddresses.first?.value ?? "")
            _notes = State(initialValue: contact.note ?? "")
            _selectedImageData = State(initialValue: contact.imageData)

            if let birthday = contact.birthday {
                _hasBirthday = State(initialValue: true)
                _selectedYear = State(initialValue: calendar.component(.year, from: birthday))
                _selectedMonth = State(initialValue: calendar.component(.month, from: birthday))
                _selectedDay = State(initialValue: calendar.component(.day, from: birthday))
            } else {
                _hasBirthday = State(initialValue: false)
                _selectedYear = State(initialValue: 1990)
                _selectedMonth = State(initialValue: calendar.component(.month, from: now))
                _selectedDay = State(initialValue: calendar.component(.day, from: now))
            }
        } else {
            _firstName = State(initialValue: "")
            _lastName = State(initialValue: "")
            _company = State(initialValue: "")
            _phone = State(initialValue: "")
            _email = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedImageData = State(initialValue: nil)
            _selectedYear = State(initialValue: 1990)
            _selectedMonth = State(initialValue: calendar.component(.month, from: now))
            _selectedDay = State(initialValue: calendar.component(.day, from: now))
            // Birthday mode starts with birthday enabled
            _hasBirthday = State(initialValue: mode == .birthday)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating header with Cancel/Save buttons (情報デザイン)
            headerSection
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.vertical, JohoDimensions.spacingMD)
                .background(JohoColors.background)

            // Scrollable content
            ScrollView {
                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator
                    titleSection

                    // Avatar placeholder
                    avatarSection

                    // Name fields
                    nameFieldsSection

                    // Company (contact mode only)
                    if mode == .contact {
                        companyFieldSection
                    }

                    // Birthday section
                    birthdaySection

                    // Phone field
                    phoneFieldSection

                    // Email field (contact mode only)
                    if mode == .contact {
                        emailFieldSection
                    }

                    // Notes field
                    notesFieldSection
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
    }

    // MARK: - Header Section (Floating Cancel/Save)

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }

            Spacer()

            Button {
                saveContact()
                dismiss()
            } label: {
                Text("Save")
                    .font(JohoFont.body.bold())
                    .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.vertical, JohoDimensions.spacingMD)
                    .background(canSave ? accentColor : JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Circle()
                .fill(accentColor)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
            Text(isEditing ? "Edit Contact" : mode.title)
                .font(JohoFont.displaySmall)
                .foregroundStyle(JohoColors.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Avatar Section (情報デザイン: Circular photo like iOS Contacts)

    private var avatarSection: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    // Show selected/existing photo in circular frame
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                        )
                } else {
                    // Placeholder avatar (like iOS Contacts)
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                            )

                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(JohoColors.white)
                    }
                }

                // Camera badge (情報デザイン: small circular indicator)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(JohoColors.white)
                            .frame(width: 28, height: 28)
                            .background(accentColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                    }
                }
                .frame(width: 100, height: 100)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let newValue,
                   let data = try? await newValue.loadTransferable(type: Data.self) {
                    // Resize image for storage (max 500px for contacts)
                    if let uiImage = UIImage(data: data) {
                        selectedImageData = resizeImageForContact(uiImage)
                    } else {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    /// Resize image for contact storage (max 500px, JPEG compressed)
    private func resizeImageForContact(_ image: UIImage) -> Data? {
        let maxSize: CGFloat = 500
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.jpegData(compressionQuality: 0.8)
    }

    // MARK: - Name Fields Section

    private var nameFieldsSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // First name (required)
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                JohoPill(text: "FIRST NAME", style: .whiteOnBlack, size: .small)

                TextField("e.g., Emma", text: $firstName)
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }

            // Last name (optional)
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                JohoPill(text: "LAST NAME (OPTIONAL)", style: .whiteOnBlack, size: .small)

                TextField("e.g., Johnson", text: $lastName)
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }
        }
    }

    // MARK: - Company Field Section

    private var companyFieldSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "COMPANY (OPTIONAL)", style: .whiteOnBlack, size: .small)

            TextField("e.g., Acme Inc.", text: $company)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
        }
    }

    // MARK: - Birthday Section

    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Toggle for birthday (in contact mode)
            if mode == .contact {
                HStack {
                    JohoPill(text: "BIRTHDAY", style: .whiteOnBlack, size: .small)
                    Spacer()
                    JohoToggle(isOn: $hasBirthday, accentColor: JohoColors.pink)
                }
            } else {
                JohoPill(text: "BIRTHDAY", style: .whiteOnBlack, size: .small)
            }

            if hasBirthday {
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Year picker
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button {
                                selectedYear = year
                                // Adjust day if Feb 29 in non-leap year
                                let maxDay = daysInMonth(selectedMonth, year: year)
                                if selectedDay > maxDay {
                                    selectedDay = maxDay
                                }
                            } label: {
                                Text(String(year))  // No locale formatting
                            }
                        }
                    } label: {
                        Text(String(selectedYear))  // No locale formatting - years must never have spaces
                            .font(JohoFont.body)
                            .monospacedDigit()
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingSM)
                            .frame(width: 70)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Month picker
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button {
                                selectedMonth = month
                                let maxDay = daysInMonth(month, year: selectedYear)
                                if selectedDay > maxDay {
                                    selectedDay = maxDay
                                }
                            } label: {
                                Text(monthName(month))
                            }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingSM)
                            .frame(minWidth: 60)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Day picker
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                Text("\(day)")
                            }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(JohoFont.body)
                            .monospacedDigit()
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingSM)
                            .frame(width: 50)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    Spacer()
                }

                // Age display
                if let age = calculateAge() {
                    HStack(spacing: JohoDimensions.spacingXS) {
                        Image(systemName: "birthday.cake")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(accentColor)
                        Text("\(age) years old")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                    .padding(.top, JohoDimensions.spacingXS)
                }
            }
        }
    }

    private func calculateAge() -> Int? {
        let calendar = Calendar.current
        guard let birthDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) else {
            return nil
        }
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }

    // MARK: - Phone Field Section

    private var phoneFieldSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "PHONE (OPTIONAL)", style: .whiteOnBlack, size: .small)

            TextField("e.g., +46 70 123 4567", text: $phone)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .keyboardType(.phonePad)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
        }
    }

    // MARK: - Email Field Section

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "EMAIL (OPTIONAL)", style: .whiteOnBlack, size: .small)

            TextField("e.g., emma@example.com", text: $email)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
        }
    }

    // MARK: - Notes Field Section

    private var notesFieldSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "NOTES (OPTIONAL)", style: .whiteOnBlack, size: .small)

            TextEditor(text: $notes)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .frame(height: 80)
                .scrollContentBackground(.hidden)
                .padding(JohoDimensions.spacingSM)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
        }
    }

    // NOTE: JohoToggle is now in JohoDesignSystem.swift

    // MARK: - Helper Functions

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: dateComponents) ?? Date()
        return formatter.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int = 2024) -> Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    private func saveContact() {
        // Create birthday date if enabled (with actual year for age calculation)
        var birthdayDate: Date? = nil
        if hasBirthday {
            let calendar = Calendar.current
            birthdayDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay))
        }

        // Create phone number if provided
        var phoneNumbers: [ContactPhoneNumber] = []
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPhone.isEmpty {
            phoneNumbers.append(ContactPhoneNumber(label: "mobile", value: trimmedPhone))
        }

        // Create email if provided
        var emailAddresses: [ContactEmailAddress] = []
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.isEmpty {
            emailAddresses.append(ContactEmailAddress(label: "home", value: trimmedEmail))
        }

        // Notes
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingContact = existingContact {
            // Update existing contact
            existingContact.givenName = firstName.trimmingCharacters(in: .whitespaces)
            existingContact.familyName = lastName.trimmingCharacters(in: .whitespaces)
            existingContact.organizationName = company.trimmingCharacters(in: .whitespaces).isEmpty ? nil : company.trimmingCharacters(in: .whitespaces)
            existingContact.phoneNumbers = phoneNumbers
            existingContact.emailAddresses = emailAddresses
            existingContact.birthday = birthdayDate
            existingContact.note = trimmedNotes.isEmpty ? nil : trimmedNotes
            existingContact.imageData = selectedImageData  // Save photo (circular)
            existingContact.modifiedAt = Date()
        } else {
            // Create the contact
            let contact = Contact(
                givenName: firstName.trimmingCharacters(in: .whitespaces),
                familyName: lastName.trimmingCharacters(in: .whitespaces),
                organizationName: company.trimmingCharacters(in: .whitespaces).isEmpty ? nil : company.trimmingCharacters(in: .whitespaces),
                phoneNumbers: phoneNumbers,
                emailAddresses: emailAddresses,
                birthday: birthdayDate
            )

            // Set notes if provided
            if !trimmedNotes.isEmpty {
                contact.note = trimmedNotes
            }

            // Set photo if provided (displayed in circular frame)
            contact.imageData = selectedImageData

            // Save to SwiftData
            modelContext.insert(contact)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
    }
}

// MARK: - Convenience Alias

/// Convenience alias for birthday-focused editor (from Special Days page)
typealias JohoBirthdayEditorSheet = JohoContactEditorSheet

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

    // Icon picker
    @State private var selectedSymbol: String
    @State private var showingIconPicker = false

    private let calendar = Calendar.current

    // 情報デザイン: Birthday mode uses pink, Contact mode uses purple
    private var accentColor: Color {
        mode == .birthday ? SpecialDayType.birthday.accentColor : Color(hex: "805AD5")
    }

    private var lightBackground: Color {
        mode == .birthday ? SpecialDayType.birthday.lightBackground : Color(hex: "E9D8FD")
    }

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
            _selectedSymbol = State(initialValue: "person.fill")

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
            _selectedSymbol = State(initialValue: mode == .birthday ? "birthday.cake.fill" : "person.fill")
            // Birthday mode starts with birthday enabled
            _hasBirthday = State(initialValue: mode == .birthday)
        }
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(accentColor)
                            .frame(width: 36, height: 36)
                            .background(lightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEditing ? "EDIT CONTACT" : mode.title.uppercased())
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                            Text(mode == .birthday ? "Track someone's birthday" : "Save contact details")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        saveContact()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(accentColor.opacity(0.7))  // 情報デザイン: Darker header

                // Thick divider after header
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NAME ROW: [●] | First + Last name (no BDY pill - redundant in editor)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Type indicator dot (40pt)
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Name fields side-by-side
                    HStack(spacing: JohoDimensions.spacingSM) {
                        TextField("First name", text: $firstName)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)

                        Text("|")
                            .foregroundStyle(JohoColors.black.opacity(0.3))

                        TextField("Last name", text: $lastName)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(lightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // BIRTHDAY ROW: [🎂] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Birthday cake icon (40pt)
                    Image(systemName: "birthday.cake")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(lightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // ICON PICKER ROW: [icon] | Tap to change icon [>]
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Current icon (40pt)
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(accentColor)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Hint text
                        Text("Tap to change icon")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.leading, JohoDimensions.spacingMD)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                    .frame(height: 48)
                    .background(lightBackground)
                }
                .buttonStyle(.plain)
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: accentColor,
                lightBackground: lightBackground
            )
        }
    }

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

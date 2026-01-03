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
    @State private var showingVCardShare = false
    @State private var vcardURL: URL?

    // 情報デザイン accent color for contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    init(contact: Contact) {
        self.contact = contact
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Hero profile section (horizontal bento: photo left, info right, actions bottom)
                heroAvatarSection

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
        .sheet(isPresented: $showingVCardShare) {
            if let url = vcardURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Hero Profile Section (Japanese-inspired centered layout with 情報デザイン borders)

    private var heroAvatarSection: some View {
        VStack(spacing: 0) {
            // Top section: Centered photo and name (soft purple gradient background)
            VStack(spacing: JohoDimensions.spacingMD) {
                // Large centered avatar with soft shadow
                JohoContactAvatar(contact: contact, size: 100)
                    .shadow(color: JohoColors.black.opacity(0.15), radius: 8, y: 4)

                // Name - large and prominent
                Text(contact.displayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .multilineTextAlignment(.center)

                // Organization subtitle (if any)
                if let org = contact.organizationName, !org.isEmpty {
                    Text(org)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                // Contact info hints row
                HStack(spacing: JohoDimensions.spacingLG) {
                    if let phone = contact.phoneNumbers.first {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(accentColor)
                            Text(phone.value)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                        }
                    }

                    if let email = contact.emailAddresses.first {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(accentColor)
                            Text(email.value)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.vertical, JohoDimensions.spacingLG)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity)
            .background(PageHeaderColor.contacts.lightBackground)

            // Separator line (情報デザイン: solid black)
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Action buttons row - softer pill-style buttons
            HStack(spacing: JohoDimensions.spacingSM) {
                // Call button
                if let phone = contact.phoneNumbers.first {
                    profileActionButton(
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
                    profileActionButton(
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
                    profileActionButton(
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
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    /// Soft pill-style action button for profile card
    @ViewBuilder
    private func profileActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // Removed quickActionsSection - now integrated into heroAvatarSection

    private func formatBirthday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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
        case .contact: return PageHeaderColor.contacts.accent  // Warm Brown 情報デザイン
        }
    }

    var lightBackground: Color {
        switch self {
        case .birthday: return SpecialDayType.birthday.lightBackground
        case .contact: return PageHeaderColor.contacts.lightBackground
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

    // Address fields
    @State private var street: String
    @State private var city: String
    @State private var postalCode: String

    // Birthday fields
    @State private var hasBirthday: Bool
    @State private var birthdayKnown: Bool  // True = known, False = N/A (won't show in Star page)
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Photo picker (circular avatar like iOS Contacts)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // Image cropper state
    @State private var showImageCropper = false
    @State private var tempCropImage: UIImage?
    @State private var cropScale: CGFloat = 1.0
    @State private var cropOffset: CGSize = .zero

    // Icon picker
    @State private var selectedSymbol: String
    @State private var showingIconPicker = false

    private let calendar = Calendar.current

    // 情報デザイン: Use mode's colors (Birthday = pink, Contact = warm brown)
    private var accentColor: Color { mode.accentColor }
    private var lightBackground: Color { mode.lightBackground }

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
            _selectedSymbol = State(initialValue: contact.symbolName ?? (mode == .birthday ? "birthday.cake.fill" : "person.fill"))

            // Address - get first postal address if available
            let firstAddress = contact.postalAddresses.first
            _street = State(initialValue: firstAddress?.street ?? "")
            _city = State(initialValue: firstAddress?.city ?? "")
            _postalCode = State(initialValue: firstAddress?.postalCode ?? "")

            // Birthday with N/A support
            _birthdayKnown = State(initialValue: contact.birthdayKnown)
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
            _street = State(initialValue: "")
            _city = State(initialValue: "")
            _postalCode = State(initialValue: "")
            _selectedImageData = State(initialValue: nil)
            _selectedYear = State(initialValue: 1990)
            _selectedMonth = State(initialValue: calendar.component(.month, from: now))
            _selectedDay = State(initialValue: calendar.component(.day, from: now))
            _selectedSymbol = State(initialValue: mode == .birthday ? "birthday.cake.fill" : "person.fill")
            // Birthday mode starts with birthday enabled and known
            _hasBirthday = State(initialValue: mode == .birthday)
            _birthdayKnown = State(initialValue: true)  // Default: birthday is known if provided
        }
    }

    var body: some View {
        // Elegant minimal profile-style editor (Lala Kudo inspired)
        ScrollView {
            VStack(spacing: 0) {
                // Floating action buttons at top - ○/× (maru-batsu)
                HStack {
                    // × Cancel
                    Button { dismiss() } label: {
                        Text(JohoSymbols.batsu)  // ×
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(Squircle(cornerRadius: JohoDimensions.radiusSmall).stroke(JohoColors.black, lineWidth: 1.5))
                    }

                    Spacer()

                    // ○ Confirm
                    Button {
                        saveContact()
                        dismiss()
                    } label: {
                        Text(JohoSymbols.maru)  // ○
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .background(canSave ? accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(Squircle(cornerRadius: JohoDimensions.radiusSmall).stroke(JohoColors.black, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingLG)

                // Main profile card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Centered photo section
                    VStack(spacing: JohoDimensions.spacingMD) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                                } else {
                                    // Elegant placeholder
                                    Circle()
                                        .fill(JohoColors.black.opacity(0.05))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 28, weight: .medium))
                                                    .foregroundStyle(JohoColors.black.opacity(0.3))
                                                Text("Add Photo")
                                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                                    .foregroundStyle(JohoColors.black.opacity(0.4))
                                            }
                                        )
                                        .overlay(Circle().stroke(JohoColors.black.opacity(0.2), lineWidth: 1.5))
                                }

                                // Small type indicator circle
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                                    .offset(x: 48, y: 48)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task { @MainActor in
                                guard let item = newItem else { return }
                                do {
                                    if let data = try await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        // Show cropper instead of directly setting
                                        tempCropImage = image
                                        cropScale = 1.0
                                        cropOffset = .zero
                                        showImageCropper = true
                                    }
                                } catch {
                                    Log.e("Failed to load photo: \(error)")
                                }
                            }
                        }
                    }

                    // Symbol decoration picker (情報デザイン compliant)
                    symbolDecorationPicker

                    // Name fields - clean and centered
                    VStack(spacing: JohoDimensions.spacingSM) {
                        TextField("First Name", text: $firstName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .multilineTextAlignment(.center)

                        TextField("Last Name", text: $lastName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    // Thin separator
                    Rectangle()
                        .fill(JohoColors.black.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 40)

                    // Form fields - minimal style
                    VStack(spacing: JohoDimensions.spacingMD) {
                        // Company
                        elegantTextField(
                            icon: "building.2",
                            placeholder: "Company",
                            text: $company
                        )

                        // Phone
                        elegantTextField(
                            icon: "phone",
                            placeholder: "Phone",
                            text: $phone
                        )
                        .keyboardType(.phonePad)

                        // Email
                        elegantTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                        // Address section (Lala Kudo: grouped elegantly)
                        VStack(spacing: JohoDimensions.spacingSM) {
                            elegantTextField(
                                icon: "mappin",
                                placeholder: "Street Address",
                                text: $street
                            )

                            HStack(spacing: JohoDimensions.spacingSM) {
                                // City
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    TextField("City", text: $city)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .frame(maxWidth: .infinity)

                                // Postal code
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    TextField("Postal Code", text: $postalCode)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                        .keyboardType(.numbersAndPunctuation)
                                }
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .frame(width: 120)
                            }
                            .padding(.leading, 32) // Align with icon
                        }

                        // Birthday section with N/A option (情報デザイン: data hygiene)
                        VStack(spacing: JohoDimensions.spacingSM) {
                            // Birthday toggle row
                            HStack(spacing: JohoDimensions.spacingSM) {
                                Image(systemName: "birthday.cake")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(birthdayKnown ? SpecialDayType.birthday.accentColor : JohoColors.black.opacity(0.4))
                                    .frame(width: 24)

                                // Three-state toggle: Has birthday / No birthday yet / N/A
                                HStack(spacing: 6) {
                                    // Has birthday
                                    Button {
                                        hasBirthday = true
                                        birthdayKnown = true
                                    } label: {
                                        Text("HAS")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(hasBirthday && birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.5))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(hasBirthday && birthdayKnown ? SpecialDayType.birthday.accentColor : JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }

                                    // Not entered yet (default)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = true
                                    } label: {
                                        Text("NONE")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!hasBirthday && birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.5))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!hasBirthday && birthdayKnown ? JohoColors.black : JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }

                                    // N/A - explicitly unknown (won't show in Star page)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = false
                                    } label: {
                                        Text("N/A")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.5))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!birthdayKnown ? JohoColors.red : JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)

                            // Birthday date picker (only shown when HAS is selected)
                            if hasBirthday && birthdayKnown {
                                HStack(spacing: 8) {
                                    // Year
                                    Menu {
                                        ForEach(yearRange, id: \.self) { year in
                                            Button { selectedYear = year } label: { Text(String(year)) }
                                        }
                                    } label: {
                                        Text(String(selectedYear))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }

                                    // Month
                                    Menu {
                                        ForEach(1...12, id: \.self) { month in
                                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                                        }
                                    } label: {
                                        Text(monthName(selectedMonth))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }

                                    // Day
                                    Menu {
                                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                                            Button { selectedDay = day } label: { Text("\(day)") }
                                        }
                                    } label: {
                                        Text("\(selectedDay)")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(JohoColors.black.opacity(0.05))
                                            .clipShape(Capsule())
                                    }

                                    Spacer()
                                }
                                .padding(.leading, 32)  // Align with icon
                                .padding(.horizontal, JohoDimensions.spacingMD)
                            }

                            // N/A explanation
                            if !birthdayKnown {
                                Text("N/A = Birthday unknown. Won't appear in Star page.")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black.opacity(0.4))
                                    .padding(.leading, 32)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                }
                .padding(.vertical, JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer().frame(height: 40)
            }
        }
        .johoBackground()
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showImageCropper) {
            if let image = tempCropImage {
                CircularImageCropperView(
                    image: image,
                    scale: $cropScale,
                    offset: $cropOffset,
                    onCancel: {
                        showImageCropper = false
                        tempCropImage = nil
                    },
                    onDone: { croppedImage in
                        selectedImageData = croppedImage.jpegData(compressionQuality: 0.8)
                        showImageCropper = false
                        tempCropImage = nil
                    }
                )
            }
        }
    }

    // MARK: - Symbol Decoration Picker
    /// 情報デザイン compliant symbol picker for contact avatars
    private var symbolDecorationPicker: some View {
        Button {
            showingIconPicker = true
            HapticManager.selection()
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Current symbol preview (matches header icon zone pattern)
                Image(systemName: selectedSymbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(lightBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("DECORATION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                    Text("Tap to change icon")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(JohoColors.black.opacity(0.3))
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingIconPicker) {
            ContactSymbolPicker(selectedSymbol: $selectedSymbol, accentColor: accentColor, lightBackground: lightBackground)
        }
    }

    // Elegant minimal text field
    @ViewBuilder
    private func elegantTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.4))
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
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
        if hasBirthday && birthdayKnown {
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

        // Create postal address if any address field is provided
        var postalAddresses: [ContactPostalAddress] = []
        let trimmedStreet = street.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedStreet.isEmpty || !trimmedCity.isEmpty || !trimmedPostalCode.isEmpty {
            postalAddresses.append(ContactPostalAddress(
                label: "home",
                street: trimmedStreet,
                city: trimmedCity,
                postalCode: trimmedPostalCode
            ))
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
            existingContact.postalAddresses = postalAddresses
            existingContact.birthday = birthdayDate
            existingContact.birthdayKnown = birthdayKnown  // Save N/A status
            existingContact.note = trimmedNotes.isEmpty ? nil : trimmedNotes
            existingContact.imageData = selectedImageData  // Save photo (circular)
            existingContact.symbolName = selectedSymbol  // Save decoration symbol
            existingContact.modifiedAt = Date()
        } else {
            // Create the contact
            let contact = Contact(
                givenName: firstName.trimmingCharacters(in: .whitespaces),
                familyName: lastName.trimmingCharacters(in: .whitespaces),
                organizationName: company.trimmingCharacters(in: .whitespaces).isEmpty ? nil : company.trimmingCharacters(in: .whitespaces),
                phoneNumbers: phoneNumbers,
                emailAddresses: emailAddresses,
                postalAddresses: postalAddresses,
                birthday: birthdayDate,
                birthdayKnown: birthdayKnown
            )

            // Set notes if provided
            if !trimmedNotes.isEmpty {
                contact.note = trimmedNotes
            }

            // Set photo if provided (displayed in circular frame)
            contact.imageData = selectedImageData

            // Set decoration symbol
            contact.symbolName = selectedSymbol

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

// MARK: - Circular Image Cropper

/// Full-screen image cropper with pinch-to-zoom and drag-to-pan
struct CircularImageCropperView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let onCancel: () -> Void
    let onDone: (UIImage) -> Void

    // Gesture state
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with Cancel/Done
                HStack {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }

                    Spacer()

                    Text("Move and Scale")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: cropAndSave) {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)

                Spacer()

                // Crop area
                ZStack {
                    // The image (can be zoomed/panned)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: cropSize, height: cropSize)
                        .clipped()

                    // Circular mask overlay
                    CircularMaskOverlay(cropSize: cropSize)
                }
                .frame(width: cropSize, height: cropSize)
                .gesture(dragGesture)
                .gesture(magnificationGesture)

                Spacer()

                // Hint text
                Text("Pinch to zoom • Drag to move")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
                constrainOffset()
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                constrainOffset()
            }
    }

    private func constrainOffset() {
        // Keep image within reasonable bounds
        let maxOffset = cropSize * scale / 2
        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = min(max(offset.width, -maxOffset), maxOffset)
            offset.height = min(max(offset.height, -maxOffset), maxOffset)
            lastOffset = offset
        }
    }

    // MARK: - Crop and Save

    private func cropAndSave() {
        let croppedImage = cropImage()
        onDone(croppedImage)
    }

    private func cropImage() -> UIImage {
        let outputSize: CGFloat = 400 // Output image size

        // Calculate the crop rect
        let imageSize = image.size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // Center of the crop area in image coordinates
        let centerX = scaledImageSize.width / 2 - offset.width * (imageSize.width / cropSize)
        let centerY = scaledImageSize.height / 2 - offset.height * (imageSize.height / cropSize)

        // The visible portion of the image
        let visibleSize = imageSize.width / scale * (cropSize / cropSize)
        let cropRect = CGRect(
            x: (centerX / scale) - (visibleSize / 2),
            y: (centerY / scale) - (visibleSize / 2),
            width: visibleSize,
            height: visibleSize
        )

        // Render the cropped circular image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize))
        return renderer.image { context in
            // Clip to circle
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
            circlePath.addClip()

            // Draw the image scaled and positioned
            let drawRect = CGRect(
                x: -cropRect.origin.x * (outputSize / visibleSize),
                y: -cropRect.origin.y * (outputSize / visibleSize),
                width: imageSize.width * (outputSize / visibleSize),
                height: imageSize.height * (outputSize / visibleSize)
            )
            image.draw(in: drawRect)
        }
    }
}

// MARK: - Circular Mask Overlay

private struct CircularMaskOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        ZStack {
            // Semi-transparent overlay with circular hole
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .mask(
                    ZStack {
                        Rectangle()
                        Circle()
                            .frame(width: cropSize, height: cropSize)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )

            // Circle border
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropSize, height: cropSize)
        }
    }
}

// MARK: - Contact Symbol Picker (情報デザイン Compliant)

/// Symbol picker for contact avatar decorations
/// Selected state: Accent color icon on light background (NOT inverted)
/// Unselected state: Black icon on white background
private struct ContactSymbolPicker: View {
    @Binding var selectedSymbol: String
    let accentColor: Color
    let lightBackground: Color
    @Environment(\.dismiss) private var dismiss

    // Symbol categories for contacts (person-focused)
    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("PEOPLE", ["person.fill", "person.2.fill", "person.3.fill", "figure.stand", "heart.circle.fill", "hand.raised.fill", "hand.wave.fill"]),
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill", "star.fill"]),
        ("EVENTS", ["birthday.cake.fill", "gift.fill", "party.popper.fill", "balloon.fill", "heart.fill", "sparkles", "bell.fill"]),
        ("WORK", ["briefcase.fill", "building.2.fill", "phone.fill", "envelope.fill", "laptopcomputer", "network"]),
        ("NATURE", ["leaf.fill", "sun.max.fill", "moon.fill", "cloud.sun.fill", "flame.fill", "drop.fill", "camera.macro"]),
    ]

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }

                    Spacer()

                    Text("DECORATION")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Spacer()

                    Button { dismiss() } label: {
                        Text("Done")
                            .font(JohoFont.body.bold())
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(accentColor)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)

                // Symbol categories
                ForEach(symbolCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        // Category header
                        Text(category.name)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        // Symbol grid
                        LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                            ForEach(category.symbols, id: \.self) { symbol in
                                Button {
                                    selectedSymbol = symbol
                                    HapticManager.selection()
                                } label: {
                                    let isSelected = selectedSymbol == symbol
                                    Image(systemName: symbol)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(isSelected ? accentColor : JohoColors.black)
                                        .frame(width: 52, height: 52)
                                        .background(isSelected ? lightBackground : JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                                .stroke(JohoColors.black, lineWidth: isSelected ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }
                }
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .background(JohoColors.white)
    }
}

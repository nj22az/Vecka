//
//  ContactDetailView.swift
//  Vecka
//
//  Contact detail view with 情報デザイン (Jōhō Dezain) styling
//  Purple zone - people & connections
//
//  Lock/Unlock inline editing pattern:
//  🔒 Locked = read-only view (default)
//  🔓 Unlocked = edit mode with all fields editable
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - 情報デザイン Contact Detail View

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    let contact: Contact
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // MARK: - Edit Mode (Lock/Unlock)
    @State private var isEditMode = false

    // MARK: - Editable Fields (populated from contact on appear)
    @State private var editFirstName: String = ""
    @State private var editLastName: String = ""
    @State private var editCompany: String = ""
    @State private var editPhone: String = ""
    @State private var editEmail: String = ""
    @State private var editStreet: String = ""
    @State private var editCity: String = ""
    @State private var editPostalCode: String = ""
    @State private var editNotes: String = ""
    @State private var editHasBirthday: Bool = false
    @State private var editBirthdayKnown: Bool = true
    @State private var editYear: Int = 1990
    @State private var editMonth: Int = 1
    @State private var editDay: Int = 1
    @State private var editSymbol: String = "person.fill"
    @State private var editImageData: Data? = nil
    @State private var editGroup: ContactGroup = .other

    // MARK: - Photo Picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    // MARK: - Share
    @State private var showingQRCard = false

    // 情報デザイン accent color for contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }
    private var lightBackground: Color { PageHeaderColor.contacts.lightBackground }

    private let calendar = Calendar.current

    // Year range for birthday picker
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1920...currentYear).reversed())
    }

    init(contact: Contact) {
        self.contact = contact
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Hero profile section with overlaid control buttons
                heroAvatarSection
                    .overlay(alignment: .top) {
                        HStack {
                            closeButton
                            Spacer()
                            if isEditMode {
                                saveButton
                            }
                            lockUnlockButton
                        }
                        .padding(.horizontal, JohoDimensions.spacingSM)
                        .padding(.top, JohoDimensions.spacingSM)
                    }

                if isEditMode {
                    // MARK: Edit Mode — flat red-themed layout
                    editModeContent
                } else {
                    // MARK: View Mode — bento grid layout
                    viewModeContent
                }
            }
            .padding(JohoDimensions.spacingLG)
        }
        .background(isEditMode ? colors.surface : Color.clear)
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingQRCard) {
            VStack(spacing: 0) {
                JohoSheetHeader(
                    title: "CONTACT",
                    shareButton: ContactShareIconButton(contact: contact),
                    onClose: { showingQRCard = false }
                )

                ShareableContactCard(contact: contact)
                    .padding(JohoDimensions.spacingMD)

                Spacer()
            }
            .background(accentColor.opacity(0.3))
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(JohoDimensions.radiusLarge)
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            populateEditFields()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { @MainActor in
                guard let item = newItem else { return }
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        editImageData = image.jpegData(compressionQuality: 0.8)
                    }
                } catch {
                    Log.e("Failed to load photo: \(error)")
                }
            }
        }
    }

    // MARK: - Populate Edit Fields from Contact

    private func populateEditFields() {
        editFirstName = contact.givenName
        editLastName = contact.familyName
        editCompany = contact.organizationName ?? ""
        editPhone = contact.phoneNumbers.first?.value ?? ""
        editEmail = contact.emailAddresses.first?.value ?? ""
        editNotes = contact.note ?? ""
        editImageData = contact.imageData
        editSymbol = contact.symbolName ?? "person.fill"

        // Address
        let firstAddress = contact.postalAddresses.first
        editStreet = firstAddress?.street ?? ""
        editCity = firstAddress?.city ?? ""
        editPostalCode = firstAddress?.postalCode ?? ""

        // Birthday
        editBirthdayKnown = contact.birthdayKnown
        if let birthday = contact.birthday {
            editHasBirthday = true
            editYear = calendar.component(.year, from: birthday)
            editMonth = calendar.component(.month, from: birthday)
            editDay = calendar.component(.day, from: birthday)
        } else {
            editHasBirthday = false
            editYear = 1990
            editMonth = calendar.component(.month, from: Date())
            editDay = calendar.component(.day, from: Date())
        }

        // Group
        editGroup = contact.group
    }

    // MARK: - Edit Mode Content (flat red-themed layout)

    @ViewBuilder
    private var editModeContent: some View {
        if !contact.phoneNumbers.isEmpty || isEditMode {
            phoneSection
        }
        if !contact.emailAddresses.isEmpty || isEditMode {
            emailSection
        }
        if !contact.postalAddresses.isEmpty || isEditMode {
            addressSection
        }
        birthdaySection
        groupSection
        notesSection
    }

    // MARK: - View Mode Content (情報デザイン: bento grid layout)

    @ViewBuilder
    private var viewModeContent: some View {
        let hasPhone = !contact.phoneNumbers.isEmpty
        let hasEmail = !contact.emailAddresses.isEmpty
        let hasAddress = !contact.postalAddresses.isEmpty
        let hasBirthday = contact.birthday != nil
        let hasNotes = contact.note?.isEmpty == false

        // Row 1–2: Phone and Email (full width — action icons need space)
        if hasPhone {
            phoneSection
        }
        if hasEmail {
            emailSection
        }

        // Row 2: Address (full width)
        if hasAddress {
            addressSection
        }

        // Row 3: Birthday + Group side-by-side
        if hasBirthday {
            HStack(alignment: .top, spacing: JohoDimensions.spacingSM) {
                birthdaySection
                groupSection
            }
        } else {
            groupSection
        }

        // Row 4: Notes (full width)
        if hasNotes {
            notesSection
        }

        // Row 5: Share (full width)
        shareActionsSection
    }

    // MARK: - Hero Profile Section (Japanese-inspired centered layout with 情報デザイン borders)

    private var heroAvatarSection: some View {
        VStack(spacing: 0) {
            // Top section: Centered photo and name (soft purple gradient background)
            VStack(spacing: JohoDimensions.spacingMD) {
                // Large centered avatar with soft shadow (tappable in edit mode for photo picker)
                if isEditMode {
                    // Edit mode: PhotosPicker wraps the avatar
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        avatarImage
                            .overlay(
                                // Camera overlay hint
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(colors.primaryInverted)
                                            .frame(width: 28, height: 28)
                                            .background(accentColor)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(colors.primaryInverted, lineWidth: 2))
                                    }
                                }
                            )
                    }
                    .photosPickerStyle(.presentation)
                } else {
                    // View mode: Static avatar
                    avatarImage
                }

                // Name - editable in edit mode
                if isEditMode {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        TextField("First Name", text: $editFirstName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .johoBordered(borderWidth: JohoDimensions.borderThin, borderColor: JohoColors.red.opacity(0.4))

                        TextField("Last Name", text: $editLastName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.red.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .johoBordered(borderWidth: JohoDimensions.borderThin, borderColor: JohoColors.red.opacity(0.4))

                        TextField("Company", text: $editCompany)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.red.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .johoBordered(borderWidth: JohoDimensions.borderThin, borderColor: JohoColors.red.opacity(0.4))
                    }
                } else {
                    // View mode: Display name
                    Text(contact.displayName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)

                    // Organization subtitle (if any)
                    if let org = contact.organizationName, !org.isEmpty {
                        Text(org)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }

                    // Contact info hints row
                    HStack(spacing: JohoDimensions.spacingLG) {
                        if let phone = contact.phoneNumbers.first {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                                Text(phone.value)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                            }
                        }

                        if let email = contact.emailAddresses.first {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                                Text(email.value)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, JohoDimensions.spacingLG)
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity)
            .background(isEditMode ? colors.surface : PageHeaderColor.contacts.lightBackground)

            // Separator line
            Rectangle()
                .fill(isEditMode ? JohoColors.red.opacity(0.3) : colors.border)
                .frame(height: 1.5)

            // 情報デザイン: LINE-style action buttons row (circular icons + labels)
            HStack(spacing: 0) {
                // Message button (cyan)
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

                // Call button (green)
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

                // Video button (purple) - FaceTime
                if let phone = contact.phoneNumbers.first {
                    profileActionButton(
                        icon: "video.fill",
                        label: "VIDEO",
                        color: PageHeaderColor.contacts.accent
                    ) {
                        if let url = URL(string: "facetime:\(phone.value)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Email button (warm brown accent)
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
            .padding(.vertical, JohoDimensions.spacingMD)
            .padding(.horizontal, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: isEditMode ? JohoColors.red.opacity(0.4) : nil)
    }

    /// 情報デザイン: LINE-style action button (circular icon + label below)
    @ViewBuilder
    private func profileActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Circular icon (情報デザイン: 44pt minimum touch target)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                // Label below
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .tracking(0.5)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // Removed quickActionsSection - now integrated into heroAvatarSection

    private func formatBirthday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Phone Section (情報デザイン: white card with header pill)

    @ViewBuilder
    private var phoneSection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("PHONE")
                johoEditField(
                    icon: "phone.fill",
                    iconColor: JohoColors.red,
                    placeholder: "Phone number",
                    text: $editPhone,
                    keyboard: .phonePad
                )
            }
        } else {
            johoDetailSection(title: "PHONE", icon: "phone.fill", iconColor: JohoColors.green) {
                VStack(spacing: 0) {
                    ForEach(Array(contact.phoneNumbers.enumerated()), id: \.element.id) { index, phone in
                        if index > 0 {
                            Rectangle().fill(colors.border.opacity(0.3)).frame(height: 1)
                        }
                        johoInfoRow(
                            label: phone.label.uppercased(),
                            value: phone.value,
                            actions: [
                                ("phone.fill", JohoColors.green, { callPhone(phone.value) }),
                                ("message.fill", JohoColors.cyan, { messagePhone(phone.value) })
                            ]
                        )
                        .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }
            }
        }
    }

    // MARK: - Email Section

    @ViewBuilder
    private var emailSection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("EMAIL")
                johoEditField(
                    icon: "envelope.fill",
                    iconColor: JohoColors.red,
                    placeholder: "Email address",
                    text: $editEmail,
                    keyboard: .emailAddress
                )
            }
        } else {
            johoDetailSection(title: "EMAIL", icon: "envelope.fill", iconColor: accentColor) {
                VStack(spacing: 0) {
                    ForEach(Array(contact.emailAddresses.enumerated()), id: \.element.id) { index, email in
                        if index > 0 {
                            Rectangle().fill(colors.border.opacity(0.3)).frame(height: 1)
                        }
                        johoInfoRow(
                            label: email.label.uppercased(),
                            value: email.value,
                            actions: [
                                ("envelope.fill", accentColor, { sendEmail(email.value) })
                            ]
                        )
                        .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }
            }
        }
    }

    // MARK: - Address Section

    @ViewBuilder
    private var addressSection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("ADDRESS")
                VStack(spacing: JohoDimensions.spacingSM) {
                    johoEditField(
                        icon: "mappin",
                        iconColor: JohoColors.red,
                        placeholder: "Street address",
                        text: $editStreet
                    )

                    HStack(spacing: JohoDimensions.spacingSM) {
                        johoEditField(
                            icon: "building.2.fill",
                            iconColor: JohoColors.red,
                            placeholder: "City",
                            text: $editCity
                        )

                        johoEditField(
                            icon: "number",
                            iconColor: JohoColors.red,
                            placeholder: "Postal",
                            text: $editPostalCode,
                            keyboard: .numbersAndPunctuation
                        )
                        .frame(width: 130)
                    }
                }
            }
        } else {
            johoDetailSection(title: "ADDRESS", icon: "mappin", iconColor: JohoColors.cyan) {
                VStack(spacing: 0) {
                    ForEach(Array(contact.postalAddresses.enumerated()), id: \.element.id) { index, address in
                        if index > 0 {
                            Rectangle().fill(colors.border.opacity(0.3)).frame(height: 1)
                        }
                        HStack(alignment: .top, spacing: JohoDimensions.spacingMD) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.label.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.6))

                                Text(address.formattedAddress)
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.primary)
                            }

                            Spacer()

                            Button {
                                openInMaps(address.formattedAddress)
                            } label: {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(JohoColors.cyan)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, JohoDimensions.spacingSM)
                    }
                }
            }
        }
    }

    // MARK: - Birthday Section

    @ViewBuilder
    private var birthdaySection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("BIRTHDAY")

                // 2-state toggle: YES / NO
                HStack(spacing: 8) {
                    Button {
                        editHasBirthday = true
                        editBirthdayKnown = true
                    } label: {
                        Text("YES")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(editHasBirthday ? colors.surface : JohoColors.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(editHasBirthday ? JohoColors.red : colors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(JohoColors.red, lineWidth: editHasBirthday ? 2.5 : 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        editHasBirthday = false
                        editBirthdayKnown = true
                    } label: {
                        Text("NO")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(!editHasBirthday ? colors.surface : JohoColors.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(!editHasBirthday ? JohoColors.red : colors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(JohoColors.red, lineWidth: !editHasBirthday ? 2.5 : 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                // Date pickers (only if YES selected)
                if editHasBirthday {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(yearRange, id: \.self) { year in
                                Button { editYear = year } label: { Text(String(year)) }
                            }
                        } label: {
                            Text(String(editYear))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(colors.inputBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                        }

                        Menu {
                            ForEach(1...12, id: \.self) { month in
                                Button { editMonth = month } label: { Text(monthName(month)) }
                            }
                        } label: {
                            Text(monthName(editMonth))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(colors.inputBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                        }

                        Menu {
                            ForEach(1...daysInMonth(editMonth, year: editYear), id: \.self) { day in
                                Button { editDay = day } label: { Text("\(day)") }
                            }
                        } label: {
                            Text("\(editDay)")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(colors.inputBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                        }

                        Spacer()
                    }
                }
            }
        } else {
            johoDetailSection(title: "BIRTHDAY", icon: "gift.fill", iconColor: SpecialDayType.birthday.accentColor) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let birthday = contact.birthday {
                            Text(birthday.formatted(.dateTime.year().month(.wide).day()))
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            if let age = calculateAge(from: birthday) {
                                Text("\(age) years old")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(colors.primary.opacity(0.6))
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(SpecialDayType.birthday.accentColor)
                }
            }
        }
    }

    // MARK: - Date Helpers

    private func monthName(_ month: Int) -> String {
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: dateComponents) ?? Date()
        return DateFormatterCache.monthAbbr.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int = 2024) -> Int {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    private func calculateAge(from birthday: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("NOTES")
                TextField("Notes", text: $editNotes, axis: .vertical)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.red)
                    .lineLimit(3...10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .johoBordered(borderWidth: JohoDimensions.borderThin, borderColor: JohoColors.red.opacity(0.4))
            }
        } else {
            johoDetailSection(title: "NOTES", icon: "doc.text", iconColor: JohoColors.yellow) {
                if let note = contact.note, !note.isEmpty {
                    Text(note)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Group Section (情報デザイン: 4-button grid for contact categories)

    @ViewBuilder
    private var groupSection: some View {
        if isEditMode {
            VStack(alignment: .leading, spacing: 6) {
                johoEditSectionLabel("GROUP")
                // Wrapping grid for group selection
                let groups = ContactGroup.allCases
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(groups, id: \.rawValue) { group in
                        let isSelected = editGroup == group

                        Button {
                            editGroup = group
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: group.icon)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? colors.surface : JohoColors.red)

                                Text(group.localizedName)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? colors.surface : JohoColors.red)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? JohoColors.red : colors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(JohoColors.red, lineWidth: isSelected ? 2.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else {
            let groupAccentColor = editGroup.swiftUIColor
            johoDetailSection(title: "GROUP", icon: "folder.fill", iconColor: groupAccentColor) {
                let groupColor = contact.group.swiftUIColor
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: contact.group.icon)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primaryInverted)

                    Text(contact.group.localizedName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primaryInverted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(groupColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
            }
        }
    }

    // MARK: - Share Actions Section

    private var shareActionsSection: some View {
        Button {
            showingQRCard = true
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)

                Text("Share Contact")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)

                Spacer()
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .johoBordered()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Edit Field Helper (情報デザイン: Consistent edit-mode text field)

    @ViewBuilder
    private func johoEditField(
        icon: String,
        iconColor: Color,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(JohoFont.body)
                .foregroundStyle(iconColor)
                .keyboardType(keyboard)
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(borderWidth: JohoDimensions.borderThin, borderColor: iconColor.opacity(0.4))
    }

    // MARK: - Edit Section Label (flat, no card)

    @ViewBuilder
    private func johoEditSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .tracking(1)
            .foregroundStyle(JohoColors.red)
            .padding(.horizontal, JohoDimensions.spacingSM)
    }

    // MARK: - 情報デザイン Section Container (two-compartment bento card)

    @ViewBuilder
    private func johoDetailSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color = JohoColors.purple,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header banner — 情報デザイン: Colored banner with icon zone
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.35))
                    .johoBordered(cornerRadius: 6, borderWidth: 1)

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(colors.primary)

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(iconColor.opacity(0.15))

            // Divider — 情報デザイン: Border between compartments
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Content
            content()
                .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .johoBordered()
    }

    // MARK: - Info Row Helper (情報デザイン: white background with colored action icons)

    @ViewBuilder
    private func johoInfoRow(label: String, value: String, actions: [(String, Color, () -> Void)]) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))

                Text(value)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)
            }

            Spacer()

            HStack(spacing: JohoDimensions.spacingMD) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.2) {
                        Image(systemName: action.0)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(action.1)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Avatar Image (for edit mode preview)

    private var avatarImage: some View {
        Group {
            if let imageData = isEditMode ? editImageData : contact.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 2))
            } else {
                // Placeholder (情報デザイン: solid semantic background)
                Circle()
                    .fill(PageHeaderColor.contacts.lightBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: isEditMode ? editSymbol : (contact.symbolName ?? "person.fill"))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                    )
                    .overlay(Circle().stroke(colors.border, lineWidth: 2))
            }
        }
        .shadow(color: colors.border, radius: 0, x: 2, y: 2)
    }

    // MARK: - Control Buttons

    private var closeButton: some View {
        Button {
            if isEditMode {
                // Cancel edit mode, revert to original values
                populateEditFields()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditMode = false
                }
            } else {
                dismiss()
            }
        } label: {
            // 44pt minimum touch target
            Image(systemName: isEditMode ? "xmark" : "xmark")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .johoTouchTarget()
                .background(colors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(colors.border, lineWidth: 2))
        }
    }

    /// Lock/Unlock toggle button (44pt minimum touch target)
    private var lockUnlockButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditMode.toggle()
            }
            HapticManager.selection()
        } label: {
            Image(systemName: isEditMode ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isEditMode ? colors.surface : colors.primary.opacity(0.6))
                .johoTouchTarget()
                .background(isEditMode ? JohoColors.red : colors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(isEditMode ? JohoColors.red : colors.border, lineWidth: isEditMode ? 2.5 : 1.5))
        }
    }

    /// Save button (only shown in edit mode)
    private var saveButton: some View {
        Button {
            saveContact()
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditMode = false
            }
            HapticManager.notification(.success)
        } label: {
            Text("Save")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(JohoColors.green)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
        }
    }

    // MARK: - Save Contact

    private func saveContact() {
        // Update contact with edited values
        contact.givenName = editFirstName.trimmingCharacters(in: .whitespaces)
        contact.familyName = editLastName.trimmingCharacters(in: .whitespaces)
        contact.organizationName = editCompany.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editCompany.trimmingCharacters(in: .whitespaces)

        // Phone (preserve additional entries from merges)
        let trimmedPhone = editPhone.trimmed
        if !trimmedPhone.isEmpty {
            if contact.phoneNumbers.isEmpty {
                contact.phoneNumbers = [ContactPhoneNumber(label: "mobile", value: trimmedPhone)]
            } else {
                // Update the first entry, keep the rest
                contact.phoneNumbers[0] = ContactPhoneNumber(label: contact.phoneNumbers[0].label, value: trimmedPhone)
            }
        } else if contact.phoneNumbers.count <= 1 {
            contact.phoneNumbers = []
        }

        // Email (preserve additional entries from merges)
        let trimmedEmail = editEmail.trimmed
        if !trimmedEmail.isEmpty {
            if contact.emailAddresses.isEmpty {
                contact.emailAddresses = [ContactEmailAddress(label: "home", value: trimmedEmail)]
            } else {
                contact.emailAddresses[0] = ContactEmailAddress(label: contact.emailAddresses[0].label, value: trimmedEmail)
            }
        } else if contact.emailAddresses.count <= 1 {
            contact.emailAddresses = []
        }

        // Address (preserve additional entries from merges)
        let trimmedStreet = editStreet.trimmed
        let trimmedCity = editCity.trimmed
        let trimmedPostalCode = editPostalCode.trimmed
        if !trimmedStreet.isEmpty || !trimmedCity.isEmpty || !trimmedPostalCode.isEmpty {
            let label = contact.postalAddresses.first?.label ?? "home"
            if contact.postalAddresses.isEmpty {
                contact.postalAddresses = [ContactPostalAddress(
                    label: label,
                    street: trimmedStreet,
                    city: trimmedCity,
                    postalCode: trimmedPostalCode
                )]
            } else {
                contact.postalAddresses[0] = ContactPostalAddress(
                    label: label,
                    street: trimmedStreet,
                    city: trimmedCity,
                    postalCode: trimmedPostalCode
                )
            }
        } else if contact.postalAddresses.count <= 1 {
            contact.postalAddresses = []
        }

        // Birthday
        contact.birthdayKnown = editBirthdayKnown
        if editHasBirthday && editBirthdayKnown {
            contact.birthday = calendar.date(from: DateComponents(year: editYear, month: editMonth, day: editDay))
        } else {
            contact.birthday = nil
        }

        // Notes
        let trimmedNotes = editNotes.trimmed
        contact.note = trimmedNotes.isEmpty ? nil : trimmedNotes

        // Image (this is the key fix - saving directly on the contact)
        contact.imageData = editImageData

        // Symbol
        contact.symbolName = editSymbol

        // Group
        contact.group = editGroup

        // Update timestamp
        contact.modifiedAt = Date()

        // Save to model context
        do {
            try modelContext.save()
            Log.i("Contact saved successfully with image: \(editImageData != nil)")
        } catch {
            Log.e("Failed to save contact: \(error)")
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
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .johoTouchTarget()
                            .background(colors.surface)
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    }

                    Spacer()

                    // ○ Confirm
                    Button {
                        saveContact()
                        dismiss()
                    } label: {
                        Text(JohoSymbols.maru)  // ○
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? colors.primaryInverted : colors.primary.opacity(0.6))
                            .johoTouchTarget()
                            .background(canSave ? accentColor : colors.surface)
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .padding(.bottom, JohoDimensions.spacingLG)

                // Main profile card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Centered photo section
                    VStack(spacing: JohoDimensions.spacingMD) {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            ZStack {
                                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(colors.border, lineWidth: 2))
                                } else {
                                    // Elegant placeholder
                                    Circle()
                                        .fill(colors.inputBackground)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 28, weight: .medium, design: .rounded))
                                                    .foregroundStyle(colors.primary.opacity(0.6))
                                                Text("Add Photo")
                                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                                    .foregroundStyle(colors.primary.opacity(0.6))
                                            }
                                        )
                                        .overlay(Circle().stroke(colors.border, lineWidth: 1))
                                }
                            }
                            .frame(width: 120, height: 120)  // Fixed frame for tap area
                            .contentShape(Circle())  // Ensure proper hit testing area
                        }
                        .photosPickerStyle(.presentation)  // Use presentation style
                        .accessibilityLabel("Select contact photo")
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task { @MainActor in
                                guard let item = newItem else { return }
                                do {
                                    if let data = try await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        selectedImageData = image.jpegData(compressionQuality: 0.8)
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
                            .foregroundStyle(colors.primary)
                            .multilineTextAlignment(.center)

                        TextField("Last Name", text: $lastName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    // Thin separator
                    Rectangle()
                        .fill(colors.border)
                        .frame(height: 0.5)
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
                                        .foregroundStyle(colors.primary)
                                }
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .frame(maxWidth: .infinity)

                                // Postal code
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    TextField("Postal Code", text: $postalCode)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(colors.primary)
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
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(birthdayKnown ? SpecialDayType.birthday.accentColor : colors.primary.opacity(0.6))
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
                                            .foregroundStyle(hasBirthday && birthdayKnown ? colors.primaryInverted : colors.primary.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(hasBirthday && birthdayKnown ? SpecialDayType.birthday.accentColor : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                                    }

                                    // Not entered yet (default)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = true
                                    } label: {
                                        Text("NONE")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!hasBirthday && birthdayKnown ? colors.primaryInverted : colors.primary.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!hasBirthday && birthdayKnown ? colors.primary : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                                    }

                                    // N/A - explicitly unknown (won't show in Star page)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = false
                                    } label: {
                                        Text("N/A")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!birthdayKnown ? colors.primaryInverted : colors.primary.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!birthdayKnown ? JohoColors.red : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)

                            // Birthday date picker (only shown when HAS is selected)
                            // 情報デザイン: solid background + border on all pickers
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
                                            .foregroundStyle(colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                                    }

                                    // Month
                                    Menu {
                                        ForEach(1...12, id: \.self) { month in
                                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                                        }
                                    } label: {
                                        Text(monthName(selectedMonth))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
                                    }

                                    // Day
                                    Menu {
                                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                                            Button { selectedDay = day } label: { Text("\(day)") }
                                        }
                                    } label: {
                                        Text("\(selectedDay)")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(colors.border, lineWidth: 1))
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
                                    .foregroundStyle(colors.primary.opacity(0.6))
                                    .padding(.leading, 32)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                }
                .padding(.vertical, JohoDimensions.spacingLG)
                .background(colors.surface)
                .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick)
                .padding(.horizontal, JohoDimensions.spacingLG)

                Spacer().frame(height: 40)
            }
        }
        .johoBackground()
        .navigationBarHidden(true)
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
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(lightBackground)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

                VStack(alignment: .leading, spacing: 2) {
                    Text("DECORATION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                    Text("Tap to change icon")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))
            }
            .padding(JohoDimensions.spacingMD)
            .background(colors.surface)
            .johoBordered(borderWidth: 1)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingIconPicker) {
            // 情報デザイン: Exclude birthday default icon from picker
            ContactSymbolPicker(
                selectedSymbol: $selectedSymbol,
                accentColor: accentColor,
                lightBackground: lightBackground,
                excludedSymbols: [SpecialDayType.birthday.defaultIcon]
            )
        }
    }

    // Elegant minimal text field
    @ViewBuilder
    private func elegantTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.6))
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - Helper Functions

    private func monthName(_ month: Int) -> String {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: dateComponents) ?? Date()
        return DateFormatterCache.monthAbbr.string(from: tempDate)
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
        let trimmedPhone = phone.trimmed
        if !trimmedPhone.isEmpty {
            phoneNumbers.append(ContactPhoneNumber(label: "mobile", value: trimmedPhone))
        }

        // Create email if provided
        var emailAddresses: [ContactEmailAddress] = []
        let trimmedEmail = email.trimmed
        if !trimmedEmail.isEmpty {
            emailAddresses.append(ContactEmailAddress(label: "home", value: trimmedEmail))
        }

        // Create postal address if any address field is provided
        var postalAddresses: [ContactPostalAddress] = []
        let trimmedStreet = street.trimmed
        let trimmedCity = city.trimmed
        let trimmedPostalCode = postalCode.trimmed
        if !trimmedStreet.isEmpty || !trimmedCity.isEmpty || !trimmedPostalCode.isEmpty {
            postalAddresses.append(ContactPostalAddress(
                label: "home",
                street: trimmedStreet,
                city: trimmedCity,
                postalCode: trimmedPostalCode
            ))
        }

        // Notes
        let trimmedNotes = notes.trimmed

        if let existingContact = existingContact {
            // Update existing contact properties
            existingContact.givenName = firstName.trimmingCharacters(in: .whitespaces)
            existingContact.familyName = lastName.trimmingCharacters(in: .whitespaces)
            existingContact.organizationName = company.trimmingCharacters(in: .whitespaces).isEmpty ? nil : company.trimmingCharacters(in: .whitespaces)
            existingContact.phoneNumbers = phoneNumbers
            existingContact.emailAddresses = emailAddresses
            existingContact.postalAddresses = postalAddresses
            existingContact.birthday = birthdayDate
            existingContact.birthdayKnown = birthdayKnown  // Save N/A status
            existingContact.note = trimmedNotes.isEmpty ? nil : trimmedNotes
            existingContact.imageData = selectedImageData  // Save photo (circular cropped)
            existingContact.symbolName = selectedSymbol  // Save decoration symbol
            existingContact.modifiedAt = Date()

            // CRITICAL: Always use the environment modelContext for saving
            // This ensures changes are properly persisted even when the contact
            // was passed from a parent view into a sheet
            do {
                try modelContext.save()
                Log.i("Contact saved successfully with image: \(selectedImageData != nil)")
            } catch {
                Log.e("Failed to save contact: \(error)")
            }
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
            do {
                try modelContext.save()
            } catch {
                Log.e("Failed to save new contact: \(error)")
            }
        }

        HapticManager.notification(.success)
    }
}

// MARK: - Convenience Alias

/// Convenience alias for birthday-focused editor (from Special Days page)
typealias JohoBirthdayEditorSheet = JohoContactEditorSheet

// MARK: - Contact Symbol Picker (情報デザイン Compliant)

/// Symbol picker for contact avatar decorations
/// Selected state: Accent color icon on light background (NOT inverted)
/// Unselected state: Black icon on white background
private struct ContactSymbolPicker: View {
    @Binding var selectedSymbol: String
    let accentColor: Color
    let lightBackground: Color
    /// 情報デザイン: Icons to exclude from picker (category defaults should not be selectable)
    var excludedSymbols: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Symbol categories for contacts (person-focused)
    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("PEOPLE", ["person.fill", "person.2.fill", "person.3.fill", "figure.stand", "heart.circle.fill", "hand.raised.fill", "hand.wave.fill"]),
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill", "star.fill"]),
        ("EVENTS", ["birthday.cake.fill", "gift.fill", "party.popper.fill", "balloon.fill", "heart.fill", "sparkles", "bell.fill"]),
        ("WORK", ["briefcase.fill", "building.2.fill", "phone.fill", "envelope.fill", "laptopcomputer", "network"]),
        ("NATURE", ["leaf.fill", "sun.max.fill", "moon.fill", "cloud.sun.fill", "flame.fill", "drop.fill", "camera.macro"]),
    ]

    /// 情報デザイン: Filter out excluded symbols (category defaults)
    private var filteredCategories: [(name: String, symbols: [String])] {
        symbolCategories.map { category in
            (name: category.name, symbols: category.symbols.filter { !excludedSymbols.contains($0) })
        }.filter { !$0.symbols.isEmpty }
    }

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    }

                    Spacer()

                    Text("DECORATION")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)

                    Spacer()

                    Button { dismiss() } label: {
                        Text("Done")
                            .font(JohoFont.body.bold())
                            .foregroundStyle(colors.primaryInverted)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(accentColor)
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Symbol categories (情報デザイン: filtered to exclude category defaults)
                ForEach(filteredCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        // Category header
                        Text(category.name)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
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
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? accentColor : colors.primary)
                                        .johoTouchTarget(52)
                                        .background(isSelected ? lightBackground : colors.surface)
                                        .johoBordered(borderWidth: isSelected ? 2 : 1)
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
        .background(colors.surface)
    }
}

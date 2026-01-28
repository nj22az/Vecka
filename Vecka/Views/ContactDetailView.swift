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

    // MARK: - Merge Contact
    @State private var showingMergeContactPicker = false
    @State private var selectedMergeContact: Contact?
    @State private var showingMergeSheet = false

    // MARK: - Photo Picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var cropImageItem: CropImageItem?
    @State private var cropScale: CGFloat = 1.0
    @State private var cropOffset: CGSize = .zero

    // MARK: - Share
    @State private var showingVCardShare = false
    @State private var vcardURL: URL?

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
                // 情報デザイン: Status bar safe zone - prevents content from scrolling under status bar icons
                Spacer().frame(height: 44)

                // EDIT MODE indicator (情報デザイン: prominent when unlocked)
                if isEditMode {
                    editModeIndicator
                }

                // Hero profile section (horizontal bento: photo left, info right, actions bottom)
                heroAvatarSection

                // Phone section (edit mode shows editable field)
                if isEditMode || !contact.phoneNumbers.isEmpty {
                    phoneSection
                }

                // Email section
                if isEditMode || !contact.emailAddresses.isEmpty {
                    emailSection
                }

                // Social links section (情報デザイン: LINE-style social profiles)
                if !contact.socialProfiles.isEmpty {
                    socialLinksSection
                }

                // Address section
                if isEditMode || !contact.postalAddresses.isEmpty {
                    addressSection
                }

                // Birthday section
                if isEditMode || contact.birthday != nil {
                    birthdaySection
                }

                // Group section (情報デザイン: Always visible - defines contact category)
                groupSection

                // Notes section
                if isEditMode || (contact.note?.isEmpty == false) {
                    notesSection
                }

                // Share actions section (only in view mode)
                if !isEditMode {
                    shareActionsSection
                }
            }
            .padding(JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            // Header with close and lock/unlock buttons
            HStack {
                closeButton
                Spacer()
                if isEditMode {
                    saveButton
                }
                lockUnlockButton
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingSM)
        }
        .sheet(isPresented: $showingVCardShare) {
            if let url = vcardURL {
                ShareSheet(url: url)
            }
        }
        .fullScreenCover(item: $cropImageItem) { item in
            CircularImageCropperView(
                image: item.image,
                scale: $cropScale,
                offset: $cropOffset,
                onCancel: { cropImageItem = nil },
                onDone: { croppedImage in
                    editImageData = croppedImage.jpegData(compressionQuality: 0.8)
                    cropImageItem = nil
                }
            )
        }
        .sheet(isPresented: $showingMergeContactPicker) {
            // Contact picker for manual merge (excludes current contact)
            ContactPickerSheet(
                excludeContact: contact,
                onSelect: { selectedContact in
                    selectedMergeContact = selectedContact
                    showingMergeContactPicker = false
                    // Slight delay to let sheet dismiss before showing merge
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingMergeSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingMergeSheet) {
            if let mergeTarget = selectedMergeContact {
                // Use existing MergeContactSheet with current + selected contact
                ManualMergeSheet(
                    contact1: contact,
                    contact2: mergeTarget,
                    onMerged: {
                        // Contact merged - dismiss detail view
                        dismiss()
                    }
                )
            }
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
                        cropScale = 1.0
                        cropOffset = .zero
                        cropImageItem = CropImageItem(image: image)
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

    // MARK: - EDIT MODE Indicator (情報デザイン: Prominent banner with black border)

    private var editModeIndicator: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // 情報デザイン: Edit icon in colored zone
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .frame(width: 28, height: 28)
                .background(accentColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

            // Title pill (情報デザイン: BLACK on WHITE = prominent)
            Text("EDIT MODE")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))

            Spacer()

            Text("Tap → to save")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .padding(JohoDimensions.spacingMD)
        .background(lightBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
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
                                            .foregroundStyle(JohoColors.white)
                                            .frame(width: 28, height: 28)
                                            .background(accentColor)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(JohoColors.white, lineWidth: 2))
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
                            .foregroundStyle(JohoColors.black)
                            .multilineTextAlignment(.center)

                        TextField("Last Name", text: $editLastName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.7))
                            .multilineTextAlignment(.center)

                        TextField("Company", text: $editCompany)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .multilineTextAlignment(.center)
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
            .background(PageHeaderColor.contacts.lightBackground)
            .opacity(isEditMode ? 1.0 : 1.0)  // Full opacity always (can adjust if needed)

            // Separator line
            Rectangle()
                .fill(colors.border)
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
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
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
                    .foregroundStyle(JohoColors.black)
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

    private var phoneSection: some View {
        johoDetailSection(title: "PHONE", icon: "phone.fill", iconColor: JohoColors.green) {
            if isEditMode {
                // Edit mode: editable text field
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.green)
                        .frame(width: 24)

                    TextField("Phone number", text: $editPhone)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .keyboardType(.phonePad)
                }
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                )
            } else {
                // View mode: display with action buttons
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
    }

    // MARK: - Email Section

    private var emailSection: some View {
        johoDetailSection(title: "EMAIL", icon: "envelope.fill", iconColor: accentColor) {
            if isEditMode {
                // Edit mode: editable text field
                HStack(spacing: JohoDimensions.spacingMD) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .frame(width: 24)

                    TextField("Email address", text: $editEmail)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(JohoDimensions.spacingMD)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                )
            } else {
                // View mode
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
    }

    // MARK: - Social Links Section (情報デザイン: LINE-style social profiles)

    private var socialLinksSection: some View {
        johoDetailSection(title: "SOCIAL", icon: "link", iconColor: PageHeaderColor.contacts.accent) {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(contact.socialProfiles, id: \.id) { profile in
                    Button {
                        // Open the profile URL or construct one
                        if let urlString = profile.url, let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        } else {
                            // Construct URL based on service
                            let url = constructSocialURL(service: profile.service, username: profile.username)
                            if let url = url {
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        socialProfileRow(profile: profile)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// 情報デザイン: Social profile row with service icon and username
    @ViewBuilder
    private func socialProfileRow(profile: ContactSocialProfile) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Service icon in colored zone
            Image(systemName: socialServiceIcon(for: profile.service))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(socialServiceColor(for: profile.service))
                .frame(width: 32, height: 32)
                .background(colors.inputBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: 1)
                )

            // Service name + username
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.service.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Text("@\(profile.username)")
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
            }

            Spacer()

            // External link indicator
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: 1)
        )
    }

    /// Get appropriate icon for social service
    private func socialServiceIcon(for service: String) -> String {
        switch service.lowercased() {
        case "twitter", "x": return "at"
        case "instagram": return "camera.fill"
        case "facebook": return "person.2.fill"
        case "linkedin": return "briefcase.fill"
        case "tiktok": return "music.note"
        case "youtube": return "play.rectangle.fill"
        case "snapchat": return "camera.viewfinder"
        case "pinterest": return "pin.fill"
        case "tumblr": return "text.quote"
        case "reddit": return "bubble.left.and.bubble.right.fill"
        case "github": return "chevron.left.forwardslash.chevron.right"
        case "mastodon": return "text.bubble.fill"
        default: return "link"
        }
    }

    /// Get semantic color for social service
    private func socialServiceColor(for service: String) -> Color {
        switch service.lowercased() {
        case "twitter", "x": return JohoColors.cyan
        case "instagram": return Color(hex: "#E1306C")  // Instagram pink
        case "facebook": return Color(hex: "#1877F2")   // Facebook blue
        case "linkedin": return Color(hex: "#0A66C2")   // LinkedIn blue
        case "tiktok": return JohoColors.black
        case "youtube": return Color(hex: "#FF0000")    // YouTube red
        case "snapchat": return JohoColors.yellow
        case "github": return JohoColors.black
        default: return PageHeaderColor.contacts.accent
        }
    }

    /// Construct URL for social service if not provided
    private func constructSocialURL(service: String, username: String) -> URL? {
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
        switch service.lowercased() {
        case "twitter", "x": return URL(string: "https://twitter.com/\(cleanUsername)")
        case "instagram": return URL(string: "https://instagram.com/\(cleanUsername)")
        case "facebook": return URL(string: "https://facebook.com/\(cleanUsername)")
        case "linkedin": return URL(string: "https://linkedin.com/in/\(cleanUsername)")
        case "tiktok": return URL(string: "https://tiktok.com/@\(cleanUsername)")
        case "youtube": return URL(string: "https://youtube.com/@\(cleanUsername)")
        case "github": return URL(string: "https://github.com/\(cleanUsername)")
        default: return nil
        }
    }

    // MARK: - Address Section

    private var addressSection: some View {
        johoDetailSection(title: "ADDRESS", icon: "mappin", iconColor: JohoColors.cyan) {
            if isEditMode {
                // Edit mode: editable address fields
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Street
                    HStack(spacing: JohoDimensions.spacingMD) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.cyan)
                            .frame(width: 24)

                        TextField("Street address", text: $editStreet)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                    // City + Postal code row
                    HStack(spacing: JohoDimensions.spacingSM) {
                        TextField("City", text: $editCity)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                            )

                        TextField("Postal", text: $editPostalCode)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(JohoDimensions.spacingMD)
                            .frame(width: 100)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                            )
                    }
                }
            } else {
                // View mode
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(contact.postalAddresses, id: \.id) { address in
                        HStack(alignment: .top, spacing: JohoDimensions.spacingMD) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.label.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.6))

                                Text(address.formattedAddress)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black)
                            }

                            Spacer()

                            // Open in Maps (情報デザイン: 44pt minimum touch target)
                            Button {
                                openInMaps(address.formattedAddress)
                            } label: {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(JohoColors.cyan)
                                    .johoTouchTarget()
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
    }

    // MARK: - Birthday Section

    private var birthdaySection: some View {
        johoDetailSection(title: "BIRTHDAY", icon: "gift.fill", iconColor: SpecialDayType.birthday.accentColor) {
            if isEditMode {
                // Edit mode: birthday toggle and date picker
                VStack(spacing: JohoDimensions.spacingSM) {
                    // 情報デザイン: マルバツ記号 (Maru-Batsu) toggle
                    // ○ = HAS (positive/yes)  × = NONE (negative/no)  ー = N/A (not applicable)
                    HStack(spacing: 8) {
                        // ○ HAS birthday (Maru = positive/yes)
                        Button {
                            editHasBirthday = true
                            editBirthdayKnown = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("○")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                Text("HAS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(editHasBirthday && editBirthdayKnown ? JohoColors.white : JohoColors.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(editHasBirthday && editBirthdayKnown ? SpecialDayType.birthday.accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(
                                Squircle(cornerRadius: 8)
                                    .stroke(JohoColors.black, lineWidth: editHasBirthday && editBirthdayKnown ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // × NONE (Batsu = negative/no)
                        Button {
                            editHasBirthday = false
                            editBirthdayKnown = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("×")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                Text("NONE")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(!editHasBirthday && editBirthdayKnown ? JohoColors.white : JohoColors.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(!editHasBirthday && editBirthdayKnown ? JohoColors.black : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(
                                Squircle(cornerRadius: 8)
                                    .stroke(JohoColors.black, lineWidth: !editHasBirthday && editBirthdayKnown ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // ー N/A (Bō = not applicable)
                        Button {
                            editHasBirthday = false
                            editBirthdayKnown = false
                        } label: {
                            HStack(spacing: 6) {
                                Text("ー")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                Text("N/A")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(!editBirthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(!editBirthdayKnown ? JohoColors.black.opacity(0.6) : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(
                                Squircle(cornerRadius: 8)
                                    .stroke(JohoColors.black, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )

                    // Date pickers (only if HAS selected)
                    if editHasBirthday && editBirthdayKnown {
                        HStack(spacing: 8) {
                            // Year (情報デザイン: solid background + border)
                            Menu {
                                ForEach(yearRange, id: \.self) { year in
                                    Button { editYear = year } label: { Text(String(year)) }
                                }
                            } label: {
                                Text(String(editYear))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(colors.inputBackground)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                            }

                            // Month (情報デザイン: solid background + border)
                            Menu {
                                ForEach(1...12, id: \.self) { month in
                                    Button { editMonth = month } label: { Text(monthName(month)) }
                                }
                            } label: {
                                Text(monthName(editMonth))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(colors.inputBackground)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                            }

                            // Day (情報デザイン: solid background + border)
                            Menu {
                                ForEach(1...daysInMonth(editMonth, year: editYear), id: \.self) { day in
                                    Button { editDay = day } label: { Text("\(day)") }
                                }
                            } label: {
                                Text("\(editDay)")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(JohoColors.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(colors.inputBackground)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                        )
                    }

                    // N/A explanation (情報デザイン: minimum 0.6 opacity)
                    if !editBirthdayKnown {
                        Text("N/A = Birthday unknown. Won't appear in Star page.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            } else {
                // View mode
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
                                    .foregroundStyle(colors.primary.opacity(0.6))
                            }
                        }
                    }

                    Spacer()

                    // Birthday cake icon
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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
    }

    // MARK: - Date Helpers

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: dateComponents) ?? Date()
        return formatter.string(from: tempDate)
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

    private var notesSection: some View {
        johoDetailSection(title: "NOTES", icon: "doc.text", iconColor: JohoColors.yellow) {
            if isEditMode {
                // Edit mode: multiline text editor
                TextField("Notes", text: $editNotes, axis: .vertical)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(3...10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )
            } else {
                // View mode
                if let note = contact.note, !note.isEmpty {
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
        }
    }

    // MARK: - Group Section (情報デザイン: 4-button grid for contact categories)

    private var groupSection: some View {
        let groupAccentColor = Color(hex: editGroup.color)

        return johoDetailSection(title: "GROUP", icon: "folder.fill", iconColor: groupAccentColor) {
            if isEditMode {
                // Edit mode: 4-button grid for group selection
                let groups = ContactGroup.allCases
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(groups, id: \.rawValue) { group in
                        let isSelected = editGroup == group
                        let groupColor = Color(hex: group.color)

                        Button {
                            editGroup = group
                        } label: {
                            VStack(spacing: 4) {
                                // Icon
                                Image(systemName: group.icon)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(JohoColors.black)

                                // Label
                                Text(group.localizedName)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(JohoColors.black)
                                    .lineLimit(1)

                                // Selection indicator
                                Circle()
                                    .fill(isSelected ? JohoColors.black : colors.inputBackground)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isSelected ? groupColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 10))
                            .overlay(
                                Squircle(cornerRadius: 10)
                                    .stroke(JohoColors.black, lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // View mode: Show current group as a pill
                let groupColor = Color(hex: contact.group.color)
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: contact.group.icon)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text(contact.group.localizedName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(groupColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
            }
        }
    }

    // MARK: - Share Actions Section

    private var shareActionsSection: some View {
        johoDetailSection(title: "SHARE", icon: "square.and.arrow.up", iconColor: accentColor) {
            VStack(spacing: JohoDimensions.spacingSM) {
                // Share as PNG with embedded QR code (情報デザイン: Like RandomFact sharing)
                if #available(iOS 16.0, *) {
                    ShareLink(
                        item: ShareableContactSnapshot(
                            contact: contact,
                            size: ShareableContactSnapshot.calculateSize(for: contact)
                        ),
                        preview: SharePreview(
                            contact.displayName,
                            image: Image(systemName: contact.group.icon)
                        )
                    ) {
                        johoActionRow(icon: "photo", title: "Share as Image")
                    }
                    .buttonStyle(.plain)
                }

                // Export to iOS Contacts
                Button {
                    exportToIOSContacts()
                } label: {
                    johoActionRow(icon: "person.badge.plus", title: "Export to iOS Contacts")
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 4)

                // Manual Merge (情報デザイン: User-initiated merge for contacts system didn't detect)
                Button {
                    showingMergeContactPicker = true
                } label: {
                    johoActionRow(icon: "arrow.triangle.merge", title: "Merge with another contact...")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 情報デザイン Section Container (white card with colored icon zone)

    @ViewBuilder
    private func johoDetailSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color = Color(hex: "805AD5"),
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Header row with colored icon zone + title pill (情報デザイン: color in icon zone only)
            HStack(spacing: JohoDimensions.spacingSM) {
                // Colored icon zone (情報デザイン: solid background)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(colors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: 1)
                    )

                JohoPill(text: title, style: .whiteOnBlack, size: .medium)

                Spacer()
            }

            // Content
            content()
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    @ViewBuilder
    private func johoActionRow(icon: String, title: String, color: Color? = nil) -> some View {
        let rowColor = color ?? accentColor
        HStack(spacing: JohoDimensions.spacingMD) {
            // Colored icon zone (情報デザイン: solid background)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(rowColor)
                .frame(width: 36, height: 36)
                .background(colors.inputBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: 1.5)
                )

            Text(title)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
        )
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

            // Action buttons with semantic colors (情報デザイン: 44pt minimum touch targets)
            HStack(spacing: JohoDimensions.spacingSM) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.2) {
                        Image(systemName: action.0)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(action.1)
                            .johoTouchTarget()
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
        )
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
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
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
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
            }
        }
        .shadow(color: JohoColors.black, radius: 0, x: 2, y: 2)
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
                .foregroundStyle(isEditMode ? JohoColors.white : colors.primary.opacity(0.6))
                .johoTouchTarget()
                .background(isEditMode ? accentColor : colors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(colors.border, lineWidth: isEditMode ? 2.5 : 1.5))
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
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(JohoColors.green)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
        }
    }

    // MARK: - Save Contact

    private func saveContact() {
        // Update contact with edited values
        contact.givenName = editFirstName.trimmingCharacters(in: .whitespaces)
        contact.familyName = editLastName.trimmingCharacters(in: .whitespaces)
        contact.organizationName = editCompany.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editCompany.trimmingCharacters(in: .whitespaces)

        // Phone
        let trimmedPhone = editPhone.trimmed
        if !trimmedPhone.isEmpty {
            contact.phoneNumbers = [ContactPhoneNumber(label: "mobile", value: trimmedPhone)]
        } else {
            contact.phoneNumbers = []
        }

        // Email
        let trimmedEmail = editEmail.trimmed
        if !trimmedEmail.isEmpty {
            contact.emailAddresses = [ContactEmailAddress(label: "home", value: trimmedEmail)]
        } else {
            contact.emailAddresses = []
        }

        // Address
        let trimmedStreet = editStreet.trimmed
        let trimmedCity = editCity.trimmed
        let trimmedPostalCode = editPostalCode.trimmed
        if !trimmedStreet.isEmpty || !trimmedCity.isEmpty || !trimmedPostalCode.isEmpty {
            contact.postalAddresses = [ContactPostalAddress(
                label: "home",
                street: trimmedStreet,
                city: trimmedCity,
                postalCode: trimmedPostalCode
            )]
        } else {
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

    private func generateAndShareVCard() {
        let vcard = contact.toVCard()
        let tempDir = FileManager.default.temporaryDirectory

        // Sanitize filename: remove characters that are invalid for file systems
        let sanitizedName = contact.displayName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "-")
            .trimmed

        let filename = (sanitizedName.isEmpty ? "Contact" : sanitizedName) + ".vcf"
        let url = tempDir.appendingPathComponent(filename)

        do {
            try vcard.write(to: url, atomically: true, encoding: .utf8)
            vcardURL = url
            showingVCardShare = true
            HapticManager.selection()  // 情報デザイン: Tactile confirmation
        } catch {
            Log.e("Failed to create vCard file: \(error)")
            HapticManager.notification(.error)
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

    // Image cropper state - using Identifiable wrapper for reliable fullScreenCover
    @State private var cropImageItem: CropImageItem?
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
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .johoTouchTarget()
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
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.6))
                            .johoTouchTarget()
                            .background(canSave ? accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(Squircle(cornerRadius: JohoDimensions.radiusSmall).stroke(JohoColors.black, lineWidth: 1.5))
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
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
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
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
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
                                        // Show cropper using item-based presentation (more reliable)
                                        cropScale = 1.0
                                        cropOffset = .zero
                                        cropImageItem = CropImageItem(image: image)
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
                            .foregroundStyle(colors.primary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    // Thin separator
                    Rectangle()
                        .fill(JohoColors.black)
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
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(birthdayKnown ? SpecialDayType.birthday.accentColor : JohoColors.black.opacity(0.6))
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
                                            .foregroundStyle(hasBirthday && birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(hasBirthday && birthdayKnown ? SpecialDayType.birthday.accentColor : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                                    }

                                    // Not entered yet (default)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = true
                                    } label: {
                                        Text("NONE")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!hasBirthday && birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!hasBirthday && birthdayKnown ? JohoColors.black : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                                    }

                                    // N/A - explicitly unknown (won't show in Star page)
                                    Button {
                                        hasBirthday = false
                                        birthdayKnown = false
                                    } label: {
                                        Text("N/A")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(!birthdayKnown ? JohoColors.white : JohoColors.black.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(!birthdayKnown ? JohoColors.red : colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
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
                                            .foregroundStyle(JohoColors.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
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
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
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
                                            .background(colors.inputBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
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
        .fullScreenCover(item: $cropImageItem) { item in
            CircularImageCropperView(
                image: item.image,
                scale: $cropScale,
                offset: $cropOffset,
                onCancel: {
                    cropImageItem = nil
                },
                onDone: { croppedImage in
                    selectedImageData = croppedImage.jpegData(compressionQuality: 0.8)
                    cropImageItem = nil
                }
            )
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
                    .font(.system(size: 18, weight: .bold, design: .rounded))
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
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                    Text("Tap to change icon")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: 1)
            )
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
                .foregroundStyle(JohoColors.black.opacity(0.6))
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

// MARK: - Crop Image Item (Identifiable wrapper for fullScreenCover)

/// Wrapper to make UIImage work with item-based fullScreenCover presentation
struct CropImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

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
                // Top bar with title only
                Text("Move and Scale")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 8)  // 情報デザイン: Max 8pt top padding
                    .padding(.bottom, 8)

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
                    .padding(.bottom, 24)

                // Cancel/Done buttons below photo (情報デザイン マルバツ style)
                HStack(spacing: 20) {
                    // × Cancel (Batsu = No/Wrong)
                    Button(action: onCancel) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(JohoColors.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(JohoColors.black, lineWidth: 2)
                        )
                    }

                    // ○ Done (Maru = Yes/Correct)
                    Button(action: cropAndSave) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Done")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(JohoColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(JohoColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
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
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingSM)
                            .background(colors.surface)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: 1.5)
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
                .padding(.top, JohoDimensions.spacingSM)

                // Symbol categories (情報デザイン: filtered to exclude category defaults)
                ForEach(filteredCategories, id: \.name) { category in
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
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? accentColor : JohoColors.black)
                                        .johoTouchTarget(52)
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

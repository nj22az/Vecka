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
    @Environment(\.johoColorMode) private var colorMode
    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    private var contactsManager = ContactsManager.shared
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var showingImportSheet = false
    @State private var showingContactPicker = false
    @State private var selectedContact: Contact?
    @State private var editingContact: Contact?
    @State private var showingDuplicateReview = false
    @State private var duplicateSuggestionCount = 0
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var isEditMode = false  // 情報デザイン: Edit mode for contact management
    @State private var selectedForDeletion: Set<UUID> = []  // Multi-select for bulk delete

    // 情報デザイン: Cached computed properties to prevent recalculation on every render
    @State private var cachedFilteredContacts: [Contact] = []
    @State private var cachedGroupedContacts: [String: [Contact]] = [:]
    @State private var cachedAvailableLetters: [String] = []
    @State private var cachedSortedSections: [String] = []

    // Duplicate detection manager
    private let duplicateManager = DuplicateContactManager.shared

    // 情報デザイン accent color for Contacts (Warm Brown - from PageHeaderColor)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    // Stats for header subtitle
    private var contactsWithPhone: Int {
        contacts.filter { $0.phoneNumbers.isNotEmpty }.count
    }
    private var contactsWithEmail: Int {
        contacts.filter { $0.emailAddresses.isNotEmpty }.count
    }
    private var contactsWithBirthday: Int {
        contacts.filter { $0.birthday != nil }.count
    }

    // 情報デザイン: Computed properties now return cached values to prevent freezing
    var filteredContacts: [Contact] { cachedFilteredContacts }
    var groupedContacts: [String: [Contact]] { cachedGroupedContacts }
    var sortedSections: [String] { cachedSortedSections }
    var allAvailableLetters: [String] { cachedAvailableLetters }

    // MARK: - Cache Management (情報デザイン: Memoization for performance)

    /// Rebuilds all contact caches - call when filters or data change
    private func refreshContactCache() {
        // Step 1: Build filtered contacts
        var result = contacts

        // Filter by search text
        if searchText.isNotEmpty {
            result = result.filter { contact in
                contact.displayName.localizedCaseInsensitiveContains(searchText) ||
                contact.organizationName?.localizedCaseInsensitiveContains(searchText) == true ||
                contact.emailAddresses.contains { $0.value.localizedCaseInsensitiveContains(searchText) } ||
                contact.phoneNumbers.contains { $0.value.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // 情報デザイン: Filter by selected group (Family/Friends/Work/Other)
        if let group = selectedGroup {
            result = result.filter { $0.group == group }
        }

        // 情報デザイン: Filter by selected letter (show one group at a time)
        if let letter = filterLetter {
            result = result.filter { contact in
                let firstLetter = contact.familyName.isEmpty ?
                    (contact.givenName.isEmpty ? "#" : String(contact.givenName.prefix(1).uppercased())) :
                    String(contact.familyName.prefix(1).uppercased())
                return firstLetter.uppercased() == letter
            }
        }

        cachedFilteredContacts = result

        // Step 2: Build grouped contacts from filtered
        let grouped = Dictionary(grouping: result) { contact in
            let firstLetter = contact.familyName.isEmpty ?
                (contact.givenName.isEmpty ? "#" : String(contact.givenName.prefix(1).uppercased())) :
                String(contact.familyName.prefix(1).uppercased())
            return firstLetter.uppercased()
        }
        cachedGroupedContacts = grouped

        // Step 3: Build sorted sections
        cachedSortedSections = grouped.keys.sorted()

        // Step 4: Build all available letters (from unfiltered contacts)
        let allGrouped = Dictionary(grouping: contacts) { contact in
            let firstLetter = contact.familyName.isEmpty ?
                (contact.givenName.isEmpty ? "#" : String(contact.givenName.prefix(1).uppercased())) :
                String(contact.familyName.prefix(1).uppercased())
            return firstLetter.uppercased()
        }
        cachedAvailableLetters = allGrouped.keys.sorted()
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
                    // Search field row (unified component)
                    JohoSearchField(text: $searchText, placeholder: "Search contacts")
                        .padding(.horizontal, JohoDimensions.spacingXS)
                        .padding(.vertical, JohoDimensions.spacingSM)

                    // Horizontal divider
                    Rectangle()
                        .fill(colors.border)
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
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
        .sheet(isPresented: $showingExportSheet) {
            ContactExportSheet(contacts: contacts)
        }
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .onAppear {
            loadDuplicateSuggestions()
            refreshContactCache()  // 情報デザイン: Initialize cache on appear
        }
        .onChange(of: contacts.count) { _, _ in
            // Rescan when contacts change
            refreshContactCache()  // 情報デザイン: Rebuild cache when contacts change
            Task { @MainActor in
                await duplicateManager.scanForDuplicates(contacts: contacts, modelContext: modelContext)
                loadDuplicateSuggestions()
            }
        }
        .onChange(of: searchText) { _, _ in
            refreshContactCache()  // 情報デザイン: Rebuild cache when search changes
        }
        .onChange(of: selectedGroup) { _, _ in
            refreshContactCache()  // 情報デザイン: Rebuild cache when group filter changes
        }
        .onChange(of: filterLetter) { _, _ in
            refreshContactCache()  // 情報デザイン: Rebuild cache when letter filter changes
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
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(PageHeaderColor.contacts.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.contacts.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                    Text("CONTACTS")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Edit mode controls OR Export/Import buttons
                HStack(spacing: 0) {
                    if isEditMode {
                        // Delete selected button (red when items selected)
                        if selectedForDeletion.isNotEmpty {
                            Button {
                                deleteSelectedContacts()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                    Text("\(selectedForDeletion.count)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(colors.primaryInverted)
                                .frame(height: 32)
                                .padding(.horizontal, 12)
                                .background(JohoColors.red)
                                .clipShape(Squircle(cornerRadius: 8))
                                .overlay(
                                    Squircle(cornerRadius: 8)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                        }

                        // Done button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditMode = false
                                selectedForDeletion.removeAll()
                            }
                        } label: {
                            Text("Done")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primaryInverted)
                                .frame(height: 32)
                                .padding(.horizontal, 12)
                                .background(PageHeaderColor.contacts.accent)
                                .clipShape(Squircle(cornerRadius: 8))
                                .overlay(
                                    Squircle(cornerRadius: 8)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Edit button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditMode = true
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(PageHeaderColor.contacts.accent)
                                .johoTouchTarget()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(contacts.isEmpty)
                        .opacity(contacts.isEmpty ? 0.3 : 1.0)

                        // Thin separator (情報デザイン: solid black, reduced height)
                        Rectangle()
                            .fill(colors.border)
                            .frame(width: 0.5)
                            .padding(.vertical, 8)

                        // Export button
                        Button {
                            showingExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(PageHeaderColor.contacts.accent)
                                .johoTouchTarget()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Thin separator (情報デザイン: solid black, reduced height)
                        Rectangle()
                            .fill(colors.border)
                            .frame(width: 0.5)
                            .padding(.vertical, 8)

                        // Import button
                        Button {
                            showingImportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(PageHeaderColor.contacts.accent)
                                .johoTouchTarget()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingXS)
            }
            .frame(minHeight: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // STATS ROW: 情報デザイン - clean summary without redundant orbs
            HStack(spacing: JohoDimensions.spacingMD) {
                // Total count only (no orb - the number speaks for itself)
                Text("\(contacts.count) contacts")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary.opacity(0.7))

                // Phone count with icon
                if contactsWithPhone > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.cyan)
                        Text("\(contactsWithPhone)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.primary.opacity(0.7))
                    }
                }

                // Birthday count with icon
                if contactsWithBirthday > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SpecialDayType.birthday.accentColor)
                        Text("\(contactsWithBirthday)")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.primary.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Empty State (情報デザイン: Black text in white container)

    private var contactsEmptyState: some View {
        VStack(spacing: JohoDimensions.spacingLG) {
            Spacer()
                .frame(height: JohoDimensions.spacingXL)

            // Icon in bordered box
            Image(systemName: "person.2.fill")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .frame(width: 80, height: 80)
                .background(PageHeaderColor.contacts.lightBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: 2)
                )

            // Title and subtitle
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("NO CONTACTS")
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)

                Text("Import from your address book or add contacts manually")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Import button (情報デザイン: bento row style with clear compartments)
            Button {
                showingImportSheet = true
            } label: {
                HStack(spacing: 0) {
                    // LEFT COMPARTMENT: Icon zone
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .frame(width: 56, height: 56)
                        .background(PageHeaderColor.contacts.lightBackground)

                    // VERTICAL WALL (full height)
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // RIGHT COMPARTMENT: Label
                    Text("IMPORT FROM ADDRESS BOOK")
                        .font(JohoFont.bodySmall.bold())
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .padding(.trailing, JohoDimensions.spacingMD)
                }
                .frame(height: 56)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()
                .frame(height: JohoDimensions.spacingXL)
        }
        .frame(minHeight: 300)
    }

    // MARK: - Contact List Content (情報デザイン: Clean grouped list with letter picker)

    @State private var filterLetter: String?  // 情報デザイン: Filter to show only one letter group
    @State private var selectedGroup: ContactGroup?  // 情報デザイン: Filter by contact group
    @State private var isGroupsExpanded = false  // 情報デザイン: Collapsible group filter
    @State private var isIndexExpanded = false  // 情報デザイン: Collapsible letter index

    private var contactsListContent: some View {
        VStack(spacing: 0) {
            // 情報デザイン: Collapsible filter header (GROUPS | INDEX)
            filterHeaderRow

            // Horizontal divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1)

            // Contact list (情報デザイン: filtered by selected letter)
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { deleteContact(contact) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button { editingContact = contact } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(JohoColors.cyan)
                                }
                            }
                        } header: {
                            sectionHeader(letter: section)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Header Row (情報デザイン: Subtle filter bar)

    private var filterHeaderRow: some View {
        VStack(spacing: 0) {
            // Simple filter row - subtle, not heavy
            HStack(spacing: JohoDimensions.spacingSM) {
                // Group filter pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGroupsExpanded.toggle()
                        if isGroupsExpanded { isIndexExpanded = false }
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        if let group = selectedGroup {
                            Image(systemName: group.icon)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                            Text(group.localizedName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        } else {
                            Image(systemName: "folder")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                            Text("All")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        Image(systemName: isGroupsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                    .foregroundStyle(selectedGroup != nil ? Color(hex: selectedGroup!.color) : colors.primary.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedGroup != nil ? Color(hex: selectedGroup!.color).opacity(0.12) : colors.inputBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Letter filter pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isIndexExpanded.toggle()
                        if isIndexExpanded { isGroupsExpanded = false }
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        if let letter = filterLetter {
                            Text(letter)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        } else {
                            Text("A-Z")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        Image(systemName: isIndexExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                    .foregroundStyle(filterLetter != nil ? accentColor : colors.primary.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(filterLetter != nil ? accentColor.opacity(0.12) : colors.inputBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                // Contact count
                Text("\(filteredContacts.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.4))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surface)

            // Expanded: Group filter grid
            if isGroupsExpanded {
                Rectangle()
                    .fill(colors.primary.opacity(0.1))
                    .frame(height: 1)

                groupFilterGrid
            }

            // Expanded: Letter index grid
            if isIndexExpanded {
                Rectangle()
                    .fill(colors.primary.opacity(0.1))
                    .frame(height: 1)

                letterIndexGrid
            }
        }
        .background(colors.surface)
    }

    // MARK: - Group Filter Grid (情報デザイン: Simple pill list)

    private var groupFilterGrid: some View {
        // Horizontal scrolling pills - simpler than grid
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                groupPill(
                    icon: "person.3",
                    label: "All",
                    count: contacts.count,
                    isSelected: selectedGroup == nil,
                    color: accentColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGroup = nil
                        isGroupsExpanded = false
                    }
                }

                // Group pills
                ForEach(ContactGroup.allCases, id: \.self) { group in
                    let count = contacts.filter { $0.group == group }.count
                    groupPill(
                        icon: group.icon,
                        label: group.localizedName,
                        count: count,
                        isSelected: selectedGroup == group,
                        color: Color(hex: group.color)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGroup = selectedGroup == group ? nil : group
                            isGroupsExpanded = false
                        }
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.inputBackground.opacity(0.5))
    }

    private func groupPill(icon: String, label: String, count: Int, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(isSelected ? colors.primaryInverted.opacity(0.7) : colors.primary.opacity(0.4))
                }
            }
            .foregroundStyle(isSelected ? colors.primaryInverted : colors.primary.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? color : colors.border.opacity(0.5), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Letter Index Grid (情報デザイン: Simple letter strip)

    private var letterIndexGrid: some View {
        let populatedLetters = allAvailableLetters

        // Horizontal scrolling letter pills - simpler
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // "All" pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterLetter = nil
                        isIndexExpanded = false
                    }
                    HapticManager.selection()
                } label: {
                    Text("All")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(filterLetter == nil ? colors.primaryInverted : colors.primary.opacity(0.6))
                        .frame(minWidth: 36)
                        .padding(.vertical, 8)
                        .background(filterLetter == nil ? accentColor : colors.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(filterLetter == nil ? accentColor : colors.border.opacity(0.5), lineWidth: filterLetter == nil ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)

                // Letter pills
                ForEach(populatedLetters, id: \.self) { letter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterLetter = filterLetter == letter ? nil : letter
                            isIndexExpanded = false
                        }
                        HapticManager.selection()
                    } label: {
                        Text(letter)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(filterLetter == letter ? colors.primaryInverted : colors.primary.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(filterLetter == letter ? accentColor : colors.surface)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(filterLetter == letter ? accentColor : colors.border.opacity(0.3), lineWidth: filterLetter == letter ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.inputBackground.opacity(0.5))
    }

    // MARK: - Section Header (情報デザイン: Subtle letter divider)

    private func sectionHeader(letter: String) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Subtle letter badge - not heavy black
            Text(letter)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.5))
                .frame(width: 20)

            // Light divider line
            Rectangle()
                .fill(colors.primary.opacity(0.15))
                .frame(height: 1)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, 6)
        .background(colors.surface)
    }

    // MARK: - Clean Contact Row (情報デザイン: Minimal, readable, information-first)

    private func compactContactRow(for contact: Contact) -> some View {
        let isSelected = selectedForDeletion.contains(contact.id)

        return HStack(spacing: JohoDimensions.spacingMD) {
            // EDIT MODE: Selection checkbox
            if isEditMode {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isSelected {
                            selectedForDeletion.remove(contact.id)
                        } else {
                            selectedForDeletion.insert(contact.id)
                        }
                    }
                    HapticManager.selection()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isSelected ? JohoColors.red : colors.primary.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            // AVATAR: Clean squircle, not too heavy
            JohoContactAvatar(contact: contact, size: 44)

            // INFO: Name + subtitle (clean stack, no pills)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                // Subtitle: Org or birthday (not both cluttering)
                if let org = contact.organizationName, org.isNotEmpty {
                    Text(org)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .lineLimit(1)
                } else if contact.birthday != nil {
                    // Only show birthday if no org
                    Text("Birthday")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(JohoColors.pink.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ACTION ICONS: Subtle, icon-only (no colored backgrounds)
            if !isEditMode {
                HStack(spacing: 16) {
                    // Birthday indicator (subtle)
                    if contact.birthday != nil, contact.hasBirthdayForStarPage {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(JohoColors.pink)
                    }

                    // Phone (if available)
                    if let phone = contact.phoneNumbers.first?.value {
                        Button {
                            if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(JohoColors.green)
                        }
                        .buttonStyle(.plain)
                    }

                    // Chevron for detail
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.primary.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(isSelected ? JohoColors.red.opacity(0.1) : Color.clear)
    }

    // MARK: - Contact Row (情報デザイン: Bento style with compartments)

    private func contactRow(for contact: Contact) -> some View {
        HStack(spacing: 0) {
            // LEFT: Avatar compartment
            JohoContactAvatar(contact: contact, size: 44)
                .padding(.horizontal, JohoDimensions.spacingSM)

            // WALL
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .padding(.vertical, JohoDimensions.spacingSM)

            // CENTER: Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(JohoFont.body.bold())
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if let org = contact.organizationName, org.isNotEmpty {
                    Text(org)
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            Spacer()

            // RIGHT: Quick info indicators
            HStack(spacing: 4) {
                if contact.phoneNumbers.isNotEmpty {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                if contact.emailAddresses.isNotEmpty {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                // 情報デザイン: Birthday indicator with Pink pill background
                if contact.birthday != nil {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(SpecialDayType.birthday.accentColor)
                        .padding(4)
                        .background(JohoColors.pink)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.5))
                .padding(.trailing, JohoDimensions.spacingSM)
        }
        .frame(height: 56)
        .background(colors.inputBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
    }

    /// 情報デザイン: Compact subtitle showing contact stats
    private var contactsSubtitle: String {
        var parts: [String] = []
        parts.append("\(contacts.count) contact\(contacts.count == 1 ? "" : "s")")

        var details: [String] = []
        if contactsWithPhone > 0 { details.append("\(contactsWithPhone) phone") }
        if contactsWithBirthday > 0 { details.append("\(contactsWithBirthday) birthday\(contactsWithBirthday == 1 ? "" : "s")") }

        if details.isNotEmpty {
            parts.append("• " + details.joined(separator: " • "))
        }

        return parts.joined(separator: " ")
    }

    private func deleteContact(_ contact: Contact) {
        modelContext.delete(contact)
        try? modelContext.save()
    }

    private func deleteSelectedContacts() {
        // Find contacts by ID and delete them
        let contactsToDelete = contacts.filter { selectedForDeletion.contains($0.id) }
        for contact in contactsToDelete {
            modelContext.delete(contact)
        }
        try? modelContext.save()

        // Clear selection and exit edit mode
        selectedForDeletion.removeAll()
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditMode = false
        }

        HapticManager.notification(.success)
    }
}

// MARK: - 情報デザイン Contact Avatar (Clean, Minimal)

/// Clean contact avatar - photo or initials in a subtle squircle
/// Designed to not overpower the contact information
struct JohoContactAvatar: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let contact: Contact
    var size: CGFloat = 44

    // Softer accent color for avatars (not heavy brown)
    private var avatarBackground: Color {
        // Use a softer, more neutral tone
        colorMode == .dark ? Color(hex: "3A3A3C") : Color(hex: "E5E5EA")
    }

    private var initialsColor: Color {
        colorMode == .dark ? colors.primary : Color(hex: "636366")
    }

    private var fontSize: CGFloat {
        size * 0.36
    }

    private var cornerRadius: CGFloat {
        size * 0.24
    }

    var body: some View {
        Group {
            if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                // Photo available - clean squircle
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Squircle(cornerRadius: cornerRadius))
                    .overlay(
                        Squircle(cornerRadius: cornerRadius)
                            .stroke(colors.border.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // No photo - subtle initials
                ZStack {
                    Squircle(cornerRadius: cornerRadius)
                        .fill(avatarBackground)

                    Text(contact.initials.isEmpty ? "?" : contact.initials)
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(initialsColor)
                }
                .frame(width: size, height: size)
                .overlay(
                    Squircle(cornerRadius: cornerRadius)
                        .stroke(colors.border.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - 情報デザイン Contact Row (Business Card Style)

/// A contact row that displays squircle photo (or initials), name, organization - business card style
struct JohoContactRow: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Squircle avatar
            JohoContactAvatar(contact: contact, size: 56)
                .padding(JohoDimensions.spacingSM)

            // VERTICAL WALL
            Rectangle()
                .fill(colors.border.opacity(0.5))
                .frame(width: 1)
                .padding(.vertical, JohoDimensions.spacingSM)

            // CENTER COMPARTMENT: Contact info
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(contact.displayName)
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                // Organization (if any)
                if let org = contact.organizationName, org.isNotEmpty {
                    Text(org)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .lineLimit(1)
                }

                // Quick contact info pills (情報デザイン squircle pills)
                HStack(spacing: JohoDimensions.spacingXS) {
                    if primaryPhone != nil {
                        contactInfoPill(icon: "phone.fill", text: "PHONE", color: accentColor)
                    }

                    if primaryEmail != nil {
                        contactInfoPill(icon: "envelope.fill", text: "EMAIL", color: accentColor)
                    }

                    // 情報デザイン: Birthday pill with Pink background
                    if contact.birthday != nil {
                        contactInfoPill(icon: "gift.fill", text: "BDAY", color: SpecialDayType.birthday.accentColor, bgColor: JohoColors.pink.opacity(0.2))
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .padding(.trailing, JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }

    @ViewBuilder
    /// 情報デザイン: Info pill with squircle shape (not capsule)
    private func contactInfoPill(icon: String, text: String, color: Color, bgColor: Color? = nil) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold, design: .rounded))
            Text(text)
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(bgColor ?? colors.surface)
        .clipShape(Squircle(cornerRadius: 4))
        .overlay(Squircle(cornerRadius: 4).stroke(colors.border.opacity(0.5), lineWidth: 1))
    }
}

struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Use @State to track authorization - refreshes view when changed
    @State private var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    private var contactsManager = ContactsManager.shared

    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var showingIOSContactPicker = false

    // 情報デザイン accent color for Contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    // Computed property for authorization check
    // iOS 18+: Handle both .authorized and .limited (user selected specific contacts)
    private var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

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
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingMD)
                                .background(colors.surface)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: 1.5)
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
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .frame(width: 40, height: 40)
                                .background(PageHeaderColor.contacts.lightBackground)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )

                            Text("IMPORT CONTACTS")
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Horizontal divider
                        Rectangle()
                            .fill(colors.border)
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
                            .disabled(isImporting || !isAuthorized)
                            .opacity((isImporting || !isAuthorized) ? 0.5 : 1.0)

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
                            .disabled(isImporting || !isAuthorized)
                            .opacity((isImporting || !isAuthorized) ? 0.5 : 1.0)
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Permission warning if needed
                        if !isAuthorized {
                            // Divider
                            Rectangle()
                                .fill(colors.border)
                                .frame(height: 1.5)

                            // Warning section (情報デザイン: white background with warning indicator)
                            VStack(spacing: JohoDimensions.spacingMD) {
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    // Warning icon
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.red)
                                        .frame(width: 32, height: 32)
                                        .background(JohoColors.redLight)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))

                                    JohoPill(text: "PERMISSION REQUIRED", style: .whiteOnBlack, size: .small)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Contacts access is required to import from your address book.")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.red)  // Keep red for warning text
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Grant permission button
                                Button {
                                    requestPermission()
                                } label: {
                                    HStack(spacing: 0) {
                                        // Icon zone
                                        Image(systemName: "person.badge.key")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(JohoColors.red)
                                            .johoTouchTarget()
                                            .background(JohoColors.redLight)

                                        // Wall
                                        Rectangle()
                                            .fill(colors.border)
                                            .frame(width: 1.5)

                                        // Label
                                        Text("GRANT PERMISSION")
                                            .font(JohoFont.bodySmall.bold())
                                            .foregroundStyle(colors.primary)
                                            .padding(.horizontal, JohoDimensions.spacingMD)

                                        Spacer()

                                        // Chevron
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(colors.primary)
                                            .padding(.trailing, JohoDimensions.spacingMD)
                                    }
                                    .frame(height: 48)
                                    .background(colors.surface)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                            .stroke(colors.border, lineWidth: 1.5)
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
                                .fill(colors.border)
                                .frame(height: 1.5)

                            HStack(spacing: JohoDimensions.spacingSM) {
                                Image(systemName: message.contains("Success") ? "checkmark.circle.fill" : "info.circle.fill")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(message.contains("Success") ? JohoColors.green : accentColor)

                                Text(message)
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(colors.primary)

                                Spacer()
                            }
                            .padding(JohoDimensions.spacingMD)
                        }
                    }
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
                            .tint(colors.primaryInverted)

                        Text("Importing...")
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primaryInverted)
                    }
                    .padding(JohoDimensions.spacingXL)
                    .background(colors.primary)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(Squircle(cornerRadius: JohoDimensions.radiusLarge).stroke(colors.primaryInverted, lineWidth: 2))
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .johoTouchTarget()
                .background(PageHeaderColor.contacts.lightBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(colors.border, lineWidth: 1.5)
                )
                .padding(.leading, JohoDimensions.spacingSM)

            // Wall (full height, no vertical padding)
            Rectangle()
                .fill(colors.border)
                .frame(width: 1.5)
                .padding(.leading, JohoDimensions.spacingSM)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body.bold())
                    .foregroundStyle(colors.primary)

                Text(subtitle)
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.primary.opacity(0.6))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .padding(.trailing, JohoDimensions.spacingMD)
        }
        .frame(height: 56)
        .background(colors.inputBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
    }

    private func requestPermission() {
        Task {
            do {
                let granted = try await contactsManager.requestAccess()
                await MainActor.run {
                    // Update local state to refresh UI
                    authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                    if granted {
                        importMessage = "Permission granted. You can now import contacts."
                    } else {
                        importMessage = "Permission denied. Please enable in Settings."
                    }
                }
            } catch {
                await MainActor.run {
                    authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                    importMessage = "Error requesting permission: \(error.localizedDescription)"
                }
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

        // IMPORTANT: Only implement the PLURAL version to enable multi-select mode
        // If the singular version is implemented, the picker uses single-select mode
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            // Fetch full contact details (the picker returns partial contacts)
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactNoteKey as CNKeyDescriptor
            ]

            let store = CNContactStore()
            var fullContacts: [CNContact] = []

            for contact in contacts {
                do {
                    let fullContact = try store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch)
                    fullContacts.append(fullContact)
                } catch {
                    // If we can't fetch full details, use the partial contact
                    fullContacts.append(contact)
                }
            }

            onContactsSelected(fullContacts)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // User cancelled - do nothing
        }
    }
}

// MARK: - 情報デザイン Add Contact Sheet

/// 情報デザイン compliant sheet for adding a Contact (Birthday is part of Contact)
struct JohoAddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
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
                    .foregroundStyle(colors.primaryInverted)

                Spacer()

                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, 12)
            .background(colors.primary)

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
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
                    .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderMedium))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
            }

            // Code badge - BLACK border around colored pill
            Text(code)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Squircle(cornerRadius: 4))
                .overlay(
                    Squircle(cornerRadius: 4)
                        .stroke(colors.border, lineWidth: 1.5)
                )

            // Label - bold rounded for 情報デザイン
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            // Arrow - bold BLACK
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, 10)
        .background(colors.surface)
    }
}

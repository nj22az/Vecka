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
    @State private var isIndexExpanded = false  // 情報デザイン: Collapsible letter index
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
        contacts.filter { !$0.phoneNumbers.isEmpty }.count
    }
    private var contactsWithEmail: Int {
        contacts.filter { !$0.emailAddresses.isEmpty }.count
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
        if !searchText.isEmpty {
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
            Task {
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

                // RIGHT COMPARTMENT: Edit mode controls OR Export/Import buttons
                HStack(spacing: 0) {
                    if isEditMode {
                        // Delete selected button (red when items selected)
                        if !selectedForDeletion.isEmpty {
                            Button {
                                deleteSelectedContacts()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("\(selectedForDeletion.count)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(JohoColors.white)
                                .frame(height: 32)
                                .padding(.horizontal, 12)
                                .background(JohoColors.red)
                                .clipShape(Squircle(cornerRadius: 8))
                                .overlay(
                                    Squircle(cornerRadius: 8)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
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
                                .foregroundStyle(JohoColors.white)
                                .frame(height: 32)
                                .padding(.horizontal, 12)
                                .background(PageHeaderColor.contacts.accent)
                                .clipShape(Squircle(cornerRadius: 8))
                                .overlay(
                                    Squircle(cornerRadius: 8)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
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
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(PageHeaderColor.contacts.accent)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(contacts.isEmpty)
                        .opacity(contacts.isEmpty ? 0.3 : 1.0)

                        // Thin separator (情報デザイン: solid black, reduced height)
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 0.5)
                            .padding(.vertical, 8)

                        // Export button
                        Button {
                            showingExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(PageHeaderColor.contacts.accent)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Thin separator (情報デザイン: solid black, reduced height)
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 0.5)
                            .padding(.vertical, 8)

                        // Import button
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
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingXS)
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

    // MARK: - Contact List Content (情報デザイン: Clean grouped list with letter picker)

    @State private var filterLetter: String?  // 情報デザイン: Filter to show only one letter group
    @State private var selectedGroup: ContactGroup?  // 情報デザイン: Filter by contact group

    private var contactsListContent: some View {
        VStack(spacing: 0) {
            // 情報デザイン: Group filter strip (Family/Friends/Work/Other)
            groupFilterStrip

            // Thin divider (情報デザイン: solid black, reduced height)
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 0.5)

            // 情報デザイン: Always-visible horizontal letter strip (like iOS Contacts)
            letterPickerStrip

            // Horizontal divider
            Rectangle()
                .fill(JohoColors.black)
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

    // MARK: - Group Filter Strip (情報デザイン: Filter by contact group)

    private var groupFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGroup = nil
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("All")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(selectedGroup == nil ? JohoColors.white : JohoColors.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedGroup == nil ? accentColor : JohoColors.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(JohoColors.black, lineWidth: selectedGroup == nil ? 2 : 1)
                    )
                }
                .accessibilityLabel("Show all contacts")

                // Group buttons
                ForEach(ContactGroup.allCases, id: \.self) { group in
                    let count = contacts.filter { $0.group == group }.count
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedGroup == group {
                                selectedGroup = nil
                            } else {
                                selectedGroup = group
                            }
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: group.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(group.localizedName)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            if count > 0 {
                                Text("(\(count))")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(selectedGroup == group ? JohoColors.white.opacity(0.8) : JohoColors.black.opacity(0.5))
                            }
                        }
                        .foregroundStyle(selectedGroup == group ? JohoColors.white : JohoColors.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedGroup == group ? Color(hex: group.color) : JohoColors.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(JohoColors.black, lineWidth: selectedGroup == group ? 2 : 1)
                        )
                    }
                    .accessibilityLabel("Filter by \(group.localizedName)")
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
    }

    // MARK: - Letter Picker (情報デザイン: Collapsible index with "INDEX >" toggle)

    private var letterPickerStrip: some View {
        let populatedLetters = allAvailableLetters

        return VStack(spacing: 0) {
            // Header row: INDEX > (tap to expand/collapse)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isIndexExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone (情報デザイン: solid semantic background)
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 24, height: 24)
                        .background(PageHeaderColor.contacts.lightBackground)
                        .clipShape(Squircle(cornerRadius: 5))
                        .overlay(
                            Squircle(cornerRadius: 5)
                                .stroke(JohoColors.black, lineWidth: 1)
                        )

                    Text("INDEX")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(JohoColors.black)

                    // Chevron indicating expand/collapse state
                    Image(systemName: isIndexExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Spacer()

                    // Show current filter badge if active
                    if let letter = filterLetter {
                        HStack(spacing: 4) {
                            Text(letter)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                            Text("(\(filteredContacts.count))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.white.opacity(0.8))
                        }
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accentColor)
                        .clipShape(Squircle(cornerRadius: 6))
                        .overlay(
                            Squircle(cornerRadius: 6)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                        // × clear button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterLetter = nil
                            }
                            HapticManager.selection()
                        } label: {
                            Text("×")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(JohoColors.white)
                                .frame(width: 28, height: 28)
                                .background(JohoColors.black)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Clear filter")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isIndexExpanded ? "Collapse index" : "Expand index")
            .accessibilityHint("Tap to \(isIndexExpanded ? "hide" : "show") letter filter")

            // Expanded: Letter grid (情報デザイン: wrapping grid, no horizontal scroll)
            if isIndexExpanded {
                // Thin divider (情報デザイン: solid black, reduced height)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 0.5)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                // Letter grid using LazyVGrid for wrapping
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: min(populatedLetters.count + 1, 10))

                LazyVGrid(columns: columns, spacing: 6) {
                    // "ALL" button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterLetter = nil
                        }
                        HapticManager.selection()
                    } label: {
                        Text("ALL")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(filterLetter == nil ? JohoColors.white : JohoColors.black)
                            .frame(minWidth: 32, minHeight: 32)
                            .background(filterLetter == nil ? accentColor : JohoColors.inputBackground)
                            .clipShape(Squircle(cornerRadius: 6))
                            .overlay(
                                Squircle(cornerRadius: 6)
                                    .stroke(JohoColors.black, lineWidth: filterLetter == nil ? 2 : 1)
                            )
                    }
                    .accessibilityLabel("Show all contacts")

                    // Letter buttons
                    ForEach(populatedLetters, id: \.self) { letter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if filterLetter == letter {
                                    filterLetter = nil
                                } else {
                                    filterLetter = letter
                                }
                            }
                            HapticManager.selection()
                        } label: {
                            Text(letter)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(filterLetter == letter ? JohoColors.white : JohoColors.black)
                                .frame(minWidth: 32, minHeight: 32)
                                .background(filterLetter == letter ? accentColor : JohoColors.inputBackground)
                                .clipShape(Squircle(cornerRadius: 6))
                                .overlay(
                                    Squircle(cornerRadius: 6)
                                        .stroke(JohoColors.black, lineWidth: filterLetter == letter ? 2 : 1)
                                )
                        }
                        .accessibilityLabel("Filter by \(letter)")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
        }
        .background(JohoColors.white)
    }

    // MARK: - Section Header (情報デザイン: Clean letter header)

    private func sectionHeader(letter: String) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(letter)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .frame(width: 24, height: 24)
                .background(JohoColors.black)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            // 情報デザイン: Solid black divider line, reduced height
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 0.5)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(JohoColors.white)
    }

    // MARK: - Kudo-Style Contact Row (情報デザイン: Photo + Name + actionable icons)

    private func compactContactRow(for contact: Contact) -> some View {
        let isSelected = selectedForDeletion.contains(contact.id)

        return HStack(spacing: JohoDimensions.spacingSM) {
            // EDIT MODE: Selection checkbox (情報デザイン: circle with checkmark)
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
                    ZStack {
                        Circle()
                            .fill(isSelected ? JohoColors.red : JohoColors.white)
                            .frame(width: 28, height: 28)
                        Circle()
                            .stroke(isSelected ? JohoColors.red : JohoColors.black.opacity(0.4), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(JohoColors.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // PHOTO COMPARTMENT (48pt) - tap to see details
            JohoContactAvatar(contact: contact, size: 48)

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

            // ACTIONABLE CONTACT BUTTONS (情報デザイン: Semantic colors like Star page)
            // Hide action buttons in edit mode
            if !isEditMode {
                HStack(spacing: 10) {
                    // Birthday indicator (secondary - small pink dot, not actionable)
                    birthdayIndicator(for: contact)

                    // Message button - Cyan
                    if let phone = contact.phoneNumbers.first?.value {
                        JohoContactActionButton(action: .message(phone: phone))
                    }

                    // Email button - Purple
                    if let email = contact.emailAddresses.first?.value {
                        JohoContactActionButton(action: .email(address: email))
                    }

                    // Phone button - Green
                    if let phone = contact.phoneNumbers.first?.value {
                        JohoContactActionButton(action: .call(phone: phone))
                    }
                }
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .frame(height: 64)
        .background(isSelected ? JohoColors.redLight.opacity(0.3) : Color.clear)
    }

    // MARK: - Birthday Indicator (情報デザイン: Small pink dot)

    /// 情報デザイン: Small birthday dot - details shown in contact detail view
    @ViewBuilder
    private func birthdayIndicator(for contact: Contact) -> some View {
        if contact.birthday != nil, contact.hasBirthdayForStarPage {
            // Small pink dot (情報デザイン: Secondary indicator)
            Circle()
                .fill(JohoColors.pink)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
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
                // 情報デザイン: Birthday indicator with Pink pill background
                if contact.birthday != nil {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SpecialDayType.birthday.accentColor)
                        .padding(4)
                        .background(JohoColors.pink)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
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

    private var decorationBadgeSize: CGFloat {
        size * 0.35
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                    // No photo - show initials with Warm Brown background
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

            // Symbol decoration badge (情報デザイン: bottom-right overlay)
            if let symbolName = contact.symbolName, symbolName != "person.fill" {
                Image(systemName: symbolName)
                    .font(.system(size: decorationBadgeSize * 0.5, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: decorationBadgeSize, height: decorationBadgeSize)
                    .background(JohoColors.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    .offset(x: 2, y: 2)
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

                    // 情報デザイン: Birthday pill with Pink background
                    if contact.birthday != nil {
                        contactInfoPill(icon: "gift.fill", text: "BDAY", color: SpecialDayType.birthday.accentColor, bgColor: JohoColors.pink)
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
    /// 情報デザイン: Info pill with optional background color (default white)
    private func contactInfoPill(icon: String, text: String, color: Color, bgColor: Color = JohoColors.white) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(bgColor)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
    }
}

struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Use @State to track authorization - refreshes view when changed
    @State private var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    private var contactsManager = ContactsManager.shared

    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var showingIOSContactPicker = false

    // 情報デザイン accent color for Contacts (Warm Brown)
    private var accentColor: Color { PageHeaderColor.contacts.accent }

    // Computed property for authorization check
    private var isAuthorized: Bool {
        authorizationStatus == .authorized
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

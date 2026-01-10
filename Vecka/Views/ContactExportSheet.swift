//
//  ContactExportSheet.swift
//  Vecka
//
//  情報デザイン: Contact export with individual selection
//

import SwiftUI
import SwiftData

struct ContactExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let contacts: [Contact]

    // PDF Export settings (from Settings)
    @AppStorage("pdfExportTitle") private var pdfExportTitle = "Contact Directory"
    @AppStorage("pdfExportFooter") private var pdfExportFooter = ""

    // Selection
    @State private var selectedIDs: Set<UUID> = []
    @State private var filterLetter: String? = nil

    // Options
    @State private var includePhone = true
    @State private var includeEmail = true
    @State private var includeBirthday = true
    @State private var includeGroup = false  // 情報デザイン: Show contact group/category
    @State private var sortByBirthday = false

    // Export state
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    // Initialize with all selected
    init(contacts: [Contact]) {
        self.contacts = contacts
        _selectedIDs = State(initialValue: Set(contacts.map { $0.id }))
    }

    private var availableLetters: [String] {
        let letters = Set(contacts.compactMap { contact -> String? in
            let name = contact.familyName.isEmpty ? contact.givenName : contact.familyName
            guard let first = name.first else { return nil }
            return String(first).uppercased()
        })
        return letters.sorted()
    }

    private var visibleContacts: [Contact] {
        let filtered: [Contact]
        if let letter = filterLetter {
            filtered = contacts.filter { contact in
                let name = contact.familyName.isEmpty ? contact.givenName : contact.familyName
                return name.uppercased().hasPrefix(letter)
            }
        } else {
            filtered = contacts
        }
        return filtered.sorted {
            let n1 = $0.familyName.isEmpty ? $0.givenName : $0.familyName
            let n2 = $1.familyName.isEmpty ? $1.givenName : $1.familyName
            return n1.localizedCaseInsensitiveCompare(n2) == .orderedAscending
        }
    }

    private var selectedContacts: [Contact] {
        contacts.filter { selectedIDs.contains($0.id) }
    }

    private var allVisibleSelected: Bool {
        visibleContacts.allSatisfy { selectedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Letter strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        letterButton(nil, label: "ALL")
                        ForEach(availableLetters, id: \.self) { letter in
                            letterButton(letter, label: letter)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
                }
                .background(JohoColors.white)

                Divider()

                // Select all row
                HStack {
                    Button {
                        toggleAllVisible()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: allVisibleSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(allVisibleSelected ? JohoColors.purple : JohoColors.black.opacity(0.4))
                            Text(allVisibleSelected ? "Deselect all" : "Select all")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(selectedIDs.count) selected")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(JohoColors.purple.opacity(0.1))

                // Contact list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(visibleContacts, id: \.id) { contact in
                            contactRow(contact)
                            if contact.id != visibleContacts.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                }

                Divider()

                // Bottom options + export
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Compact options row (情報デザイン: functional toggles)
                    HStack(spacing: JohoDimensions.spacingSM) {
                        optionPill("Phone", icon: "phone.fill", isOn: $includePhone)
                        optionPill("Email", icon: "envelope.fill", isOn: $includeEmail)
                        optionPill("Birthday", icon: "gift.fill", isOn: $includeBirthday)
                        optionPill("Group", icon: "folder.fill", isOn: $includeGroup)

                        Spacer()

                        Picker("", selection: $sortByBirthday) {
                            Text("A-Z").tag(false)
                            Text("Bday").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)

                    // Export button
                    Button {
                        performExport()
                    } label: {
                        HStack(spacing: 8) {
                            if isExporting {
                                ProgressView().tint(JohoColors.black)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            Text(isExporting ? "Generating..." : "Export \(selectedIDs.count) contacts")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(selectedIDs.isEmpty ? JohoColors.black.opacity(0.1) : JohoColors.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(JohoColors.black, lineWidth: 2)
                        )
                    }
                    .disabled(isExporting || selectedIDs.isEmpty)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                }
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(JohoColors.white)
            }
            .background(JohoColors.white)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(JohoColors.black)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL { ShareSheet(url: url) }
            }
        }
    }

    // MARK: - Components

    private func letterButton(_ letter: String?, label: String) -> some View {
        let isSelected = filterLetter == letter
        let count: Int
        if let l = letter {
            count = contacts.filter {
                let name = $0.familyName.isEmpty ? $0.givenName : $0.familyName
                return name.uppercased().hasPrefix(l)
            }.count
        } else {
            count = contacts.count
        }

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                filterLetter = letter
            }
        } label: {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(count)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .foregroundStyle(JohoColors.black)
            .frame(width: letter == nil ? 36 : 26, height: 36)
            .background(isSelected ? JohoColors.purple : JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func contactRow(_ contact: Contact) -> some View {
        let isSelected = selectedIDs.contains(contact.id)

        return Button {
            if isSelected {
                selectedIDs.remove(contact.id)
            } else {
                selectedIDs.insert(contact.id)
            }
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? JohoColors.purple : JohoColors.black.opacity(0.3))

                // Avatar
                ZStack {
                    Circle()
                        .fill(JohoColors.purple.opacity(0.2))
                    Text(contact.initials)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    // Subtitle with available info
                    let subtitle = contactSubtitle(contact)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(isSelected ? JohoColors.purple.opacity(0.08) : JohoColors.white)
        }
        .buttonStyle(.plain)
    }

    private func contactSubtitle(_ contact: Contact) -> String {
        var parts: [String] = []
        if let phone = contact.phoneNumbers.first?.value {
            parts.append(phone)
        }
        if let email = contact.emailAddresses.first?.value {
            parts.append(email)
        }
        return parts.joined(separator: " • ")
    }

    private func optionPill(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(JohoColors.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isOn.wrappedValue ? JohoColors.purple.opacity(0.3) : JohoColors.black.opacity(0.05))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(JohoColors.black, lineWidth: isOn.wrappedValue ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    private func toggleAllVisible() {
        if allVisibleSelected {
            for contact in visibleContacts {
                selectedIDs.remove(contact.id)
            }
        } else {
            for contact in visibleContacts {
                selectedIDs.insert(contact.id)
            }
        }
    }

    private func performExport() {
        isExporting = true
        errorMessage = nil

        let options = ContactExportOptions(
            includePhone: includePhone,
            includeEmail: includeEmail,
            includeBirthday: includeBirthday,
            includeGroup: includeGroup,  // 情報デザイン: User-configurable
            sortByBirthday: sortByBirthday
        )

        // Capture settings for async context
        let title = pdfExportTitle
        let footer = pdfExportFooter

        Task {
            do {
                let url = try await ContactExportService.shared.exportContacts(
                    selectedContacts,
                    options: options,
                    pdfTitle: title,
                    pdfFooter: footer,
                    modelContext: modelContext
                )
                await MainActor.run {
                    exportedURL = url
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

struct ContactExportOptions {
    let includePhone: Bool
    let includeEmail: Bool
    let includeBirthday: Bool
    let includeGroup: Bool
    let sortByBirthday: Bool
}

#Preview {
    ContactExportSheet(contacts: [])
        .modelContainer(for: Contact.self, inMemory: true)
}

//
//  ContactListView.swift
//  Vecka
//
//  Contact list with search, sections, and iOS-style design
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
        List {
            if contacts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("No Contacts")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Import from your address book or add contacts manually")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import from Address Book", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.extraLarge)
                .listRowBackground(Color.clear)
            } else {
                ForEach(sortedSections, id: \.self) { section in
                    Section(header: Text(section)) {
                        ForEach(groupedContacts[section] ?? []) { contact in
                            ContactRow(contact: contact)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedContact = contact
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteContact(contact)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .standardListStyle()
        .searchable(text: $searchText, prompt: "Search contacts")
        .standardNavigation(title: "Contacts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddContact = true
                    } label: {
                        Label("New Contact", systemImage: "person.badge.plus")
                    }

                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import from Address Book", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            NavigationStack {
                ContactDetailView(contact: nil)
            }
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

    private func deleteContact(_ contact: Contact) {
        modelContext.delete(contact)
        try? modelContext.save()
    }
}

struct ContactRow: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let imageData = contact.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(contact.initials)
                            .font(Typography.labelLarge)
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                if let organization = contact.organizationName, !organization.isEmpty {
                    Text(organization)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.extraSmall)
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
            List {
                Section {
                    Button {
                        importAllContacts()
                    } label: {
                        Label("Import All Contacts", systemImage: "person.2.fill")
                    }
                    .disabled(isImporting || contactsManager.authorizationStatus != .authorized)

                    Button {
                        showingIOSContactPicker = true
                    } label: {
                        Label("Select Contacts to Import", systemImage: "person.badge.plus")
                    }
                    .disabled(isImporting || contactsManager.authorizationStatus != .authorized)
                } header: {
                    Text("Import Options")
                } footer: {
                    if contactsManager.authorizationStatus != .authorized {
                        Text("Contacts access is required to import from your address book.")
                    }
                }

                if contactsManager.authorizationStatus != .authorized {
                    Section {
                        Button {
                            requestPermission()
                        } label: {
                            Label("Grant Contacts Permission", systemImage: "person.badge.key")
                        }
                    }
                }

                if let message = importMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .standardListStyle()
            .standardNavigation(title: "Import Contacts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isImporting {
                    ProgressView("Importing...")
                        .padding()
                        .glassCard(cornerRadius: 12, material: .regularMaterial)
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

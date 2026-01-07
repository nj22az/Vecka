//
//  ContactsManager.swift
//  Vecka
//
//  Manages iOS Contacts integration and synchronization
//

import Foundation
import Contacts
import SwiftData
import UIKit

@MainActor
@Observable
class ContactsManager {
    static let shared = ContactsManager()

    var authorizationStatus: CNAuthorizationStatus = .notDetermined

    private let contactStore = CNContactStore()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async throws -> Bool {
        let granted = try await contactStore.requestAccess(for: .contacts)
        checkAuthorizationStatus()
        return granted
    }

    // MARK: - Import from iOS Contacts

    /// Imports all contacts from iOS Contacts app
    /// 情報デザイン: Deduplication check prevents double imports
    /// iOS 18+: .limited access returns only user-selected contacts
    func importAllContacts(to modelContext: ModelContext) async throws -> Int {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw ContactsError.notAuthorized
        }

        // Fetch existing contacts to check for duplicates by cnContactIdentifier
        let existingDescriptor = FetchDescriptor<Contact>()
        let existingContacts = (try? modelContext.fetch(existingDescriptor)) ?? []
        let existingIdentifiers = Set(existingContacts.compactMap { $0.cnContactIdentifier })

        let keys = Self.contactKeys
        let request = CNContactFetchRequest(keysToFetch: keys)

        var importedCount = 0
        var importedContacts: [Contact] = []

        try contactStore.enumerateContacts(with: request) { cnContact, _ in
            // Skip if already imported (deduplication check)
            if existingIdentifiers.contains(cnContact.identifier) {
                return
            }

            let contact = self.convertToContact(cnContact)
            modelContext.insert(contact)
            importedContacts.append(contact)
            importedCount += 1
        }

        try modelContext.save()

        // Scan for duplicates after import (non-blocking)
        if importedCount > 0 {
            await scanForDuplicatesAfterImport(modelContext: modelContext)
        }

        return importedCount
    }

    /// Imports selected contacts from iOS Contacts
    /// Note: Contacts from picker may have minimal data, so we re-fetch with all keys
    /// 情報デザイン: Deduplication check prevents double imports
    func importContacts(_ cnContacts: [CNContact], to modelContext: ModelContext) async throws {
        // Fetch existing contacts to check for duplicates by cnContactIdentifier
        let existingDescriptor = FetchDescriptor<Contact>()
        let existingContacts = (try? modelContext.fetch(existingDescriptor)) ?? []
        let existingIdentifiers = Set(existingContacts.compactMap { $0.cnContactIdentifier })

        var actuallyImported = 0

        for cnContact in cnContacts {
            // Skip if already imported (deduplication check)
            if existingIdentifiers.contains(cnContact.identifier) {
                continue
            }

            // Re-fetch the contact with all our required keys to get full data including images
            let fullContact: CNContact
            do {
                fullContact = try contactStore.unifiedContact(
                    withIdentifier: cnContact.identifier,
                    keysToFetch: Self.contactKeys
                )
            } catch {
                // Fall back to the original contact if re-fetch fails
                fullContact = cnContact
            }

            let contact = convertToContact(fullContact)
            modelContext.insert(contact)
            actuallyImported += 1
        }
        try modelContext.save()

        // Scan for duplicates after import (non-blocking)
        if actuallyImported > 0 {
            await scanForDuplicatesAfterImport(modelContext: modelContext)
        }
    }

    // MARK: - Duplicate Detection Integration

    /// Scan for duplicates after import
    private func scanForDuplicatesAfterImport(modelContext: ModelContext) async {
        // Fetch all contacts for comparison
        let descriptor = FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.familyName)])
        guard let allContacts = try? modelContext.fetch(descriptor) else { return }

        await DuplicateContactManager.shared.scanForDuplicates(
            contacts: allContacts,
            modelContext: modelContext
        )
    }

    /// Fetches all iOS contacts for picker
    /// iOS 18+: .limited access returns only user-selected contacts
    func fetchAllCNContacts() throws -> [CNContact] {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw ContactsError.notAuthorized
        }

        let keys = Self.contactKeys
        let request = CNContactFetchRequest(keysToFetch: keys)

        var contacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }

        return contacts
    }

    // MARK: - Export to iOS Contacts

    /// Exports a WeekGrid contact to iOS Contacts
    /// Note: Export requires full access (.authorized), not limited access
    func exportToIOSContacts(_ contact: Contact) throws {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw ContactsError.notAuthorized
        }

        let cnContact = CNMutableContact()

        // Name
        cnContact.givenName = contact.givenName
        cnContact.familyName = contact.familyName
        cnContact.middleName = contact.middleName ?? ""
        cnContact.namePrefix = contact.namePrefix ?? ""
        cnContact.nameSuffix = contact.nameSuffix ?? ""
        cnContact.nickname = contact.nickname ?? ""

        // Organization
        cnContact.organizationName = contact.organizationName ?? ""
        cnContact.departmentName = contact.departmentName ?? ""
        cnContact.jobTitle = contact.jobTitle ?? ""

        // Phone numbers
        cnContact.phoneNumbers = contact.phoneNumbers.map { phone in
            let label = Self.labelToCNLabel(phone.label, type: .phone)
            return CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: phone.value))
        }

        // Email addresses
        cnContact.emailAddresses = contact.emailAddresses.map { email in
            let label = Self.labelToCNLabel(email.label, type: .email)
            return CNLabeledValue(label: label, value: email.value as NSString)
        }

        // Postal addresses
        cnContact.postalAddresses = contact.postalAddresses.map { address in
            let cnAddress = CNMutablePostalAddress()
            cnAddress.street = address.street
            cnAddress.city = address.city
            cnAddress.state = address.state
            cnAddress.postalCode = address.postalCode
            cnAddress.country = address.country
            cnAddress.isoCountryCode = address.isoCountryCode

            let label = Self.labelToCNLabel(address.label, type: .address)
            return CNLabeledValue(label: label, value: cnAddress)
        }

        // Birthday
        if let birthday = contact.birthday {
            let calendar = Calendar.current
            cnContact.birthday = calendar.dateComponents([.year, .month, .day], from: birthday)
        }

        // Image
        if let imageData = contact.imageData {
            cnContact.imageData = imageData
        }

        // Note
        cnContact.note = contact.note ?? ""

        // Save to Contacts
        let saveRequest = CNSaveRequest()
        saveRequest.add(cnContact, toContainerWithIdentifier: nil)

        try contactStore.execute(saveRequest)

        // Update our contact with the identifier
        contact.cnContactIdentifier = cnContact.identifier
    }

    // MARK: - Conversion Helpers

    private func convertToContact(_ cnContact: CNContact) -> Contact {
        let contact = Contact(
            givenName: cnContact.givenName,
            familyName: cnContact.familyName,
            middleName: cnContact.middleName.isEmpty ? nil : cnContact.middleName,
            organizationName: cnContact.organizationName.isEmpty ? nil : cnContact.organizationName
        )

        // Additional name fields
        contact.namePrefix = cnContact.namePrefix.isEmpty ? nil : cnContact.namePrefix
        contact.nameSuffix = cnContact.nameSuffix.isEmpty ? nil : cnContact.nameSuffix
        contact.nickname = cnContact.nickname.isEmpty ? nil : cnContact.nickname
        contact.departmentName = cnContact.departmentName.isEmpty ? nil : cnContact.departmentName
        contact.jobTitle = cnContact.jobTitle.isEmpty ? nil : cnContact.jobTitle

        // Phone numbers
        contact.phoneNumbers = cnContact.phoneNumbers.map { labeledValue in
            let label = Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other")
            return ContactPhoneNumber(label: label, value: labeledValue.value.stringValue)
        }

        // Email addresses
        contact.emailAddresses = cnContact.emailAddresses.map { labeledValue in
            let label = Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other")
            return ContactEmailAddress(label: label, value: labeledValue.value as String)
        }

        // Postal addresses
        contact.postalAddresses = cnContact.postalAddresses.map { labeledValue in
            let label = Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other")
            let cnAddress = labeledValue.value
            return ContactPostalAddress(
                label: label,
                street: cnAddress.street,
                city: cnAddress.city,
                state: cnAddress.state,
                postalCode: cnAddress.postalCode,
                country: cnAddress.country,
                isoCountryCode: cnAddress.isoCountryCode
            )
        }

        // Birthday
        if let nsBirthday = cnContact.birthday {
            var dateComponents = DateComponents()
            dateComponents.year = nsBirthday.year == NSDateComponentUndefined ? nil : nsBirthday.year
            dateComponents.month = nsBirthday.month == NSDateComponentUndefined ? nil : nsBirthday.month
            dateComponents.day = nsBirthday.day == NSDateComponentUndefined ? nil : nsBirthday.day

            if let date = Calendar.current.date(from: dateComponents) {
                contact.birthday = date
            }
        }

        // Dates
        contact.dates = cnContact.dates.compactMap { labeledValue in
            let nsDateComponents = labeledValue.value
            var dateComponents = DateComponents()
            dateComponents.year = nsDateComponents.year == NSDateComponentUndefined ? nil : nsDateComponents.year
            dateComponents.month = nsDateComponents.month == NSDateComponentUndefined ? nil : nsDateComponents.month
            dateComponents.day = nsDateComponents.day == NSDateComponentUndefined ? nil : nsDateComponents.day

            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let label = Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other")
            return ContactDate(label: label, value: date)
        }

        // URLs
        contact.urlAddresses = cnContact.urlAddresses.map { labeledValue in
            let label = Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other")
            return ContactURL(label: label, value: labeledValue.value as String)
        }

        // Social profiles
        contact.socialProfiles = cnContact.socialProfiles.map { labeledValue in
            let profile = labeledValue.value
            return ContactSocialProfile(
                label: Self.cnLabelToLabel(labeledValue.label, defaultLabel: "other"),
                service: profile.service,
                username: profile.username,
                url: profile.urlString
            )
        }

        // Note - skipped because CNContactNoteKey requires special entitlement
        // that is not available to third-party apps

        // Image - prefer full image, fall back to thumbnail
        if let imageData = cnContact.imageData {
            contact.imageData = imageData
        } else if let thumbnailData = cnContact.thumbnailImageData {
            contact.imageData = thumbnailData
        }

        // Store CN identifier for sync
        contact.cnContactIdentifier = cnContact.identifier

        return contact
    }

    // MARK: - Label Conversion

    private static func cnLabelToLabel(_ cnLabel: String?, defaultLabel: String) -> String {
        guard let cnLabel = cnLabel else { return defaultLabel }

        switch cnLabel {
        case CNLabelHome: return "home"
        case CNLabelWork: return "work"
        case CNLabelOther: return "other"
        case CNLabelPhoneNumberMobile: return "mobile"
        case CNLabelPhoneNumberMain: return "main"
        case CNLabelPhoneNumberHomeFax: return "home fax"
        case CNLabelPhoneNumberWorkFax: return "work fax"
        case CNLabelDateAnniversary: return "anniversary"
        default:
            // Remove "Label" prefix if present
            if cnLabel.hasPrefix("_$!<") && cnLabel.hasSuffix(">!$_") {
                let start = cnLabel.index(cnLabel.startIndex, offsetBy: 4)
                let end = cnLabel.index(cnLabel.endIndex, offsetBy: -4)
                return String(cnLabel[start..<end]).lowercased()
            }
            return cnLabel.lowercased()
        }
    }

    private static func labelToCNLabel(_ label: String, type: ContactFieldType) -> String {
        switch label.lowercased() {
        case "home": return CNLabelHome
        case "work": return CNLabelWork
        case "other": return CNLabelOther
        case "mobile" where type == .phone: return CNLabelPhoneNumberMobile
        case "main" where type == .phone: return CNLabelPhoneNumberMain
        case "home fax" where type == .phone: return CNLabelPhoneNumberHomeFax
        case "work fax" where type == .phone: return CNLabelPhoneNumberWorkFax
        case "anniversary" where type == .date: return CNLabelDateAnniversary
        default: return label
        }
    }

    // MARK: - Contact Keys
    // Note: CNContactNoteKey requires special entitlement (com.apple.developer.contacts.notes)
    // which is not available to third-party apps, so we exclude it to avoid "Unauthorized Keys" error

    private static let contactKeys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactNicknameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactDepartmentNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        CNContactDatesKey as CNKeyDescriptor,
        CNContactUrlAddressesKey as CNKeyDescriptor,
        CNContactSocialProfilesKey as CNKeyDescriptor,
        // CNContactNoteKey - REMOVED: requires special entitlement not available to third-party apps
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,  // Add thumbnail for faster loading
        CNContactIdentifierKey as CNKeyDescriptor
    ]
}

enum ContactFieldType {
    case phone
    case email
    case address
    case date
}

enum ContactsError: LocalizedError {
    case notAuthorized
    case importFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Contacts access not authorized"
        case .importFailed:
            return "Failed to import contacts"
        case .exportFailed:
            return "Failed to export contact"
        }
    }
}

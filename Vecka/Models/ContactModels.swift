//
//  ContactModels.swift
//  Vecka
//
//  Contact data models matching iOS Contacts framework
//

import Foundation
import SwiftData
import Contacts

@Model
final class Contact {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Name
    var givenName: String
    var familyName: String
    var middleName: String?
    var namePrefix: String?
    var nameSuffix: String?
    var nickname: String?
    var organizationName: String?
    var departmentName: String?
    var jobTitle: String?

    // Phone numbers
    var phoneNumbers: [ContactPhoneNumber]

    // Email addresses
    var emailAddresses: [ContactEmailAddress]

    // Postal addresses
    var postalAddresses: [ContactPostalAddress]

    // Dates
    var birthday: Date?
    /// True = birthday is known, False = explicitly marked as N/A (won't show in Star page)
    /// When nil or true with a birthday date, contact appears in Star page birthdays
    /// Default is true for SwiftData migration of existing records
    var birthdayKnown: Bool = true
    var dates: [ContactDate]

    // Social profiles
    var socialProfiles: [ContactSocialProfile]

    // URLs
    var urlAddresses: [ContactURL]

    // Notes
    var note: String?

    // Image
    var imageData: Data?

    // Relations
    var relations: [ContactRelation]

    // iOS Contacts integration
    var cnContactIdentifier: String?

    init(
        givenName: String = "",
        familyName: String = "",
        middleName: String? = nil,
        organizationName: String? = nil,
        phoneNumbers: [ContactPhoneNumber] = [],
        emailAddresses: [ContactEmailAddress] = [],
        postalAddresses: [ContactPostalAddress] = [],
        birthday: Date? = nil,
        birthdayKnown: Bool = true
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.givenName = givenName
        self.familyName = familyName
        self.middleName = middleName
        self.organizationName = organizationName
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.birthday = birthday
        self.birthdayKnown = birthdayKnown
        self.dates = []
        self.socialProfiles = []
        self.urlAddresses = []
        self.relations = []
    }

    var displayName: String {
        let components = [namePrefix, givenName, middleName, familyName, nameSuffix]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        if components.isEmpty {
            return organizationName ?? "No Name"
        }
        return components.joined(separator: " ")
    }

    var initials: String {
        let first = givenName.first.map(String.init) ?? ""
        let last = familyName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    /// Returns true if this contact has a birthday that should appear in the Star page
    /// Only shows when birthdayKnown is true AND birthday date exists
    var hasBirthdayForStarPage: Bool {
        birthdayKnown && birthday != nil
    }
}

@Model
final class ContactPhoneNumber {
    var id: UUID
    var label: String
    var value: String

    init(label: String, value: String) {
        self.id = UUID()
        self.label = label
        self.value = value
    }

    static let labelHome = "home"
    static let labelWork = "work"
    static let labelMobile = "mobile"
    static let labelMain = "main"
    static let labelHomeFax = "home fax"
    static let labelWorkFax = "work fax"
    static let labelOther = "other"
}

@Model
final class ContactEmailAddress {
    var id: UUID
    var label: String
    var value: String

    init(label: String, value: String) {
        self.id = UUID()
        self.label = label
        self.value = value
    }

    static let labelHome = "home"
    static let labelWork = "work"
    static let labelOther = "other"
}

@Model
final class ContactPostalAddress {
    var id: UUID
    var label: String
    var street: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
    var isoCountryCode: String

    init(label: String, street: String = "", city: String = "", state: String = "", postalCode: String = "", country: String = "", isoCountryCode: String = "") {
        self.id = UUID()
        self.label = label
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
    }

    var formattedAddress: String {
        let components = [street, city, state, postalCode, country]
            .filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }

    static let labelHome = "home"
    static let labelWork = "work"
    static let labelOther = "other"
}

@Model
final class ContactDate {
    var id: UUID
    var label: String
    var value: Date

    init(label: String, value: Date) {
        self.id = UUID()
        self.label = label
        self.value = value
    }

    static let labelAnniversary = "anniversary"
    static let labelOther = "other"
}

@Model
final class ContactSocialProfile {
    var id: UUID
    var label: String
    var service: String
    var username: String
    var url: String?

    init(label: String, service: String, username: String, url: String? = nil) {
        self.id = UUID()
        self.label = label
        self.service = service
        self.username = username
        self.url = url
    }

    static let serviceTwitter = "Twitter"
    static let serviceFacebook = "Facebook"
    static let serviceLinkedIn = "LinkedIn"
    static let serviceInstagram = "Instagram"
    static let serviceGitHub = "GitHub"
}

@Model
final class ContactURL {
    var id: UUID
    var label: String
    var value: String

    init(label: String, value: String) {
        self.id = UUID()
        self.label = label
        self.value = value
    }

    static let labelHomePage = "homepage"
    static let labelWork = "work"
    static let labelOther = "other"
}

@Model
final class ContactRelation {
    var id: UUID
    var label: String
    var name: String

    init(label: String, name: String) {
        self.id = UUID()
        self.label = label
        self.name = name
    }

    static let labelSpouse = "spouse"
    static let labelPartner = "partner"
    static let labelMother = "mother"
    static let labelFather = "father"
    static let labelChild = "child"
    static let labelFriend = "friend"
    static let labelManager = "manager"
    static let labelAssistant = "assistant"
}

// MARK: - VCard Support

extension Contact {
    /// Generates a VCard (vCard 3.0) string representation
    /// - Parameter includePhoto: Whether to include the contact photo (default: true). Set to false for QR codes.
    func toVCard(includePhoto: Bool = true) -> String {
        var vcard = "BEGIN:VCARD\nVERSION:3.0\n"

        // Name
        let n = "\(familyName);\(givenName);\(middleName ?? "");;\(nameSuffix ?? "")"
        vcard += "N:\(n)\n"
        vcard += "FN:\(displayName)\n"

        if let nickname = nickname {
            vcard += "NICKNAME:\(nickname)\n"
        }

        // Organization
        if let org = organizationName {
            vcard += "ORG:\(org)"
            if let dept = departmentName {
                vcard += ";\(dept)"
            }
            vcard += "\n"
        }

        if let title = jobTitle {
            vcard += "TITLE:\(title)\n"
        }

        // Phone numbers
        for phone in phoneNumbers {
            let type = phone.label.uppercased().replacingOccurrences(of: " ", with: "")
            vcard += "TEL;TYPE=\(type):\(phone.value)\n"
        }

        // Email addresses
        for email in emailAddresses {
            let type = email.label.uppercased()
            vcard += "EMAIL;TYPE=\(type):\(email.value)\n"
        }

        // Postal addresses
        for address in postalAddresses {
            let type = address.label.uppercased()
            vcard += "ADR;TYPE=\(type):;;\(address.street);\(address.city);\(address.state);\(address.postalCode);\(address.country)\n"
        }

        // Birthday
        if let birthday = birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            vcard += "BDAY:\(formatter.string(from: birthday))\n"
        }

        // URLs
        for url in urlAddresses {
            vcard += "URL:\(url.value)\n"
        }

        // Social profiles
        for profile in socialProfiles {
            if let url = profile.url {
                vcard += "X-SOCIALPROFILE;TYPE=\(profile.service):\(url)\n"
            }
        }

        // Note
        if let note = note {
            vcard += "NOTE:\(note.replacingOccurrences(of: "\n", with: "\\n"))\n"
        }

        // Photo (optional - exclude for QR codes to keep them scannable)
        if includePhoto, let imageData = imageData {
            let base64 = imageData.base64EncodedString()
            vcard += "PHOTO;ENCODING=b;TYPE=JPEG:\(base64)\n"
        }

        vcard += "END:VCARD"
        return vcard
    }

    /// Creates a Contact from VCard string
    static func fromVCard(_ vcardString: String) -> Contact? {
        let contact = Contact()

        let lines = vcardString.components(separatedBy: .newlines)

        for line in lines {
            let parts = line.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }

            let key = parts[0]
            let value = parts[1...].joined(separator: ":")

            if key.hasPrefix("N") {
                let nameComponents = value.components(separatedBy: ";")
                if nameComponents.count > 0 { contact.familyName = nameComponents[0] }
                if nameComponents.count > 1 { contact.givenName = nameComponents[1] }
                if nameComponents.count > 2 { contact.middleName = nameComponents[2].isEmpty ? nil : nameComponents[2] }
                if nameComponents.count > 4 { contact.nameSuffix = nameComponents[4].isEmpty ? nil : nameComponents[4] }
            } else if key.hasPrefix("FN") {
                // Already handled by N field
            } else if key.hasPrefix("NICKNAME") {
                contact.nickname = value
            } else if key.hasPrefix("ORG") {
                let orgComponents = value.components(separatedBy: ";")
                if orgComponents.count > 0 { contact.organizationName = orgComponents[0] }
                if orgComponents.count > 1 { contact.departmentName = orgComponents[1] }
            } else if key.hasPrefix("TITLE") {
                contact.jobTitle = value
            } else if key.hasPrefix("TEL") {
                let label = extractLabel(from: key) ?? "other"
                contact.phoneNumbers.append(ContactPhoneNumber(label: label, value: value))
            } else if key.hasPrefix("EMAIL") {
                let label = extractLabel(from: key) ?? "other"
                contact.emailAddresses.append(ContactEmailAddress(label: label, value: value))
            } else if key.hasPrefix("BDAY") {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                contact.birthday = formatter.date(from: value)
            } else if key.hasPrefix("NOTE") {
                contact.note = value.replacingOccurrences(of: "\\n", with: "\n")
            }
        }

        return contact
    }

    private static func extractLabel(from key: String) -> String? {
        let components = key.components(separatedBy: ";")
        for component in components {
            if component.hasPrefix("TYPE=") {
                return component.replacingOccurrences(of: "TYPE=", with: "").lowercased()
            }
        }
        return nil
    }
}

//
//  DuplicateReviewSheet.swift
//  Vecka
//
//  情報デザイン compliant duplicate contact review sheet
//

import SwiftUI
import SwiftData

// MARK: - Duplicate Suggestion Banner

/// A non-aggressive banner that appears when potential duplicate contacts are detected
/// 情報デザイン: Orange accent for warnings, tappable to review
struct DuplicateSuggestionBanner: View {
    let suggestionCount: Int
    let onTap: () -> Void

    private let warningColor = JohoColors.orange

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // LEFT: Warning icon zone
                Image(systemName: "person.2.badge.key.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(warningColor)
                    .frame(width: 44, height: 44)
                    .background(warningColor.opacity(0.2))

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // CENTER: Message
                VStack(alignment: .leading, spacing: 2) {
                    Text("POSSIBLE DUPLICATES")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text("\(suggestionCount) contact\(suggestionCount == 1 ? "" : "s") may be duplicated")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)

                Spacer()

                // RIGHT: Count badge and chevron
                HStack(spacing: JohoDimensions.spacingSM) {
                    Text("\(suggestionCount)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(warningColor)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.trailing, JohoDimensions.spacingMD)
            }
            .frame(height: 56)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(warningColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duplicate Review Sheet

/// Full-screen sheet to review and resolve duplicate contacts
struct DuplicateReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    @State private var suggestions: [DuplicateSuggestion] = []
    @State private var selectedSuggestion: DuplicateSuggestion?
    @State private var showingMergeSheet = false

    private let duplicateManager = DuplicateContactManager.shared
    private let warningColor = JohoColors.orange

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Header with close button
                    reviewHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Main content card
                    VStack(spacing: 0) {
                        // Title with icon
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: "person.2.badge.key.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(warningColor)
                                .frame(width: 40, height: 40)
                                .background(warningColor.opacity(0.2))
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
                                )

                            Text("REVIEW DUPLICATES")
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)

                            Spacer()

                            // Count badge
                            Text("\(suggestions.count)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(JohoColors.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(warningColor)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(height: 1.5)

                        // Suggestions list
                        if suggestions.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: JohoDimensions.spacingSM) {
                                ForEach(suggestions, id: \.id) { suggestion in
                                    duplicatePairRow(for: suggestion)
                                }
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
            .onAppear {
                loadSuggestions()
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                if let contact1 = findContact(id: suggestion.contact1Id),
                   let contact2 = findContact(id: suggestion.contact2Id) {
                    MergeContactSheet(
                        suggestion: suggestion,
                        contact1: contact1,
                        contact2: contact2,
                        onMerge: { primary, secondary in
                            performMerge(suggestion: suggestion, primary: primary, secondary: secondary)
                        },
                        onDismiss: {
                            dismissSuggestion(suggestion)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var reviewHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Done")
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(JohoColors.green)

            Text("NO DUPLICATES")
                .font(JohoFont.headline)
                .foregroundStyle(JohoColors.black)

            Text("All contacts are unique")
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingLG)
    }

    // MARK: - Duplicate Pair Row

    private func duplicatePairRow(for suggestion: DuplicateSuggestion) -> some View {
        Button {
            selectedSuggestion = suggestion
        } label: {
            VStack(spacing: 0) {
                // Score and match reasons header
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Score badge (color-coded)
                    scoreIndicator(score: suggestion.score)

                    // Match reason icons
                    HStack(spacing: 4) {
                        ForEach(suggestion.matchReasonsArray, id: \.self) { reason in
                            if let matchReason = DuplicateMatchReason(rawValue: reason) {
                                Image(systemName: matchReason.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(JohoDimensions.spacingSM)
                .background(warningColor.opacity(0.1))

                // Divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1)

                // Contact pair
                if let contact1 = findContact(id: suggestion.contact1Id),
                   let contact2 = findContact(id: suggestion.contact2Id) {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Contact 1
                        contactPreview(contact: contact1)

                        // Versus indicator
                        Text("VS")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(warningColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(warningColor.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))

                        // Contact 2
                        contactPreview(contact: contact2)
                    }
                    .padding(JohoDimensions.spacingSM)
                }
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Score Indicator

    private func scoreIndicator(score: Int) -> some View {
        let color: Color = {
            if score >= 80 { return JohoColors.red }
            if score >= 60 { return warningColor }
            return JohoColors.yellow
        }()

        return Text("\(score)%")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(JohoColors.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
    }

    // MARK: - Contact Preview

    private func contactPreview(contact: Contact) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            JohoContactAvatar(contact: contact, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(contact.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                if !contact.phoneNumbers.isEmpty {
                    Text(contact.phoneNumbers[0].value)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func loadSuggestions() {
        suggestions = duplicateManager.loadPendingSuggestions(modelContext: modelContext)
    }

    private func findContact(id: UUID) -> Contact? {
        contacts.first { $0.id == id }
    }

    private func performMerge(suggestion: DuplicateSuggestion, primary: Contact, secondary: Contact) {
        duplicateManager.mergeContacts(
            primary: primary,
            secondary: secondary,
            suggestion: suggestion,
            modelContext: modelContext
        )
        loadSuggestions()
    }

    private func dismissSuggestion(_ suggestion: DuplicateSuggestion) {
        duplicateManager.dismissSuggestion(suggestion, modelContext: modelContext)
        loadSuggestions()
    }
}

// MARK: - Merge Contact Sheet

/// Sheet to confirm and choose primary contact for merging
struct MergeContactSheet: View {
    @Environment(\.dismiss) private var dismiss

    let suggestion: DuplicateSuggestion
    let contact1: Contact
    let contact2: Contact
    let onMerge: (Contact, Contact) -> Void
    let onDismiss: () -> Void

    @State private var selectedPrimary: Contact?

    private let warningColor = JohoColors.orange
    private let accentColor = PageHeaderColor.contacts.accent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Header buttons (floating)
                    mergeHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Main content card
                    VStack(spacing: 0) {
                        // Title
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(accentColor)
                                .frame(width: 40, height: 40)
                                .background(accentColor.opacity(0.2))
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: 1.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("MERGE CONTACTS")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Text("Select the primary contact to keep")
                                    .font(JohoFont.labelSmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(height: 1.5)

                        // Contact selection
                        VStack(spacing: JohoDimensions.spacingSM) {
                            contactSelectionCard(contact: contact1, isSelected: selectedPrimary?.id == contact1.id) {
                                selectedPrimary = contact1
                            }

                            contactSelectionCard(contact: contact2, isSelected: selectedPrimary?.id == contact2.id) {
                                selectedPrimary = contact2
                            }
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(height: 1.5)

                        // Merge preview
                        if let primary = selectedPrimary {
                            let secondary = primary.id == contact1.id ? contact2 : contact1
                            mergePreview(primary: primary, secondary: secondary)
                                .padding(JohoDimensions.spacingMD)
                        } else {
                            Text("Select a contact above to see merge preview")
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(JohoDimensions.spacingLG)
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
        }
    }

    // MARK: - Merge Header (floating buttons)

    private var mergeHeader: some View {
        HStack {
            // NOT DUPLICATES button
            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Not Duplicates")
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

            // MERGE button
            Button {
                guard let primary = selectedPrimary else { return }
                let secondary = primary.id == contact1.id ? contact2 : contact1
                onMerge(primary, secondary)
                dismiss()
            } label: {
                Text("Merge")
                    .font(JohoFont.body.bold())
                    .foregroundStyle(selectedPrimary != nil ? JohoColors.white : JohoColors.black.opacity(0.4))
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.vertical, JohoDimensions.spacingMD)
                    .background(selectedPrimary != nil ? accentColor : JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedPrimary == nil)
        }
    }

    // MARK: - Contact Selection Card

    private func contactSelectionCard(contact: Contact, isSelected: Bool, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : JohoColors.white)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(JohoColors.white)
                    }
                }

                // Avatar
                JohoContactAvatar(contact: contact, size: 48)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(JohoFont.body.bold())
                        .foregroundStyle(JohoColors.black)

                    if let org = contact.organizationName, !org.isEmpty {
                        Text(org)
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }

                    // Stats
                    HStack(spacing: JohoDimensions.spacingSM) {
                        if !contact.phoneNumbers.isEmpty {
                            statBadge(icon: "phone.fill", count: contact.phoneNumbers.count)
                        }
                        if !contact.emailAddresses.isEmpty {
                            statBadge(icon: "envelope.fill", count: contact.emailAddresses.count)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    JohoPill(text: "PRIMARY", style: .coloredInverted(accentColor), size: .small)
                }
            }
            .padding(JohoDimensions.spacingMD)
            .background(isSelected ? accentColor.opacity(0.1) : JohoColors.inputBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(isSelected ? accentColor : JohoColors.black, lineWidth: isSelected ? 2.5 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func statBadge(icon: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text("\(count)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(JohoColors.black.opacity(0.6))
    }

    // MARK: - Merge Preview

    private func mergePreview(primary: Contact, secondary: Contact) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            JohoPill(text: "MERGE PREVIEW", style: .whiteOnBlack, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                previewRow(label: "Name", value: primary.displayName)

                let totalPhones = Set(
                    primary.phoneNumbers.map { $0.value } +
                    secondary.phoneNumbers.map { $0.value }
                ).count
                if totalPhones > 0 {
                    previewRow(label: "Phone numbers", value: "\(totalPhones)")
                }

                let totalEmails = Set(
                    primary.emailAddresses.map { $0.value.lowercased() } +
                    secondary.emailAddresses.map { $0.value.lowercased() }
                ).count
                if totalEmails > 0 {
                    previewRow(label: "Email addresses", value: "\(totalEmails)")
                }

                if primary.birthday != nil || secondary.birthday != nil {
                    let bdayText = (primary.birthday ?? secondary.birthday)?.formatted(.dateTime.month(.wide).day()) ?? "?"
                    previewRow(label: "Birthday", value: bdayText)
                }

                previewRow(label: "Photo", value: (primary.imageData ?? secondary.imageData) != nil ? "Yes" : "No")
            }
            .padding(JohoDimensions.spacingSM)
            .background(JohoColors.inputBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(JohoColors.black, lineWidth: 1)
            )

            Text("The secondary contact will be deleted after merge.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(warningColor)
        }
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
        }
    }
}

// MARK: - Preview

#Preview("Duplicate Banner") {
    VStack {
        DuplicateSuggestionBanner(suggestionCount: 3) {
            print("Banner tapped")
        }
        .padding()
    }
    .johoBackground()
}

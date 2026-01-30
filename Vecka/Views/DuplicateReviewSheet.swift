//
//  DuplicateReviewSheet.swift
//  Vecka
//
//  情報デザイン compliant duplicate contact review sheet
//

import SwiftUI
import SwiftData

// MARK: - Duplicate Suggestion Banner

/// A friendly banner that appears when potential duplicate contacts are detected
/// 情報デザイン: Soft styling, clear action
struct DuplicateSuggestionBanner: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let suggestionCount: Int
    let onTap: () -> Void

    private let accentColor = JohoColors.purple

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Icon
                Image(systemName: "person.2.badge.gearshape")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)

                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean up duplicates")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.primary)

                    Text("\(suggestionCount) possible duplicate\(suggestionCount == 1 ? "" : "s") found")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                }

                Spacer()

                // Action button
                Text("Review")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(accentColor.opacity(0.08))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
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
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    @Query(sort: \Contact.familyName) private var contacts: [Contact]

    @State private var suggestions: [DuplicateSuggestion] = []
    @State private var duplicateClusters: [[Contact]] = []  // Grouped duplicates
    @State private var selectedClusterIndex: Int?
    @State private var showingClusterMerge = false

    private let duplicateManager = DuplicateContactManager.shared
    private let accentColor = PageHeaderColor.contacts.accent

    /// Groups related duplicate suggestions into clusters
    /// If A-B and B-C are duplicates, they form one cluster [A, B, C]
    private func buildClusters() {
        var unionFind: [UUID: UUID] = [:]  // parent pointers

        // Find function with path compression
        func find(_ id: UUID) -> UUID {
            if unionFind[id] == nil {
                unionFind[id] = id
            }
            guard let parent = unionFind[id] else { return id }
            if parent != id {
                let root = find(parent)
                unionFind[id] = root
                return root
            }
            return parent
        }

        // Union function
        func union(_ id1: UUID, _ id2: UUID) {
            let root1 = find(id1)
            let root2 = find(id2)
            if root1 != root2 {
                unionFind[root1] = root2
            }
        }

        // Build unions from all suggestions
        for suggestion in suggestions {
            union(suggestion.contact1Id, suggestion.contact2Id)
        }

        // Group contacts by their root
        var groups: [UUID: Set<UUID>] = [:]
        for suggestion in suggestions {
            let root = find(suggestion.contact1Id)
            groups[root, default: []].insert(suggestion.contact1Id)
            groups[root, default: []].insert(suggestion.contact2Id)
        }

        // Convert to Contact arrays (only include existing contacts)
        let contactDict = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0) })
        duplicateClusters = groups.values.compactMap { ids in
            let clusterContacts = ids.compactMap { contactDict[$0] }
            return clusterContacts.count >= 2 ? clusterContacts.sorted { $0.displayName < $1.displayName } : nil
        }.sorted { $0.count > $1.count }  // Largest clusters first
    }

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
                        // Simple header
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: "person.2.badge.gearshape")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Duplicate contacts")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.primary)

                                Text("\(duplicateClusters.count) group\(duplicateClusters.count == 1 ? "" : "s") to review")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.5))
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(colors.primary.opacity(0.1))
                            .frame(height: 1)

                        // Clusters list (grouped duplicates)
                        if duplicateClusters.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: JohoDimensions.spacingSM) {
                                ForEach(Array(duplicateClusters.enumerated()), id: \.offset) { index, cluster in
                                    duplicateClusterRow(cluster: cluster, index: index)
                                }
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
            .onAppear {
                loadSuggestions()
                buildClusters()
            }
            .sheet(isPresented: $showingClusterMerge) {
                if let index = selectedClusterIndex, index < duplicateClusters.count {
                    ClusterMergeSheet(
                        cluster: duplicateClusters[index],
                        onMerge: { primary, secondaries in
                            performClusterMerge(primary: primary, secondaries: secondaries)
                        },
                        onDismissAll: {
                            if let idx = selectedClusterIndex, idx < duplicateClusters.count {
                                dismissCluster(duplicateClusters[idx])
                            }
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.green)

            Text("NO DUPLICATES")
                .font(JohoFont.headline)
                .foregroundStyle(colors.primary)

            Text("All contacts are unique")
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary.opacity(0.6))
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingLG)
    }

    // MARK: - Duplicate Cluster Row (Clean grouped view)

    private func duplicateClusterRow(cluster: [Contact], index: Int) -> some View {
        Button {
            selectedClusterIndex = index
            showingClusterMerge = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Stacked contact previews with overlapping avatars
                HStack(spacing: -8) {
                    // Overlapping avatars
                    ForEach(Array(cluster.prefix(4).enumerated()), id: \.element.id) { idx, contact in
                        JohoContactAvatar(contact: contact, size: 36)
                            .overlay(
                                Circle().stroke(colors.surface, lineWidth: 2)
                            )
                            .zIndex(Double(cluster.count - idx))
                    }
                    if cluster.count > 4 {
                        Text("+\(cluster.count - 4)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(colors.inputBackground)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(colors.surface, lineWidth: 2))
                    }

                    Spacer()

                    // Quick merge indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Text("Merge")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.top, JohoDimensions.spacingMD)

                // Names list
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(cluster.prefix(3), id: \.id) { contact in
                        HStack(spacing: 6) {
                            Text(contact.displayName)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)

                            if !contact.phoneNumbers.isEmpty {
                                Text("•")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.3))
                                Text(contact.phoneNumbers[0].value)
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.5))
                                    .lineLimit(1)
                            }
                        }
                    }
                    if cluster.count > 3 {
                        Text("+ \(cluster.count - 3) more")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
            .padding(.bottom, JohoDimensions.spacingSM)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(colors.border.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contact Preview

    private func contactPreview(contact: Contact) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            JohoContactAvatar(contact: contact, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(contact.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                if !contact.phoneNumbers.isEmpty {
                    Text(contact.phoneNumbers[0].value)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
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

    /// Merge all secondary contacts into the primary contact
    private func performClusterMerge(primary: Contact, secondaries: [Contact]) {
        // Find all suggestions involving these contacts
        let clusterIds = Set([primary.id] + secondaries.map(\.id))

        for secondary in secondaries {
            // Find the suggestion for this pair
            if let suggestion = suggestions.first(where: {
                ($0.contact1Id == primary.id && $0.contact2Id == secondary.id) ||
                ($0.contact1Id == secondary.id && $0.contact2Id == primary.id)
            }) {
                duplicateManager.mergeContacts(
                    primary: primary,
                    secondary: secondary,
                    suggestion: suggestion,
                    modelContext: modelContext
                )
            } else {
                // No suggestion for this pair, just delete the secondary
                modelContext.delete(secondary)
            }
        }

        // Dismiss any remaining suggestions involving merged contacts
        for suggestion in suggestions {
            if clusterIds.contains(suggestion.contact1Id) || clusterIds.contains(suggestion.contact2Id) {
                if suggestion.status == "pending" {
                    suggestion.status = "merged"
                    suggestion.decidedAt = Date()
                }
            }
        }

        try? modelContext.save()
        loadSuggestions()
        buildClusters()
    }

    /// Dismiss all suggestions for contacts in a cluster (mark as "not duplicates")
    private func dismissCluster(_ cluster: [Contact]) {
        let clusterIds = Set(cluster.map(\.id))

        // Find all suggestions involving these contacts and dismiss them
        for suggestion in suggestions {
            if clusterIds.contains(suggestion.contact1Id) && clusterIds.contains(suggestion.contact2Id) {
                duplicateManager.dismissSuggestion(suggestion, modelContext: modelContext)
            }
        }

        loadSuggestions()
        buildClusters()
    }
}

// MARK: - Merge Contact Sheet

/// Sheet to confirm and choose primary contact for merging
struct MergeContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let suggestion: DuplicateSuggestion
    let contact1: Contact
    let contact2: Contact
    let onMerge: (Contact, Contact) -> Void
    let onDismiss: () -> Void

    @State private var selectedPrimary: Contact?

    private let warningColor = JohoColors.cyan
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
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .frame(width: 40, height: 40)
                                .background(accentColor.opacity(0.2))
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: 1.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("MERGE CONTACTS")
                                    .font(JohoFont.headline)
                                    .foregroundStyle(colors.primary)

                                Text("Select the primary contact to keep")
                                    .font(JohoFont.labelSmall)
                                    .foregroundStyle(colors.primary.opacity(0.6))
                            }

                            Spacer()
                        }
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(colors.border)
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
                            .fill(colors.border)
                            .frame(height: 1.5)

                        // Merge preview
                        if let primary = selectedPrimary {
                            let secondary = primary.id == contact1.id ? contact2 : contact1
                            mergePreview(primary: primary, secondary: secondary)
                                .padding(JohoDimensions.spacingMD)
                        } else {
                            Text("Select a contact above to see merge preview")
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(colors.primary.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(JohoDimensions.spacingLG)
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

            // MERGE button
            Button {
                guard let primary = selectedPrimary else { return }
                let secondary = primary.id == contact1.id ? contact2 : contact1
                onMerge(primary, secondary)
                dismiss()
            } label: {
                Text("Merge")
                    .font(JohoFont.body.bold())
                    .foregroundStyle(selectedPrimary != nil ? colors.surfaceInverted : colors.primary.opacity(0.4))
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.vertical, JohoDimensions.spacingMD)
                    .background(selectedPrimary != nil ? accentColor : colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: 1.5)
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
                        .fill(isSelected ? accentColor : colors.surface)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(colors.border, lineWidth: 2))

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.surfaceInverted)
                    }
                }

                // Avatar
                JohoContactAvatar(contact: contact, size: 48)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(JohoFont.body.bold())
                        .foregroundStyle(colors.primary)

                    if let org = contact.organizationName, !org.isEmpty {
                        Text(org)
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(colors.primary.opacity(0.6))
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
            .background(isSelected ? accentColor.opacity(0.1) : colors.inputBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(isSelected ? accentColor : colors.border, lineWidth: isSelected ? 2.5 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func statBadge(icon: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold, design: .rounded))
            Text("\(count)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(colors.primary.opacity(0.6))
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
            .background(colors.inputBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border, lineWidth: 1)
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
                .foregroundStyle(colors.primary.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
        }
    }
}

// MARK: - Cluster Merge Sheet (Multi-contact merge)

/// Sheet to merge multiple duplicate contacts at once - simplified UX
struct ClusterMergeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let cluster: [Contact]
    let onMerge: (Contact, [Contact]) -> Void  // (primary, secondaries)
    let onDismissAll: () -> Void

    @State private var selectedPrimary: Contact?

    private let accentColor = PageHeaderColor.contacts.accent

    // Auto-select the most complete contact
    private var suggestedPrimary: Contact? {
        cluster.max { contactScore($0) < contactScore($1) }
    }

    // Score a contact by completeness
    private func contactScore(_ contact: Contact) -> Int {
        var score = 0
        if contact.imageData != nil { score += 10 }
        score += contact.phoneNumbers.count * 3
        score += contact.emailAddresses.count * 2
        if contact.birthday != nil { score += 5 }
        if contact.organizationName?.isEmpty == false { score += 2 }
        if !contact.givenName.isEmpty && !contact.familyName.isEmpty { score += 2 }
        return score
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Header buttons - simplified
                    clusterMergeHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Main content card - cleaner layout
                    VStack(spacing: 0) {
                        // Simple header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Merge \(cluster.count) contacts")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(colors.primary)

                            Text("Choose which contact to keep. Information from others will be merged in.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(JohoDimensions.spacingMD)

                        // Divider
                        Rectangle()
                            .fill(colors.primary.opacity(0.1))
                            .frame(height: 1)

                        // Contact selection (simplified cards)
                        VStack(spacing: JohoDimensions.spacingSM) {
                            ForEach(cluster, id: \.id) { contact in
                                let isRecommended = contact.id == suggestedPrimary?.id
                                simpleContactCard(
                                    contact: contact,
                                    isSelected: selectedPrimary?.id == contact.id,
                                    isRecommended: isRecommended
                                ) {
                                    selectedPrimary = contact
                                }
                            }
                        }
                        .padding(JohoDimensions.spacingMD)

                        // What will happen (only show when selected)
                        if let primary = selectedPrimary {
                            let secondaries = cluster.filter { $0.id != primary.id }

                            Rectangle()
                                .fill(colors.primary.opacity(0.1))
                                .frame(height: 1)

                            // Simple merge summary
                            HStack(spacing: JohoDimensions.spacingSM) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.4))

                                Text("\(secondaries.count) contact\(secondaries.count == 1 ? "" : "s") will be merged and removed")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.5))

                                Spacer()
                            }
                            .padding(JohoDimensions.spacingMD)
                        }
                    }
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
                .padding(.bottom, JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                // Auto-select the recommended contact
                if selectedPrimary == nil {
                    selectedPrimary = suggestedPrimary
                }
            }
        }
    }

    // Simple contact card - cleaner than the complex one
    private func simpleContactCard(contact: Contact, isSelected: Bool, isRecommended: Bool, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Selection radio
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : colors.surface)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(isSelected ? accentColor : colors.border.opacity(0.5), lineWidth: isSelected ? 0 : 1.5))

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.surfaceInverted)
                    }
                }

                // Avatar
                JohoContactAvatar(contact: contact, size: 40)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(contact.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .lineLimit(1)

                        if isRecommended {
                            Text("Recommended")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(JohoColors.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(JohoColors.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Contact summary
                    HStack(spacing: 8) {
                        if !contact.phoneNumbers.isEmpty {
                            Text("\(contact.phoneNumbers.count) phone")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                        if !contact.emailAddresses.isEmpty {
                            Text("\(contact.emailAddresses.count) email")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                        if contact.birthday != nil {
                            Text("birthday")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(JohoColors.pink.opacity(0.7))
                        }
                        if contact.imageData != nil {
                            Text("photo")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                    }
                }

                Spacer()
            }
            .padding(JohoDimensions.spacingSM)
            .background(isSelected ? accentColor.opacity(0.08) : colors.inputBackground.opacity(0.5))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(isSelected ? accentColor.opacity(0.5) : colors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header (simplified)

    private var clusterMergeHeader: some View {
        HStack {
            // Cancel / Not duplicates
            Button {
                onDismissAll()
                dismiss()
            } label: {
                Text("Not duplicates")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(colors.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(colors.border.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            // Merge button - always visible, enabled when selected
            Button {
                guard let primary = selectedPrimary else { return }
                let secondaries = cluster.filter { $0.id != primary.id }
                onMerge(primary, secondaries)
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.merge")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text("Merge")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(selectedPrimary != nil ? colors.primaryInverted : colors.primary.opacity(0.3))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selectedPrimary != nil ? accentColor : colors.inputBackground)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedPrimary == nil)
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

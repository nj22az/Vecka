//
//  SpecialDayDetailSheet.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Special Day Detail Sheet
//  Half-sheet modal for viewing holiday/memo details
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 情報デザイン: Special day detail sheet shown on tap
/// Displays details for a single SpecialDayRow
struct SpecialDayDetailSheet: View {
    let item: SpecialDayRow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Share customization state (temporary, not persisted)
    @State private var showIconPicker = false
    @State private var customIcon: String? = nil
    @State private var personalNote: String = ""
    @State private var showShareOptions = false

    // Permanent icon editing state
    @State private var showPermanentIconPicker = false
    @State private var permanentIconSelection: String = ""

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    /// Full date stamp for shareable: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: item.date)
        return "\(formatter.string(from: item.date)) · W\(weekNumber)"
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? item.symbolName ?? item.type.defaultIcon
    }

    private var defaultIcon: String {
        item.symbolName ?? item.type.defaultIcon
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar with type code
            header

            // Content
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Icon zone
                    iconZone

                    // Divider
                    Rectangle()
                        .fill(colors.border)
                        .frame(height: 2)
                        .padding(.horizontal, JohoDimensions.spacingLG)

                    // Title
                    Text(item.title)
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, JohoDimensions.spacingLG)

                    // Details section
                    detailsSection

                    // Item icon editing section (persists to model)
                    itemIconSection

                    // Share options section
                    shareOptionsSection

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.top, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingLG)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.surface)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .sheet(isPresented: $showIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: Binding(
                    get: { customIcon ?? defaultIcon },
                    set: { customIcon = $0 }
                ),
                accentColor: item.type.accentColor,
                lightBackground: item.type.lightBackground,
                onDone: {}
            )
        }
        .sheet(isPresented: $showPermanentIconPicker) {
            JohoSFSymbolPickerSheet(
                selectedSymbol: $permanentIconSelection,
                accentColor: CategoryColorSettings.shared.color(for: item.type.displayCategory),
                lightBackground: CategoryColorSettings.shared.color(for: item.type.displayCategory).opacity(0.2),
                onDone: {
                    savePermanentIcon(permanentIconSelection)
                }
            )
        }
        .onAppear {
            permanentIconSelection = item.symbolName ?? item.type.defaultIcon
        }
    }

    // MARK: - Item Icon Section (Persistent)

    private var itemIconSection: some View {
        VStack(spacing: 0) {
            Button {
                showPermanentIconPicker = true
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CategoryColorSettings.shared.color(for: item.type.displayCategory))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        Text("ITEM ICON")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: item.symbolName ?? item.type.defaultIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(CategoryColorSettings.shared.color(for: item.type.displayCategory))

                        if item.symbolName != nil {
                            Text("CUSTOM")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.primary.opacity(0.3))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Save Permanent Icon

    private func savePermanentIcon(_ iconName: String) {
        // Determine if it's a holiday/observance or a memo
        if item.isMemo {
            // Find and update Memo - ruleID is UUID string
            guard let targetUUID = UUID(uuidString: item.ruleID) else { return }
            let descriptor = FetchDescriptor<Memo>(predicate: #Predicate { memo in
                memo.id == targetUUID
            })
            if let memos = try? modelContext.fetch(descriptor), let memo = memos.first {
                memo.symbolName = iconName == item.type.defaultIcon ? nil : iconName
                try? modelContext.save()
                HapticManager.notification(.success)
            }
        } else {
            // Find and update HolidayRule - ruleID matches rule.id directly
            let targetID = item.ruleID
            let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate { rule in
                rule.id == targetID
            })
            if let rules = try? modelContext.fetch(descriptor), let rule = rules.first {
                rule.symbolName = iconName == item.type.defaultIcon ? nil : iconName
                rule.userModifiedAt = Date()
                try? modelContext.save()
                // Refresh holiday cache
                HolidayManager.shared.calculateAndCacheHolidays(context: modelContext, focusYear: Calendar.current.component(.year, from: item.date))
                HapticManager.notification(.success)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Type code pill
            Text(item.type.code)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colors.primary)
                .clipShape(Capsule())

            Spacer()

            // Share button
            if #available(iOS 16.0, *) {
                SpecialDayShareButton(
                    item: item,
                    customIcon: customIcon,
                    personalNote: personalNote.isEmpty ? nil : personalNote
                )
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .frame(width: 32, height: 32)
                    .background(colors.primary.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.primary)
    }

    // MARK: - Icon Zone

    private var iconZone: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: displayIcon)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(item.type.accentColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(item.type.lightBackground)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 0) {
            // Date row
            detailRow(
                label: "DATE",
                value: dateFormatter.string(from: item.date)
            )

            // Divider
            Rectangle()
                .fill(colors.primary.opacity(0.15))
                .frame(height: 1)

            // Region row (if present)
            if item.hasCountryPill {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Text("REGION")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .frame(width: 60, alignment: .leading)

                    CountryPill(region: item.region)

                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

                // Divider
                Rectangle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(height: 1)
            }

            // Birthday age (if applicable)
            if item.type == .birthday, let age = item.turningAge {
                detailRow(
                    label: "AGE",
                    value: birthdayDisplayText(age: age, date: item.date)
                )

                // Divider
                Rectangle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(height: 1)
            }

            // Notes row (if present)
            if let notes = item.notes, !notes.isEmpty, notes != item.title {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                    Text("NOTES")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))

                    Text(notes)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }

            // Days until/ago
            let daysText = daysUntilText
            if !daysText.isEmpty {
                detailRow(label: "STATUS", value: daysText)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Share Options Section

    private var shareOptionsSection: some View {
        VStack(spacing: 0) {
            // Share options toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showShareOptions.toggle()
                }
            } label: {
                HStack {
                    Text("SHARE OPTIONS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: showShareOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showShareOptions {
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1)

                VStack(spacing: 0) {
                    // Icon picker row
                    Button {
                        showIconPicker = true
                    } label: {
                        HStack {
                            Text("ICON")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))

                            Spacer()

                            Image(systemName: displayIcon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(item.type.accentColor)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(colors.primary.opacity(0.3))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(colors.border.opacity(0.3))
                        .frame(height: 1)

                    // Personal note field
                    HStack {
                        Text("NOTE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        TextField("Add personal note...", text: $personalNote)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)

                    Rectangle()
                        .fill(colors.border.opacity(0.3))
                        .frame(height: 1)

                    // Date stamp preview
                    HStack {
                        Text("DATE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        Spacer()

                        Text(fullDateStamp)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(colors.primary.opacity(0.7))
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
                }
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.5))
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)

            Spacer()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    private var daysUntilText: String {
        let days = item.daysUntil
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days == -1 {
            return "Yesterday"
        } else if days > 0 {
            return "In \(days) days"
        } else {
            return "\(abs(days)) days ago"
        }
    }
}

// MARK: - Special Day Share Button

@available(iOS 16.0, *)
struct SpecialDayShareButton: View {
    let item: SpecialDayRow
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var snapshot: SpecialDaySnapshot {
        SpecialDaySnapshot(
            item: item,
            size: CGSize(width: 340, height: 0),
            customIcon: customIcon,
            personalNote: personalNote
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                item.title,
                image: Image(systemName: customIcon ?? item.type.defaultIcon)
            )
        ) {
            ZStack {
                Circle()
                    .fill(colors.surface)
                    .frame(width: 32, height: 32)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Special Day Snapshot (Transferable)

@available(iOS 16.0, *)
struct SpecialDaySnapshot: Transferable {
    let item: SpecialDayRow
    let size: CGSize
    var customIcon: String? = nil
    var personalNote: String? = nil

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    @MainActor
    func renderToPNG() -> Data {
        let renderer = ImageRenderer(content: shareableView())
        renderer.scale = 3.0
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }

    @MainActor
    func shareableView() -> some View {
        ShareableSpecialDayCard(
            item: item,
            customIcon: customIcon,
            personalNote: personalNote
        )
        .frame(width: size.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shareable Special Day Card (情報デザイン: Consistent with other shareable cards)

struct ShareableSpecialDayCard: View {
    let item: SpecialDayRow
    var customIcon: String? = nil
    var personalNote: String? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// The icon to display (custom or default)
    private var displayIcon: String {
        customIcon ?? item.symbolName ?? item.type.defaultIcon
    }

    /// Full date stamp: YYYYMMDD · W{n}
    private var fullDateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: item.date)
        return "\(formatter.string(from: item.date)) · W\(weekNumber)"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: item.date)
    }

    var body: some View {
        ZStack {
            // Layer 1: Solid background
            cardShape.fill(colors.surface)

            // Layer 2: Content
            VStack(spacing: 0) {
                // HEADER: Branding + icon
                HStack(spacing: 0) {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                        Text("ONSEN PLANNER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // Icon (customizable)
                    Image(systemName: displayIcon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(item.type.accentColor)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(item.type.lightBackground)

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // DATE STAMP row
                HStack {
                    Text(fullDateStamp)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(colors.primary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.surface)

                // Divider
                Rectangle().fill(colors.border).frame(height: 1)

                // MAIN CONTENT: Large icon + text
                HStack(alignment: .top, spacing: 0) {
                    // LEFT: Large icon (customizable)
                    VStack {
                        Spacer()
                        Image(systemName: displayIcon)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(item.type.accentColor)
                        Spacer()
                    }
                    .frame(width: 100)
                    .frame(minHeight: 120)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)

                    // RIGHT: Text content
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text(formattedDate)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text(item.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .multilineTextAlignment(.leading)

                        // Personal note (if provided)
                        if let note = personalNote, !note.isEmpty {
                            Rectangle()
                                .fill(colors.border.opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 4)

                            Text(note)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.5))
                                .italic()
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120)
                .background(item.type.lightBackground.opacity(0.5))

                // Divider
                Rectangle().fill(colors.border).frame(height: 2)

                // FOOTER
                HStack {
                    HStack(spacing: 4) {
                        Text(item.type.code)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .tracking(1)

                        if item.hasCountryPill {
                            Text("·")
                                .foregroundStyle(colors.primary.opacity(0.3))
                            Text(item.region.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                    }

                    Spacer()

                    Text("ONSEN PLANNER")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.3))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape.strokeBorder(colors.border, lineWidth: 3)
        }
    }
}

// MARK: - Preview

#Preview {
    SpecialDayDetailSheet(
        item: SpecialDayRow(
            id: "preview-1",
            ruleID: "preview-rule",
            region: "SE",
            date: Date(),
            title: "New Year's Day",
            type: .holiday,
            symbolName: "star.fill",
            iconColor: nil,
            notes: "Public holiday in Sweden. Offices and shops are closed.",
            isCustom: false,
            isMemo: false,
            originalBirthday: nil,
            turningAge: nil
        )
    )
}

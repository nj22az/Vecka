//
//  CountdownListView.swift
//  Vecka
//
//  Events management view with 情報デザイン (Jōhō Dezain) bento styling
//  Uses purple EVT color scheme from design system
//  All events are custom - no predefined events
//

import SwiftUI

struct CountdownListView: View {
    @State private var customCountdowns: [CustomCountdown] = []
    @State private var showAddEvent = false
    @State private var selectedCountdown: CountdownType = .custom

    // State for new event dialog
    @State private var newEventName: String = ""
    @State private var newEventDate: Date = Date()
    @State private var newEventIsAnnual: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Page header in white container
                headerSection

                // Next Up Section (hero event) - only custom events
                if let nextEvent = nextUpcomingEvent {
                    nextUpSection(nextEvent)
                }

                // All Events Bento Section (custom only)
                eventsSection

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadCustomCountdowns()
        }
        .sheet(isPresented: $showAddEvent) {
            NavigationStack {
                CustomCountdownDialog(
                    name: $newEventName,
                    date: $newEventDate,
                    isAnnual: $newEventIsAnnual,
                    selectedCountdown: $selectedCountdown,
                    onSave: {
                        loadCustomCountdowns()
                        newEventName = ""
                        newEventDate = Date()
                        newEventIsAnnual = false
                    }
                )
            }
            .presentationCornerRadius(16)
        }
    }

    // MARK: - Header Section (情報デザイン: Icon zone like Star Page months)

    private var headerSection: some View {
        HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
            // Icon zone (52×52pt) - matches Star Page month detail pattern
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .johoTouchTarget(52)
                .background(JohoColors.purple.opacity(0.3))
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )

            // Title area
            VStack(alignment: .leading, spacing: 2) {
                Text("EVENTS")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)

                Text("\(customCountdowns.count) event\(customCountdowns.count == 1 ? "" : "s")")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.7))
            }

            Spacer()

            Button {
                showAddEvent = true
            } label: {
                JohoActionButton(icon: "plus")
            }
        }
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Computed Properties

    private var nextUpcomingEvent: (name: String, icon: String, days: Int, date: Date)? {
        let currentYear = Calendar.iso8601.component(.year, from: Date())
        var allEvents: [(name: String, icon: String, days: Int, date: Date)] = []

        // Only custom events - no predefined
        for custom in customCountdowns {
            if let target = custom.computeTargetDate(for: currentYear) {
                let days = daysUntil(target)
                if days >= 0 {
                    allEvents.append((custom.name, custom.iconName ?? "calendar.badge.clock", days, target))
                }
            }
        }

        return allEvents.min(by: { $0.days < $1.days })
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.iso8601
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day ?? 0
    }

    // MARK: - Next Up Section (Hero Card - matches Star page CollapsibleSpecialDayCard)

    @ViewBuilder
    private func nextUpSection(_ event: (name: String, icon: String, days: Int, date: Date)) -> some View {
        VStack(spacing: 0) {
            // 情報デザイン: Bento header with icon in RIGHT compartment
            HStack(spacing: 0) {
                JohoPill(text: "NEXT UP", style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Event icon compartment (uses actual event icon)
                Image(systemName: event.icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(JohoColors.purple.opacity(0.7))  // Light purple header (情報デザイン bento)

            // Horizontal divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Hero content (matches Star page item row style)
            HStack(spacing: 0) {
                // LEFT: Type indicator (32pt)
                HStack(alignment: .center, spacing: 3) {
                    JohoIndicatorCircle(color: JohoColors.cyan, size: .medium)
                }
                .frame(width: 32, alignment: .center)
                .frame(maxHeight: .infinity)

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // CENTER: Name and date
                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                    Text(event.name)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)

                    Text(event.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Days counter compartment (84pt like Star page)
                // 情報デザイン: Intelligent messaging - "TODAY" not "0 DAYS"
                VStack(spacing: 2) {
                    if event.days == 0 {
                        Text("TODAY")
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)
                    } else {
                        Text("\(event.days)")
                            .font(JohoFont.displayMedium)
                            .foregroundStyle(JohoColors.black)

                        Text(event.days == 1 ? "DAY" : "DAYS")
                            .font(JohoFont.label)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
                .frame(width: 84)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 72)
        }
        .background(JohoColors.purple)  // Light purple (情報デザイン bento - matches HOLIDAYS style)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Events Section (All Custom)

    private var eventsSection: some View {
        eventBentoSection(
            title: "Events",
            icon: "calendar.badge.clock",
            showAddButton: true,
            onAdd: { showAddEvent = true }
        ) {
            if customCountdowns.isEmpty {
                // Empty state row
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.4))

                        Text("No Events")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))

                        Text("Tap + to create your first event")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                    }
                    .padding(JohoDimensions.spacingLG)
                    Spacer()
                }
            } else {
                let currentYear = Calendar.iso8601.component(.year, from: Date())
                ForEach(Array(customCountdowns.enumerated()), id: \.element) { index, custom in
                    let target = custom.computeTargetDate(for: currentYear) ?? Date()
                    let days = daysUntil(target)

                    eventBentoRow(
                        name: custom.name,
                        days: days,
                        icon: custom.iconName,
                        tasks: custom.tasks,  // 情報デザイン: Pass tasks for progress display
                        countdown: custom,    // 情報デザイン: Pass full countdown for sharing
                        onDelete: {
                            deleteCustom(custom)
                        }
                    )

                    // Divider between items (not after last) - matches Star page
                    if index < customCountdowns.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Bento Section Container (matches Star page specialDaySection)

    @ViewBuilder
    private func eventBentoSection<Content: View>(
        title: String,
        icon: String,
        showAddButton: Bool = false,
        onAdd: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento with icon in RIGHT compartment)
            HStack(spacing: 0) {
                // LEFT: Title pill
                HStack(spacing: JohoDimensions.spacingSM) {
                    JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)

                    if showAddButton, let onAdd = onAdd {
                        Spacer()
                        Button(action: onAdd) {
                            HStack(spacing: JohoDimensions.spacingXS) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Text("Add")
                                    .font(JohoFont.label)
                            }
                            .foregroundStyle(JohoColors.cyan)
                        }
                    }
                }
                .padding(.leading, JohoDimensions.spacingMD)
                .padding(.trailing, showAddButton ? JohoDimensions.spacingMD : 0)

                if !showAddButton {
                    Spacer()
                }

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(JohoColors.purple.opacity(0.7))  // Light purple header (情報デザイン bento)

            // Horizontal divider between header and items
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Items in VStack for pixel-perfect 情報デザイン layout
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 4)
        }
        .background(JohoColors.purple)  // Light purple (情報デザイン bento - like HOLIDAYS uses redLight)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Event Bento Row (matches Star page specialDayItemRow)
    //
    // 情報デザイン BENTO LAYOUT - Compartments with vertical dividers (walls)
    // ┌─────┬─────────────────────────────────┬───────┬─────────┐
    // │  ●  ┃ Event Name                      ┃ share ┃ [icon]  │
    // └─────┴─────────────────────────────────┴───────┴─────────┘
    //  LEFT │           CENTER                │ 40pt  │  48pt
    //  32pt │          flexible               │       │

    @ViewBuilder
    private func eventBentoRow(
        name: String,
        days: Int,
        icon: String?,
        tasks: [EventTask] = [],  // 情報デザイン: Event tasks for progress display
        countdown: CustomCountdown,  // 情報デザイン: For sharing
        onDelete: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Type indicator (fixed 32pt, centered)
            HStack(alignment: .center, spacing: 3) {
                JohoIndicatorCircle(color: JohoColors.cyan, size: .small)
            }
            .frame(width: 32, alignment: .center)
            .frame(maxHeight: .infinity)

            // WALL (vertical divider)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER COMPARTMENT: Name + countdown + task progress (flexible)
            HStack(spacing: JohoDimensions.spacingXS) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    // 情報デザイン: Show task progress if event has tasks
                    if !tasks.isEmpty {
                        TaskProgressIndicator(tasks: tasks)
                    }
                }

                Spacer(minLength: 4)

                // Countdown text (like Star page birthday age display)
                let daysLabel = days == 0 ? "TODAY" :
                               days == 1 ? "IN 1D" :
                               "IN \(days)D"
                Text(daysLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity)

            // WALL (vertical divider)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // SHARE COMPARTMENT: Share button (fixed 40pt)
            if #available(iOS 16.0, *) {
                CountdownShareButton(countdown: countdown, daysRemaining: days)
                    .frame(width: 40, alignment: .center)
                    .frame(maxHeight: .infinity)

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }

            // RIGHT COMPARTMENT: Decoration icon (fixed 48pt, centered)
            // 情報デザイン: Decoration icon ALWAYS shown (user decision)
            HStack(spacing: 4) {
                Image(systemName: icon ?? "calendar.badge.clock")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)
                    .frame(width: 24, height: 24)
                    .background(JohoColors.cyan.opacity(0.15))
                    .clipShape(Squircle(cornerRadius: 6))
                    .overlay(Squircle(cornerRadius: 6).stroke(JohoColors.black, lineWidth: 1))
            }
            .frame(width: 48, alignment: .center)
            .frame(maxHeight: .infinity)
        }
        .frame(minHeight: tasks.isEmpty ? 36 : 48)  // 情報デザイン: Taller when showing task progress
        .contentShape(Rectangle())
        .contextMenu {
            // 情報デザイン: Share option in context menu as well
            if #available(iOS 16.0, *) {
                ShareLink(
                    item: ShareableCountdownSnapshot(
                        countdown: countdown,
                        daysRemaining: days,
                        size: CGSize(width: 340, height: 220)
                    ),
                    preview: SharePreview(countdown.name, image: Image(systemName: icon ?? "calendar.badge.clock"))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Data Management

    private func loadCustomCountdowns() {
        if let data = UserDefaults.standard.data(forKey: "customCountdowns"),
           let countdowns = try? JSONDecoder().decode([CustomCountdown].self, from: data) {
            customCountdowns = countdowns
        }
    }

    private func deleteCustom(_ custom: CustomCountdown) {
        customCountdowns.removeAll { $0 == custom }
        if let data = try? JSONEncoder().encode(customCountdowns) {
            UserDefaults.standard.set(data, forKey: "customCountdowns")
        }
        HapticManager.notification(.warning)
    }
}

// Note: CustomCountdownDialog is defined in CountdownViews.swift

// MARK: - Preview

#Preview {
    NavigationStack {
        CountdownListView()
    }
}

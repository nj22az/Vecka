//
//  CountdownBanner.swift
//  Vecka
//
//  Extracted view for countdown banner
//

import SwiftUI
import SwiftData

// MARK: - Countdown Banner
struct CountdownBanner: View {
    let selectedDate: Date

    // Query all memos, filter to countdowns in computed property
    @Query(sort: \Memo.date) private var allMemos: [Memo]
    @AppStorage("selectedCountdownID") private var selectedCountdownID: String = ""
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Filtered countdown events
    private var events: [Memo] {
        allMemos.filter { $0.type == .countdown }
    }

    var body: some View {
        Group {
            if let event = activeEvent {
                Menu {
                    Picker(Localization.selectCountdown, selection: $selectedCountdownID) {
                        ForEach(events) { event in
                            Label(event.text, systemImage: event.symbolName ?? "star.fill")
                                .tag(event.id.uuidString)
                        }
                    }
                } label: {
                    // Compact single-line layout for decluttered UI
                    HStack(spacing: 10) {
                        // Icon
                        Image(systemName: event.symbolName ?? "star.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color(hex: event.colorHex))
                            .frame(width: 24, height: 24)

                        // Title
                        Text(event.text)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(colors.primary)
                            .lineLimit(1)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(colors.primary.opacity(0.7))

                        // Days
                        let days = daysRemaining(to: event.date)
                        Text("\(abs(days)) \(days == 1 ? Localization.daySingular : Localization.dayPlural)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(colors.primary.opacity(0.7))
                            .textCase(.uppercase)
                            .lineLimit(1)

                        // Direction (Ago/Left)
                        Text(days < 0 ? Localization.countdownAgo : Localization.countdownLeft)
                             .font(.caption.weight(.bold))
                             .foregroundStyle(days < 0 ? .secondary : Color(hex: event.colorHex))

                        Spacer(minLength: 0)

                        // Chevron to indicate menu
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Squircle(cornerRadius: 12)
                            .fill(colors.surface)
                    )
                    .overlay(
                        Squircle(cornerRadius: 12)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(event.text), \(daysRemaining(to: event.date)) days left")
            } else if events.isEmpty {
                EmptyView()
            } else {
                // Fallback if ID not found, select first
                Text("Select Event")
                    .onAppear {
                        if let first = events.first {
                            selectedCountdownID = first.id.uuidString
                        }
                    }
            }
        }
    }

    private var activeEvent: Memo? {
        events.first { $0.id.uuidString == selectedCountdownID } ?? events.first
    }

    private func daysRemaining(to targetDate: Date) -> Int {
        ViewUtilities.daysUntil(from: selectedDate, to: targetDate)
    }
}

// Note: Color(hex:) extension is defined in DesignSystem.swift to avoid duplication

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
    
    @Query(sort: \CountdownEvent.targetDate) private var events: [CountdownEvent]
    @AppStorage("selectedCountdownID") private var selectedCountdownID: String = ""
    
    var body: some View {
        Group {
            if let event = activeEvent {
                Menu {
                    Picker(Localization.selectCountdown, selection: $selectedCountdownID) {
                        ForEach(events) { event in
                            Label(event.title, systemImage: event.icon)
                                .tag(event.id)
                        }
                    }
                } label: {
                    // Compact single-line layout for decluttered UI
                    HStack(spacing: 10) {
                        // Icon
                        Image(systemName: event.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color(hex: event.colorHex))
                            .frame(width: 24, height: 24)

                        // Title
                        Text(event.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        // Days
                        let days = daysRemaining(to: event.targetDate)
                        Text("\(abs(days)) \(days == 1 ? Localization.daySingular : Localization.dayPlural)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppColors.textSecondary)
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
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(hex: event.colorHex).opacity(0.2), lineWidth: 1)
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(event.title), \(daysRemaining(to: event.targetDate)) days left")
            } else if events.isEmpty {
                EmptyView()
            } else {
                // Fallback if ID not found, select first
                Text("Select Event")
                    .onAppear {
                        if let first = events.first {
                            selectedCountdownID = first.id
                        }
                    }
            }
        }
    }
    
    private var activeEvent: CountdownEvent? {
        events.first { $0.id == selectedCountdownID } ?? events.first
    }
    
    private func daysRemaining(to targetDate: Date) -> Int {
        ViewUtilities.daysUntil(from: selectedDate, to: targetDate)
    }
}

// Note: Color(hex:) extension is defined in DesignSystem.swift to avoid duplication

//
//  WeekCalendarStrip.swift
//  Vecka
//
//  Master Swift refactoring - Week calendar strip with Apple Paper metaphor navigation
//  Following Apple Human Interface Guidelines and intuitive calendar interaction patterns
//

import SwiftUI
import Foundation

// MARK: - Week Calendar Strip
/// Apple HIG-compliant weekly calendar strip with paper metaphor navigation
/// Left swipe = next week (throw away page), Right swipe = previous week (put back page)
struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    var showWeekInfo: Bool = false
    var hasEvent: ((Date) -> Bool)? = nil
    var iconProvider: ((Date) -> String?)? = nil
    var onEditIcon: ((Date) -> Void)? = nil
    var onClearIcon: ((Date) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    @State private var weekOffset: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @GestureState private var gestureOffset: CGSize = .zero
    

    @ScaledMetric private var weekdayLabelSize: CGFloat = 11
    @ScaledMetric private var dayNumberSize: CGFloat = 18
    
    private let calendar = Calendar.iso8601
    
    var body: some View {
        // Pure strip, no header
        calendarStrip
    }
    
    // MARK: - Header & Nav Buttons REMOVED (Handled by unified header)
    
    // MARK: - Calendar Strip
    
    private var calendarStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.date) { dayInfo in
                calendarDayView(dayInfo)
            }
        }
        .padding(.horizontal, 16)
        .offset(x: gestureOffset.width + dragOffset.width)
        .gesture(paperSwipeGesture)
        .frame(height: 100)
    }
    
    @ViewBuilder
    private func calendarDayView(_ dayInfo: CalendarDayInfo) -> some View {
        let isSelected = calendar.isDate(dayInfo.date, inSameDayAs: selectedDate)
        let isToday = dayInfo.isToday
        
        Button(action: {
            selectDate(dayInfo.date)
        }) {
            VStack(spacing: 4) {
                weekdayLabel(dayInfo.date)
                dayNumberDisplay(dayInfo, isSelected: isSelected, isToday: isToday)
                eventIndicator(dayInfo.date)
            }
            .frame(width: 44, height: 80)
            .background(dayBackground(isSelected: isSelected, isToday: isToday))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel(for: dayInfo))
        .contextMenu {
            Button("Set Icon…", systemImage: "sparkles") {
                onEditIcon?(dayInfo.date)
            }
            if iconProvider?(dayInfo.date) != nil {
                Button("Remove Icon", systemImage: "trash", role: .destructive) {
                    onClearIcon?(dayInfo.date)
                }
            }
        }
    }
    
    // MARK: - Day Components
    
    private func weekdayLabel(_ date: Date) -> some View {
        let weekday = Calendar.iso8601.component(.weekday, from: date)
        return Text(Localization.weekdayShort(weekday))
            .font(.system(size: weekdayLabelSize, weight: .medium, design: .default))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.3)
    }
    
    private func dayNumberDisplay(_ dayInfo: CalendarDayInfo, isSelected: Bool, isToday: Bool) -> some View {
        // Clean Apple Design: Solid circle for selected, plain text otherwise
        let textColor: Color
        if isSelected {
            textColor = .white
        } else if isToday {
            textColor = AppColors.accentBlue
        } else {
            textColor = AppColors.textPrimary
        }
        
        return Text("\(dayInfo.dayNumber)")
            .font(.system(size: dayNumberSize, weight: isSelected ? .bold : .regular, design: .rounded))
            .foregroundStyle(textColor)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(dayNumberBackground(dayInfo.date, isSelected: isSelected, isToday: isToday))
            )
            .scaleEffect(isSelected ? 1.0 : 1.0) // Remove bounce/scale if desired, or keep subtle
    }
    
    // MARK: - Styling
    
    private func dayBackground(isSelected: Bool, isToday: Bool) -> some View {
        Rectangle()
            .fill(dayBackgroundFill(isSelected: isSelected))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor(isSelected: isSelected, isToday: isToday), lineWidth: isSelected ? 1.0 : 0)
        )
    }
    
    private func dayBackgroundFill(isSelected: Bool) -> AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Material.thinMaterial)
        } else {
            return AnyShapeStyle(Color.clear)
        }
    }
    
    // Removed - using white for all day numbers now
    
    private func dayNumberBackground(_ date: Date, isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            // Check if date is a holiday using HolidayManager
            let normalized = Calendar.current.startOfDay(for: date)
            let isRedDay = (HolidayManager.shared.holidayCache[normalized] ?? []).contains(where: { $0.isRedDay })
            let base = isRedDay ? Color.red : AppColors.colorForDay(date)
            return base.opacity(0.2)
        } else if isToday {
            return AppColors.accentBlue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private func borderColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            return AppColors.textSecondary.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private func outlineColorForDay(_ date: Date) -> Color {
        // Red for holidays and Sundays, blue for Saturdays, else default
        let weekday = Calendar.iso8601.component(.weekday, from: date)
        let normalized = Calendar.current.startOfDay(for: date)
        let isRedDay = (HolidayManager.shared.holidayCache[normalized] ?? []).contains(where: { $0.isRedDay })
        if isRedDay || weekday == 1 { return .red }
        if weekday == 7 { return .blue }
        return AppColors.textPrimary
    }

    // MARK: - Event Indicator
    @ViewBuilder
    private func eventIndicator(_ date: Date) -> some View {
        // Show a subtle dot only when there is an event; no custom icons below days
        if let hasEvent = hasEvent, hasEvent(date) {
            Circle()
                .fill(AppColors.accentBlue)
                .frame(width: 5, height: 5)
        } else {
            Spacer().frame(height: 5)
        }
    }
    
    // MARK: - Paper Swipe Gesture
    
    private var paperSwipeGesture: some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
                
                if !isDragging {
                    isDragging = true
                    HapticManager.impact(.light)
                }
            }
            .onEnded { value in
                isDragging = false
                
                let threshold: CGFloat = 50
                let predicted = value.predictedEndTranslation.width
                
                withAnimation(AnimationConstants.standardSpring) {
                    if value.translation.width > threshold || predicted > threshold {
                        // Right swipe - previous week (put back calendar page)
                        navigateWeek(direction: .previous)
                        HapticManager.impact(.medium)
                    } else if value.translation.width < -threshold || predicted < -threshold {
                        // Left swipe - next week (throw away calendar page)
                        navigateWeek(direction: .next)
                        HapticManager.impact(.medium)
                    }
                    
                    dragOffset = .zero
                }
            }
    }
    
    // MARK: - Navigation
    
    private func navigateWeek(direction: NavigationDirection) {
        let weekChange = direction == .next ? 1 : -1
        
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: weekChange, to: selectedDate) else {
            return
        }
        
        withAnimation(AnimationConstants.standardSpring) {
            selectedDate = newDate
            weekOffset += weekChange
        }
    }
    

    
    private func selectDate(_ date: Date) {
        HapticManager.selection()
        
        withAnimation(AnimationConstants.quickSpring) {
            selectedDate = date
        }
    }
    
    // MARK: - Data Generation
    
    private var currentWeekInfo: WeekInfo {
        WeekInfo(for: selectedDate)
    }
    
    private var weekDays: [CalendarDayInfo] {
        let weekInfo = currentWeekInfo
        var days: [CalendarDayInfo] = []
        
        for i in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: i, to: weekInfo.startDate) else {
                continue
            }
            
            let dayNumber = calendar.component(.day, from: dayDate)
            let isToday = calendar.isDate(dayDate, inSameDayAs: Date())
            let isSelected = calendar.isDate(dayDate, inSameDayAs: selectedDate)
            let isCurrentMonth = calendar.isDate(dayDate, equalTo: selectedDate, toGranularity: .month)
            let weekNumber = calendar.component(.weekOfYear, from: dayDate)
            
            let dayInfo = CalendarDayInfo(
                date: dayDate,
                dayNumber: dayNumber,
                isToday: isToday,
                isSelected: isSelected,
                isCurrentMonth: isCurrentMonth,
                weekNumber: weekNumber
            )
            
            days.append(dayInfo)
        }
        
        return days
    }
    
    // MARK: - Accessibility
    
    private func accessibilityLabel(for dayInfo: CalendarDayInfo) -> String {
        let dateString = Localization.formatFullDate(dayInfo.date)
        
        var label = dateString
        
        if dayInfo.isToday {
            label += ", \(Localization.today)"
        }
        
        if calendar.isDate(dayInfo.date, inSameDayAs: selectedDate) {
            label += ", \(Localization.selectedDay)"
        }
        
        return label
    }
}

// MARK: - Navigation Direction
private enum NavigationDirection {
    case previous, next
    
    var iconName: String {
        switch self {
        case .previous: return "chevron.left"
        case .next: return "chevron.right"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .previous: return "Previous"
        case .next: return "Next"
        }
    }
}

// MARK: - Week Calendar Strip Preview
#Preview("Week Calendar Strip") {
    WeekCalendarStrip(
        selectedDate: .constant(Date())
    )
    .padding()
    .background(Color(.systemBackground))
}

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
    
    private let calendar = Calendar.iso8601
    
    var body: some View {
        VStack(spacing: 8) {
            if showWeekInfo { header }
            calendarStrip
        }
    }
    
    // MARK: - Week Header
    
    private var header: some View {
        VStack(spacing: 6) {
            // Week info
            VStack(alignment: .center, spacing: 2) {
                weekNumberText
                weekRangeText
            }
            .frame(maxWidth: .infinity)
            
            // Navigation row
            HStack(spacing: 12) {
                navigationButton(direction: .previous)
                todayButton
                navigationButton(direction: .next)
            }
        }
        .padding(.horizontal, LayoutConstants.cardSpacing)
    }
    
    private var weekNumberText: some View {
        Text("Week \(currentWeekInfo.weekNumber)")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.textPrimary)
    }
    
    private var weekRangeText: some View {
        Text(currentWeekInfo.dateRange)
            .font(.system(size: 14, weight: .medium, design: .default))
            .foregroundStyle(AppColors.textSecondary)
    }
    
    private var todayButton: some View {
        Button(action: goToToday) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(Localization.todayLabel)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(AppColors.accentBlue.opacity(0.12))
            )
            .foregroundStyle(AppColors.accentBlue)
        }
        .accessibilityLabel(Localization.goToToday)
    }
    
    @ViewBuilder
    private func navigationButton(direction: NavigationDirection) -> some View {
        Button(action: {
            navigateWeek(direction: direction)
        }) {
            Image(systemName: direction.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(AnyShapeStyle(Material.thinMaterial))
                        .overlay(
                            Circle()
                                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
        .accessibilityLabel(direction == .previous ? Localization.previousWeek : Localization.nextWeek)
    }
    
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
            .font(.system(size: 11, weight: .medium, design: .default))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.3)
    }
    
    private func dayNumberDisplay(_ dayInfo: CalendarDayInfo, isSelected: Bool, isToday: Bool) -> some View {
        let outlineColor = outlineColorForDay(dayInfo.date)
        
        return ZStack {
            // Outline for illustrated effect with specific colors for day types
            Text("\(dayInfo.dayNumber)")
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(outlineColor)
                .offset(x: 1, y: 1)
            
            Text("\(dayInfo.dayNumber)")
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(outlineColor)
                .offset(x: -1, y: -1)
            
            Text("\(dayInfo.dayNumber)")
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(outlineColor)
                .offset(x: 1, y: -1)
            
            Text("\(dayInfo.dayNumber)")
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(outlineColor)
                .offset(x: -1, y: 1)
            
            // White fill for all days
            Text("\(dayInfo.dayNumber)")
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
        .background(
            Circle()
                .fill(dayNumberBackground(dayInfo.date, isSelected: isSelected, isToday: isToday))
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(AnimationConstants.quickSpring, value: isSelected)
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
            let base = Holidays.isHoliday(date) ? Color.red : AppColors.colorForDay(date)
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
        if Holidays.isHoliday(date) || weekday == 1 { return .red }
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
    
    private func goToToday() {
        withAnimation(AnimationConstants.standardSpring) {
            selectedDate = Date()
        }
        HapticManager.impact(.light)
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

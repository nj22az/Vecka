//
//  EventTaskViews.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) styled task/checklist views for events
//  Inspired by Swift Playgrounds Date Planner, adapted to design system
//

import SwiftUI

// MARK: - Event Task Row (情報デザイン: Single checklist item)

/// A single task row with checkbox and text
/// Uses Cyan semantic color (予定 - scheduled/planned items)
struct EventTaskRow: View {
    @Binding var task: EventTask
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Checkbox button with 情報デザイン styling
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.isCompleted.toggle()
                }
                HapticManager.impact(.light)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(task.isCompleted ? JohoColors.cyan : JohoColors.black)
            }
            .buttonStyle(.plain)

            // Task text
            Text(task.text)
                .font(JohoFont.body)
                .foregroundStyle(task.isCompleted ? JohoColors.black.opacity(0.4) : JohoColors.black)
                .strikethrough(task.isCompleted, color: JohoColors.black.opacity(0.4))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(JohoColors.white)
        .contentShape(Rectangle())
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Event Task Editor Row (情報デザイン: Editable task with TextField)

/// An editable task row for adding/editing tasks
struct EventTaskEditorRow: View {
    @Binding var task: EventTask
    var onDelete: (() -> Void)?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Checkbox button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.isCompleted.toggle()
                }
                HapticManager.impact(.light)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(task.isCompleted ? JohoColors.cyan : JohoColors.black)
            }
            .buttonStyle(.plain)

            // Editable text field
            TextField("Task description", text: $task.text, axis: .vertical)
                .font(JohoFont.body)
                .foregroundStyle(task.isCompleted ? JohoColors.black.opacity(0.4) : JohoColors.black)
                .strikethrough(task.isCompleted, color: JohoColors.black.opacity(0.4))
                .focused($isFocused)
                .submitLabel(.done)

            Spacer(minLength: 0)

            // Delete button (only shown when not empty)
            if !task.text.isEmpty, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(JohoColors.white)
    }

    /// Request focus for this row (call after adding a new task)
    func requestFocus() {
        isFocused = true
    }
}

// MARK: - Event Tasks Section (情報デザイン: Bento-styled task list)

/// A complete task list section with header and add button
struct EventTasksSection: View {
    @Binding var tasks: [EventTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento style)
            tasksSectionHeader

            // Horizontal divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Task list
            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, _ in
                    EventTaskEditorRow(
                        task: $tasks[index],
                        onDelete: {
                            _ = withAnimation {
                                tasks.remove(at: index)
                            }
                            HapticManager.notification(.warning)
                        }
                    )

                    // Divider between tasks (not after last)
                    if index < tasks.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }

                // Add task button
                addTaskButton
            }
            .padding(.vertical, JohoDimensions.spacingXS)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Subviews

    private var tasksSectionHeader: some View {
        HStack(spacing: 0) {
            // LEFT: Title
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Text("TASKS")
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)

            Spacer()

            // RIGHT: Task count badge
            if !tasks.isEmpty {
                let remaining = tasks.filter { !$0.isCompleted && !$0.text.isEmpty }.count
                let total = tasks.filter { !$0.text.isEmpty }.count

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                Text("\(total - remaining)/\(total)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(remaining == 0 ? JohoColors.cyan : JohoColors.black.opacity(0.6))
                    .frame(width: 48)
            }
        }
        .frame(height: 32)
        .background(JohoColors.cyan.opacity(0.3))
    }

    private var addTaskButton: some View {
        Button {
            let newTask = EventTask(text: "")
            withAnimation {
                tasks.append(newTask)
            }
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.cyan)

                Text("Add Task")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.cyan)

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Progress Indicator (情報デザイン: Compact progress display)

/// A compact indicator showing task completion progress
struct TaskProgressIndicator: View {
    let tasks: [EventTask]

    private var completedCount: Int {
        tasks.filter { $0.isCompleted && !$0.text.isEmpty }.count
    }

    private var totalCount: Int {
        tasks.filter { !$0.text.isEmpty }.count
    }

    private var isAllComplete: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    var body: some View {
        if totalCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: isAllComplete ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isAllComplete ? JohoColors.cyan : JohoColors.black.opacity(0.5))

                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isAllComplete ? JohoColors.cyan : JohoColors.black.opacity(0.5))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isAllComplete ? JohoColors.cyan.opacity(0.15) : JohoColors.black.opacity(0.05))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Event Task Row") {
    VStack(spacing: 16) {
        EventTaskRow(
            task: .constant(EventTask(text: "Buy plane tickets", isCompleted: false))
        )

        EventTaskRow(
            task: .constant(EventTask(text: "Pack luggage", isCompleted: true))
        )
    }
    .padding()
    .background(JohoColors.white)
}

#Preview("Event Tasks Section") {
    EventTasksSection(
        tasks: .constant([
            EventTask(text: "Buy plane tickets", isCompleted: true),
            EventTask(text: "Pack luggage", isCompleted: false),
            EventTask(text: "Book hotel", isCompleted: false)
        ])
    )
    .padding()
    .johoBackground()
}

#Preview("Task Progress Indicator") {
    HStack(spacing: 16) {
        TaskProgressIndicator(tasks: [
            EventTask(text: "Task 1", isCompleted: true),
            EventTask(text: "Task 2", isCompleted: false),
            EventTask(text: "Task 3", isCompleted: false)
        ])

        TaskProgressIndicator(tasks: [
            EventTask(text: "Task 1", isCompleted: true),
            EventTask(text: "Task 2", isCompleted: true)
        ])
    }
    .padding()
}

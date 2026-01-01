//
//  WidgetCard.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Widget Card Components
//  Resize handle and size picker for widget cards
//

import SwiftUI
import SwiftData

// MARK: - Resize Handle

/// Corner resize handle for widgets
struct ResizeHandle: View {
    let widget: WorkspaceWidget
    let onResize: (WidgetSize) -> Void

    @State private var showSizePicker = false

    var body: some View {
        Button(action: { showSizePicker = true }) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JohoColors.white)
                .frame(width: 24, height: 24)
                .background(JohoColors.black)
                .clipShape(Squircle(cornerRadius: 6))
        }
        .popover(isPresented: $showSizePicker) {
            WidgetSizePicker(
                currentSize: widget.size,
                widgetType: widget.type,
                onSelect: { size in
                    onResize(size)
                    showSizePicker = false
                }
            )
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Widget Size Picker

/// Popover for selecting widget size
struct WidgetSizePicker: View {
    let currentSize: WidgetSize
    let widgetType: WidgetType
    let onSelect: (WidgetSize) -> Void

    var body: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Text("RESIZE")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .padding(.top, JohoDimensions.spacingSM)

            ForEach(WidgetSize.allCases, id: \.self) { size in
                Button(action: { onSelect(size) }) {
                    HStack {
                        // Size preview grid
                        SizePreviewGrid(size: size)
                            .frame(width: 32, height: 32)

                        Text(size.displayName)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)

                        Spacer()

                        if size == currentSize {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(JohoColors.cyan)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
                    .background(size == currentSize ? JohoColors.cyan.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 200)
        .padding(.bottom, JohoDimensions.spacingSM)
    }
}

// MARK: - Size Preview Grid

/// Visual representation of widget size
struct SizePreviewGrid: View {
    let size: WidgetSize

    var body: some View {
        let cellSize: CGFloat = 6
        let spacing: CGFloat = 2

        VStack(spacing: spacing) {
            ForEach(0..<size.rows, id: \.self) { _ in
                HStack(spacing: spacing) {
                    ForEach(0..<size.columns, id: \.self) { _ in
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Resize Handle") {
    let widget = WorkspaceWidget(type: .todayHero, gridX: 0, gridY: 0, size: .medium)

    ZStack {
        Color.gray.opacity(0.2)

        ResizeHandle(widget: widget) { size in
            print("Resized to \(size)")
        }
    }
    .frame(width: 200, height: 200)
}

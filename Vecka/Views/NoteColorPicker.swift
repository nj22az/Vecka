//
//  NoteColorPicker.swift
//  Vecka
//
//  Color picker for daily notes - supports rawValue init for database-driven colors
//

import SwiftUI

enum NoteColor: String, CaseIterable {
    case `default` = "default"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"

    var color: Color {
        switch self {
        case .default: return .gray
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .default: return "Default"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        }
    }
}

struct NoteTagColorPickerView: View {
    @Binding var selectedColor: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NoteColor.allCases, id: \.rawValue) { noteColor in
                    Circle()
                        .fill(noteColor.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.2), lineWidth: selectedColor == noteColor.rawValue ? 3 : 1)
                        )
                        .onTapGesture {
                            selectedColor = noteColor.rawValue
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

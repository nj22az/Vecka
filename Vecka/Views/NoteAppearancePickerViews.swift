//
//  NoteAppearancePickerViews.swift
//  Vecka
//
//  Symbol picker for daily notes - database-driven symbol catalog
//

import SwiftUI

struct NoteSymbolCatalog {
    static let defaultSymbol = "note.text"

    static let symbols: [String] = [
        "note.text", "star.fill", "heart.fill", "checkmark.circle.fill",
        "exclamationmark.triangle.fill", "flag.fill", "bookmark.fill",
        "calendar", "clock.fill", "mappin.circle.fill", "phone.fill",
        "envelope.fill", "paperplane.fill", "bell.fill", "tag.fill",
        "link", "photo.fill", "music.note", "film.fill", "book.fill",
        "lightbulb.fill", "paintbrush.fill", "hammer.fill", "wrench.fill",
        "cart.fill", "creditcard.fill", "gift.fill", "bag.fill",
        "house.fill", "building.2.fill", "airplane", "car.fill",
        "bicycle", "figure.walk", "leaf.fill", "cloud.fill",
        "sun.max.fill", "moon.fill", "star", "sparkles",
        "bolt.fill", "flame.fill", "drop.fill", "snowflake",
        "wind", "tornado", "hurricane", "thermometer",
        "cup.and.saucer.fill", "fork.knife", "wineglass.fill", "birthday.cake.fill"
    ]

    static func label(for symbol: String) -> String {
        // Convert SF Symbol name to human-readable label
        let cleaned = symbol
            .replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".circle", with: "")
            .replacingOccurrences(of: ".", with: " ")
        return cleaned.capitalized
    }
}

struct NoteIconPickerView: View {
    @Binding var selection: String?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                ForEach(NoteSymbolCatalog.symbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == symbol ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(selection == symbol ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selection = symbol
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Select Icon")
    }
}

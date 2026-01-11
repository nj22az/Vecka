//
//  QuirkyFacts.swift
//  Vecka
//
//  情報デザイン: Database-driven quirky facts
//  Minimal code, data in JSON resource
//

import Foundation
import SwiftData

// MARK: - SwiftData Model

@Model
final class QuirkyFact {
    @Attribute(.unique) var id: String
    var region: String
    var category: String
    var text: String

    init(id: String, region: String, category: String, text: String) {
        self.id = id
        self.region = region
        self.category = category
        self.text = text
    }
}

// MARK: - Category (for icons/colors)

extension QuirkyFact {
    enum Category: String {
        case tradition, food, invention, nature, history, quirky
    }

    var factCategory: Category {
        Category(rawValue: category) ?? .quirky
    }
}

// MARK: - JSON Loader

enum QuirkyFactsLoader {

    /// Seed facts from JSON on first launch
    static func seedIfNeeded(context: ModelContext) {
        // Check if already seeded
        let descriptor = FetchDescriptor<QuirkyFact>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Load from JSON
        guard let url = Bundle.main.url(forResource: "quirky-facts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let facts = try? JSONDecoder().decode([FactDTO].self, from: data) else {
            return
        }

        // Insert into SwiftData
        for dto in facts {
            let fact = QuirkyFact(id: dto.id, region: dto.region, category: dto.category, text: dto.text)
            context.insert(fact)
        }

        try? context.save()
    }

    /// DTO for JSON decoding
    private struct FactDTO: Codable {
        let id: String
        let region: String
        let category: String
        let text: String
    }
}

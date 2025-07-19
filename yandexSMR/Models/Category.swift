//
//  Category.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation
import SwiftData

@Model
final class Category: Identifiable, Codable, Hashable {
    @Attribute(.unique)
    var id: Int
    var name: String
    var emoji: String // <-- Тип String
    var isIncome: Bool
    
    var direction: Direction {
        isIncome ? .income : .outcome
    }

    // Инициализатор теперь принимает String для emoji
    init(id: Int, name: String, emoji: String, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isIncome = try container.decode(Bool.self, forKey: .isIncome)
        emoji = try container.decode(String.self, forKey: .emoji)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(isIncome, forKey: .isIncome)
    }

    // Для Hashable
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

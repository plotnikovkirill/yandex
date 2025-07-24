//
//   Transaction.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation
import SwiftData

@Model
final class Transaction: Identifiable, Codable {
    @Attribute(.unique)
    var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date

    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // --- НАЧАЛО РУЧНОЙ РЕАЛИЗАЦИИ CODABLE ---
    enum CodingKeys: String, CodingKey {
        case id, accountId, categoryId, amount, transactionDate, comment, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        amount = try container.decode(Decimal.self, forKey: .amount)
        transactionDate = try container.decode(Date.self, forKey: .transactionDate)
        comment = try container.decode(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        try container.encode(transactionDate, forKey: .transactionDate)
        try container.encode(comment, forKey: .comment)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    // --- КОНЕЦ РУЧНОЙ РЕАЛИЗАЦИИ CODABLE ---
}

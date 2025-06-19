//
//  ContentView.swift
//  yandex2
//
//  Created by kirill on 13.06.2025.
//

import SwiftUI
import Foundation
struct ContentView: View {
   var body: some View {
        VStack {
           Image(systemName: "globe")
               .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, wordld!")
       }
       .padding()
    }
}

//#Preview {
 //   ContentView()
//}


// MARK: - Direction
//enum Direction: String, Codable {
//    case income
//    case outcome
//}
//
//// MARK: - Category
//struct Category: Identifiable, Codable {
//    let id: Int
//    let name: String
//    let emoji: Character
//    let isIncome: Bool
//    
//    var direction: Direction {
//        return isIncome ? .income : .outcome
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case id, name, emoji, isIncome
//    }
//    
//    init(id: Int, name: String, emoji: Character, isIncome: Bool) {
//        self.id = id
//        self.name = name
//        self.emoji = emoji
//        self.isIncome = isIncome
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(Int.self, forKey: .id)
//        name = try container.decode(String.self, forKey: .name)
//        
//        let emojiString = try container.decode(String.self, forKey: .emoji)
//        guard let char = emojiString.first else {
//            throw DecodingError.dataCorruptedError(
//                forKey: .emoji,
//                in: container,
//                debugDescription: "Emoji string must contain exactly one character"
//            )
//        }
//        emoji = char
//        
//        isIncome = try container.decode(Bool.self, forKey: .isIncome)
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(name, forKey: .name)
//        try container.encode(String(emoji), forKey: .emoji)
//        try container.encode(isIncome, forKey: .isIncome)
//    }
//}

// MARK: - BankAccount (Updated)
//struct BankAccount: Identifiable, Codable {
//    let id: Int
//    let userId: Int
//    let name: String
//    let balance: Decimal
//    let currency: String
//    let createdAt: Date
//    let updatedAt: Date
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case userId = "userId"
//        case name
//        case balance
//        case currency
//        case createdAt = "createdAt"
//        case updatedAt = "updatedAt"
//    }
//    init(
//            id: Int,
//            userId: Int,
//            name: String,
//            balance: Decimal,
//            currency: String,
//            createdAt: Date,
//            updatedAt: Date
//        ) {
//            self.id = id
//            self.userId = userId
//            self.name = name
//            self.balance = balance
//            self.currency = currency
//            self.createdAt = createdAt
//            self.updatedAt = updatedAt
//        }
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(Int.self, forKey: .id)
//        userId = try container.decode(Int.self, forKey: .userId)
//        name = try container.decode(String.self, forKey: .name)
//        
//        // Handle balance as string
//        let balanceString = try container.decode(String.self, forKey: .balance)
//        guard let balance = Decimal(string: balanceString) else {
//            throw DecodingError.dataCorruptedError(
//                forKey: .balance,
//                in: container,
//                debugDescription: "Invalid balance format"
//            )
//        }
//        self.balance = balance
//        
//        currency = try container.decode(String.self, forKey: .currency)
//        
//        // Date decoding
//        let dateFormatter = ISO8601DateFormatter()
//        createdAt = try dateFormatter.date(from: container.decode(String.self, forKey: .createdAt)) ?? Date()
//        updatedAt = try dateFormatter.date(from: container.decode(String.self, forKey: .updatedAt)) ?? Date()
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(userId, forKey: .userId)
//        try container.encode(name, forKey: .name)
//        try container.encode(balance.description, forKey: .balance)
//        try container.encode(currency, forKey: .currency)
//        
//        let dateFormatter = ISO8601DateFormatter()
//        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
//        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
//    }
//}

// MARK: - Transaction (Updated)
//struct Transaction: Identifiable, Codable {
//    let id: Int
//    let accountId: Int
//    let categoryId: Int
//    let amount: Decimal
//    let transactionDate: Date
//    let comment: String?
//    let createdAt: Date
//    let updatedAt: Date
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case accountId = "accountId"
//        case categoryId = "categoryId"
//        case amount
//        case transactionDate = "transactionDate"
//        case comment
//        case createdAt = "createdAt"
//        case updatedAt = "updatedAt"
//    }
//    init(
//            id: Int,
//            accountId: Int,
//            categoryId: Int,
//            amount: Decimal,
//            transactionDate: Date,
//            comment: String?,
//            createdAt: Date,
//            updatedAt: Date
//        ) {
//            self.id = id
//            self.accountId = accountId
//            self.categoryId = categoryId
//            self.amount = amount
//            self.transactionDate = transactionDate
//            self.comment = comment
//            self.createdAt = createdAt
//            self.updatedAt = updatedAt
//        }
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(Int.self, forKey: .id)
//        accountId = try container.decode(Int.self, forKey: .accountId)
//        categoryId = try container.decode(Int.self, forKey: .categoryId)
//        
//        // Handle amount as string or decimal
//        if let amountString = try? container.decode(String.self, forKey: .amount) {
//            guard let amount = Decimal(string: amountString) else {
//                throw DecodingError.dataCorruptedError(
//                    forKey: .amount,
//                    in: container,
//                    debugDescription: "Invalid amount format"
//                )
//            }
//            self.amount = amount
//        } else {
//            amount = try container.decode(Decimal.self, forKey: .amount)
//        }
//        
//        // Date decoding
//        let dateFormatter = ISO8601DateFormatter()
//        transactionDate = try dateFormatter.date(from: container.decode(String.self, forKey: .transactionDate)) ?? Date()
//        createdAt = try dateFormatter.date(from: container.decode(String.self, forKey: .createdAt)) ?? Date()
//        updatedAt = try dateFormatter.date(from: container.decode(String.self, forKey: .updatedAt)) ?? Date()
//        
//        comment = try container.decodeIfPresent(String.self, forKey: .comment)
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(accountId, forKey: .accountId)
//        try container.encode(categoryId, forKey: .categoryId)
//        try container.encode(amount, forKey: .amount)
//        
//        let dateFormatter = ISO8601DateFormatter()
//        try container.encode(dateFormatter.string(from: transactionDate), forKey: .transactionDate)
//        try container.encodeIfPresent(comment, forKey: .comment)
//        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
//        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
//    }
//}

// - JSON Conversion
//extension Transaction {
//    static func parse(jsonObject: Any) -> Transaction? {
//        guard let jsonDict = jsonObject as? [String: Any] else { return nil }
//        do {
//            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
//            return try JSONDecoder().decode(Transaction.self, from: data)
//        } catch {
//            return nil
//        }
//    }
//    
//    var jsonObject: Any {
//        do {
//            let data = try JSONEncoder().encode(self)
//            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
//        } catch {
//            return [String: Any]()
//        }
//    }
//}

// MARK: - TransactionsFileCache
//class TransactionsFileCache {
//    private(set) var transactions: [Transaction] = []
//    private let fileManager = FileManager.default
//    private let queue = DispatchQueue(label: "com.transactions.cacheQueue", attributes: .concurrent)
//    
//    func addTransaction(_ transaction: Transaction) {
//        queue.async(flags: .barrier) {
//            if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
//                self.transactions[index] = transaction
//            } else {
//                self.transactions.append(transaction)
//            }
//        }
//    }
//    
//    func deleteTransaction(id: Int) {
//        queue.async(flags: .barrier) {
//            self.transactions.removeAll { $0.id == id }
//        }
//    }
//    
//    func saveToFile(named fileName: String) throws {
//        var transactionsSnapshot: [Transaction] = []
//        queue.sync {
//            transactionsSnapshot = transactions
//        }
//        
//        let jsonObjects = transactionsSnapshot.map { $0.jsonObject }
//        let data = try JSONSerialization.data(withJSONObject: jsonObjects, options: .prettyPrinted)
//        let url = try fileURL(for: fileName)
//        try data.write(to: url)
//    }
//    
//    func loadFromFile(named fileName: String) throws {
//        let url = try fileURL(for: fileName)
//        guard fileManager.fileExists(atPath: url.path) else { return }
//        
//        let data = try Data(contentsOf: url)
//        let jsonObjects = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
//        
//        queue.async(flags: .barrier) {
//            self.transactions = jsonObjects.compactMap { Transaction.parse(jsonObject: $0) }
//        }
//    }
//    
//    private func fileURL(for fileName: String) throws -> URL {
//        let docsDir = try fileManager.url(for: .documentDirectory,
//                                         in: .userDomainMask,
//                                         appropriateFor: nil,
//                                         create: true)
//        return docsDir.appendingPathComponent("\(fileName).json")
//    }
//}

// MARK: - Mock Services (Updated)
//final class CategoriesService {
//    private let mockCategories = [
//        Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: true),
//        Category(id: 2, name: "Продукты", emoji: "🍎", isIncome: false),
//        Category(id: 3, name: "Транспорт", emoji: "🚕", isIncome: false),
//        Category(id: 4, name: "Подарки", emoji: "🎁", isIncome: true),
//        Category(id: 5, name: "Кафе", emoji: "☕️", isIncome: false)
//    ]
//    
//    func categories() async throws -> [Category] {
//        return mockCategories
//    }
//    
//    func categories(by direction: Direction) async throws -> [Category] {
//        return mockCategories.filter { $0.direction == direction }
//    }
//}

//final class BankAccountsService {
//    private var mockAccount = BankAccount(
//        id: 1,
//        userId: 1,
//        name: "Основной счёт",
//        balance: 1000.00,
//        currency: "RUB",
//        createdAt: Date(),
//        updatedAt: Date()
//    )
//    
//    func getBankAccount() async throws -> BankAccount {
//        return mockAccount
//    }
//    
//    func updateBankAccount(_ account: BankAccount) async throws {
//        mockAccount = account
//    }
//}

//final class TransactionsService {
//    private let cache = TransactionsFileCache()
//    
//    func getTransactions(for accountId: Int, period: (start: Date, end: Date)) async throws -> [Transaction] {
//        return cache.transactions.filter {
//            $0.accountId == accountId &&
//            $0.transactionDate >= period.start &&
//            $0.transactionDate <= period.end
//        }
//    }
//    
//    func createTransaction(_ transaction: Transaction) async throws {
//        cache.addTransaction(transaction)
//    }
//    
//    func updateTransaction(_ transaction: Transaction) async throws {
//        cache.addTransaction(transaction)
//    }
//    
//    func deleteTransaction(id: Int) async throws {
//        cache.deleteTransaction(id: id)
//    }
//}

// MARK: - CSV Support (*)
//extension Transaction {
//    static func parse(csvRow: String) -> Transaction? {
//        let components = csvRow.split(separator: ",", omittingEmptySubsequences: false)
//            .map(String.init)
//            .map { $0.trimmingCharacters(in: .whitespaces) }
//        
//        guard components.count >= 8 else { return nil }
//        
//        // Parse IDs
//        guard let id = Int(components[0]),
//              let accountId = Int(components[1]),
//              let categoryId = Int(components[2]) else {
//            return nil
//        }
//        
//        // Parse amount
//        guard let amount = Decimal(string: components[3]) else {
//            return nil
//        }
//        
//        // Parse dates
//        let dateFormatter = ISO8601DateFormatter()
//        guard let transactionDate = dateFormatter.date(from: components[4]),
//              let createdAt = dateFormatter.date(from: components[6]),
//              let updatedAt = dateFormatter.date(from: components[7]) else {
//            return nil
//        }
//        
//        return Transaction(
//            id: id,
//            accountId: accountId,
//            categoryId: categoryId,
//            amount: amount,
//            transactionDate: transactionDate,
//            comment: components[5].isEmpty ? nil : components[5],
//            createdAt: createdAt,
//            updatedAt: updatedAt
//        )
//    }
//    
//    var csvRow: String {
//        let dateFormatter = ISO8601DateFormatter()
//        return [
//            String(id),
//            String(accountId),
//            String(categoryId),
//            amount.description,
//            dateFormatter.string(from: transactionDate),
//            comment ?? "",
//            dateFormatter.string(from: createdAt),
//            dateFormatter.string(from: updatedAt)
//        ].joined(separator: ",")
//    }
//}


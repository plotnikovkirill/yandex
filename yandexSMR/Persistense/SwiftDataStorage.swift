//
//  SwiftDataStorage.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation
import SwiftData
@MainActor
final class SwiftDataStorage {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() {
        do {
            container = try ModelContainer(for: Transaction.self, BankAccount.self, Category.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}
extension SwiftDataStorage: BackupStorage {
    func fetchAll() throws -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>()
        return try context.fetch(descriptor)
    }
    
    func save(_ operation: PendingOperation) throws {
        context.insert(operation)
        try context.save()
    }
    
    func delete(_ operation: PendingOperation) throws {
        // Мы должны найти и удалить объект по его уникальному ID
        let operationID = operation.id
        let predicate = #Predicate<PendingOperation> { $0.id == operationID }
        try context.delete(model: PendingOperation.self, where: predicate)
        try context.save()
    }
}
extension SwiftDataStorage: TransactionStorage {
    func fetch(from startDate: Date, to endDate: Date) throws -> [Transaction] {
        let predicate = #Predicate<Transaction> { transaction in
            transaction.transactionDate >= startDate && transaction.transactionDate <= endDate
        }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        return try context.fetch(descriptor)
    }
    
    func upsert(_ transactions: [Transaction]) throws {
        for transaction in transactions {
            // SwiftData автоматически обновляет существующие объекты по их ID
            context.insert(transaction)
        }
        try context.save()
    }
    
    func delete(id: Int) throws {
        let predicate = #Predicate<Transaction> { $0.id == id }
        try context.delete(model: Transaction.self, where: predicate)
    }
}

extension SwiftDataStorage: AccountStorage {
    func fetchAll() throws -> [BankAccount] {
        let descriptor = FetchDescriptor<BankAccount>()
        return try context.fetch(descriptor)
    }
    
    func upsert(_ accounts: [BankAccount]) throws {
        for account in accounts {
            context.insert(account)
        }
        try context.save()
    }
}

extension SwiftDataStorage: CategoryStorage {
    func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>()
        return try context.fetch(descriptor)
    }
    
    func upsert(_ categories: [Category]) throws {
        for category in categories {
            context.insert(category)
        }
        try context.save()
    }
}


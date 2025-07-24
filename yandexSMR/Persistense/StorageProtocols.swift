//
//  StorageProtocols.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

// Протокол для хранения транзакций
protocol TransactionStorage {
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Transaction]
    func upsert(_ transactions: [Transaction]) async throws // Update or Insert
    func delete(id: Int) async throws
}

// Протокол для хранения счетов
protocol AccountStorage {
    func fetchAll() async throws -> [BankAccount]
    func upsert(_ accounts: [BankAccount]) async throws
}

// Протокол для хранения категорий
protocol CategoryStorage {
    func fetchAll() async throws -> [Category]
    func upsert(_ categories: [Category]) async throws
}
protocol BackupStorage {
    func fetchAll() async throws -> [PendingOperation]
    func save(_ operation: PendingOperation) async throws
    func delete(_ operation: PendingOperation) async throws
}

//
//  TransactionsRepository.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

@MainActor
final class TransactionsRepository: ObservableObject {
    private let networkService: TransactionsServiceLogic
    private let storage: TransactionStorage
    private let backupStorage: BackupStorage

    @Published var isLoading = false
    @Published var error: Error?
    @Published private(set) var isOffline = false

    init(networkService: TransactionsServiceLogic, storage: TransactionStorage, backupStorage: BackupStorage) {
        self.networkService = networkService
        self.storage = storage
        self.backupStorage = backupStorage
    }

    // --- ОСНОВНАЯ ЛОГИКА ---

    func getTransactions(for accountId: Int, from startDate: Date, to endDate: Date) async -> [Transaction] {
        isLoading = true
        error = nil
        isOffline = false
        defer { isLoading = false }
        
        await syncPendingOperations()
        
        do {
            let freshTransactions = try await networkService.fetchTransactions(accountId: accountId, from: startDate, to: endDate)
            try await storage.upsert(freshTransactions)
            return try await storage.fetch(from: startDate, to: endDate)
        } catch {
            self.error = error
            self.isOffline = true
            let localTransactions = (try? await storage.fetch(from: startDate, to: endDate)) ?? []
            let pendingOperations = (try? await backupStorage.fetchAll()) ?? []
            return merge(local: localTransactions, pending: pendingOperations)
        }
    }
    
    func createTransaction(_ transaction: Transaction) async {
        isLoading = true; defer { isLoading = false }
        
        // 1. Оптимистичное обновление UI и локальной базы
        try? await storage.upsert([transaction])
        
        do {
            // 2. Пытаемся отправить на сервер
            let createdTransactionFromServer = try await networkService.createTransaction(from: transaction)
            
            // 3. УСПЕХ: Удаляем старую временную транзакцию
            try? await storage.delete(id: transaction.id)
            
            // 4. Сохраняем новую транзакцию с настоящим ID от сервера
            try await storage.upsert([createdTransactionFromServer])
            
        } catch {
            // 5. ОШИБКА: Сети нет. Сохраняем операцию в бэкап.
            // Локальная транзакция уже сохранена, так что UI выглядит корректно.
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .create, transaction: transaction)
            try? await backupStorage.save(pendingOp)
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        isLoading = true; defer { isLoading = false }
        
        try? await storage.upsert([transaction])
        
        do {
            let updatedTransaction = try await networkService.updateTransaction(transaction)
            try await storage.upsert([updatedTransaction])
        } catch {
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .update, transaction: transaction)
            try? await backupStorage.save(pendingOp)
        }
    }
    
    func deleteTransaction(id: Int) async {
        isLoading = true; defer { isLoading = false }
        
        try? await storage.delete(id: id)
        
        do {
            try await networkService.deleteTransaction(id: id)
        } catch {
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .delete, transactionId: id)
            try? await backupStorage.save(pendingOp)
        }
    }

    // --- СИНХРОНИЗАЦИЯ и СЛИЯНИЕ ---
    
    private func syncPendingOperations() async {
        guard let pending = try? await backupStorage.fetchAll(), !pending.isEmpty else { return }
        
        print("Starting sync for \(pending.count) pending operations.")
        
        for operation in pending {
            do {
                switch operation.type {
                case .create:
                    if let data = operation.transactionData, let transaction = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.createTransaction(from: transaction)
                    }
                case .update:
                    if let data = operation.transactionData, let transaction = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.updateTransaction(transaction)
                    }
                case .delete:
                    if let id = operation.transactionId {
                       try await networkService.deleteTransaction(id: id)
                    }
                }
                try await backupStorage.delete(operation)
            } catch {
                print("Sync failed for operation \(operation.id): \(error). Stopping sync.")
                break
            }
        }
    }
    
    private func merge(local: [Transaction], pending: [PendingOperation]) -> [Transaction] {
        var merged = local
        let decoder = JSONDecoder.custom
        
        for op in pending {
            switch op.type {
            case .create:
                if let data = op.transactionData, let tx = try? decoder.decode(Transaction.self, from: data) {
                    if !merged.contains(where: { $0.id == tx.id }) {
                        merged.append(tx)
                    }
                }
            case .update:
                if let data = op.transactionData, let tx = try? decoder.decode(Transaction.self, from: data) {
                    if let index = merged.firstIndex(where: { $0.id == tx.id }) {
                        merged[index] = tx
                    }
                }
            case .delete:
                if let id = op.transactionId {
                    merged.removeAll(where: { $0.id == id })
                }
            }
        }
        return merged
    }
}

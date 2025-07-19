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
        
        // 1. Пытаемся синхронизировать отложенные операции
        await syncPendingOperations()
        
        do {
            // 2. Идем в сеть за свежими данными
            let freshTransactions = try await networkService.fetchTransactions(accountId: accountId, from: startDate, to: endDate)
            // 3. Сохраняем свежие данные в локальное хранилище
            try await storage.upsert(freshTransactions)
            // 4. Возвращаем данные, отфильтрованные локально (на случай, если серверная фильтрация неточна)
            return (try? await storage.fetch(from: startDate, to: endDate)) ?? []
        } catch {
            // 5. Если сеть упала, идем в локальное хранилище
            self.error = error
            self.isOffline = true
            // TODO: Смержить с данными из бэкапа
            return (try? await storage.fetch(from: startDate, to: endDate)) ?? []
        }
    }
    
    func createTransaction(_ transaction: Transaction) async {
        isLoading = true
        error = nil
        isOffline = false
        defer { isLoading = false }
        
        do {
            // Пытаемся отправить на сервер
            let createdTransaction = try await networkService.createTransaction(from: transaction)
            // Если успешно, сохраняем в основное хранилище
            try await storage.upsert([createdTransaction])
        } catch {
            // Если ошибка, сохраняем в бэкап
            self.error = error
            self.isOffline = true
            let pendingOp = PendingOperation(type: .create, transaction: transaction)
            try? await backupStorage.save(pendingOp)
            // И все равно сохраняем в основное хранилище, чтобы пользователь видел результат
            try? await storage.upsert([transaction])
        }
    }

    func updateTransaction(_ transaction: Transaction) async {
        isLoading = true
        error = nil
        isOffline = false
        defer { isLoading = false }
        
        do {
            // Пытаемся отправить на сервер
            let createdTransaction = try await networkService.createTransaction(from: transaction)
            // Если успешно, сохраняем в основное хранилище
            try await storage.upsert([createdTransaction])
        } catch {
            // Если ошибка, сохраняем в бэкап
            self.error = error
            self.isOffline = true
            let pendingOp = PendingOperation(type: .update, transaction: transaction)
            try? await backupStorage.save(pendingOp)
            // И все равно сохраняем в основное хранилище, чтобы пользователь видел результат
            try? await storage.upsert([transaction])
        }
    }
    
    func deleteTransaction(id: Int) async {
        isLoading = true
        error = nil
        isOffline = false
        defer { isLoading = false }
        
        do {
            // Пытаемся отправить на сервер
            let createdTransaction = try await networkService.createTransaction(from: transaction)
            // Если успешно, сохраняем в основное хранилище
            try await storage.upsert([createdTransaction])
        } catch {
            // Если ошибка, сохраняем в бэкап
            self.error = error
            self.isOffline = true
            let pendingOp = PendingOperation(type: .delete, transaction: transaction)
            try? await backupStorage.save(pendingOp)
            // И все равно сохраняем в основное хранилище, чтобы пользователь видел результат
            try? await storage.upsert([transaction])
        }
    }

    // --- СИНХРОНИЗАЦИЯ ---
    private func syncPendingOperations() async {
        guard let pending = try? await backupStorage.fetchAll(), !pending.isEmpty else {
            return
        }
        
        print("Starting sync for \(pending.count) pending operations.")
        
        for operation in pending {
            do {
                switch operation.type {
                case .create:
                    if let data = operation.transactionData,
                       let transaction = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.createTransaction(from: transaction)
                    }
                case .update:
                    if let data = operation.transactionData,
                       let transaction = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.updateTransaction(id: 107, requestBody: transaction)
                    }
                case .delete:
                    if let id = operation.transactionId {
                       try await networkService.deleteTransaction(id: id)
                    }
                }
                // Если операция на сервере прошла успешно, удаляем ее из бэкапа
                try await backupStorage.delete(operation)
            } catch {
                // Если при синхронизации произошла ошибка, прекращаем попытки до следующего раза
                print("Sync failed for operation \(operation.id): \(error). Stopping sync.")
                break
            }
        }
    }
}

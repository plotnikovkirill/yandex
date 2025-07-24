import Foundation

@MainActor
final class TransactionsRepository: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published private(set) var isOffline = false

    // MARK: - Dependencies
    private let networkService: TransactionsServiceLogic
    private let storage: TransactionStorage
    private let backupStorage: BackupStorage
    private let accountsRepository: AccountsRepository

    init(networkService: TransactionsServiceLogic,
         storage: TransactionStorage,
         backupStorage: BackupStorage,
         accountsRepository: AccountsRepository) {
        self.networkService = networkService
        self.storage = storage
        self.backupStorage = backupStorage
        self.accountsRepository = accountsRepository
    }

    // MARK: - Public Methods

    func getTransactions(for accountId: Int, from startDate: Date, to endDate: Date) async {
        isLoading = true
        error = nil
        isOffline = false
        defer { isLoading = false }
        
        await syncPendingOperations()
        
        do {
            let freshTransactions = try await networkService.fetchTransactions(accountId: accountId, from: startDate, to: endDate)
            try await storage.upsert(freshTransactions)
            self.transactions = try await storage.fetch(from: startDate, to: endDate)
        } catch {
            self.error = error
            self.isOffline = true
            let localTransactions = (try? await storage.fetch(from: startDate, to: endDate)) ?? []
            let pendingOperations = (try? await backupStorage.fetchAll()) ?? []
            self.transactions = merge(local: localTransactions, pending: pendingOperations)
        }
    }
    
    func createTransaction(_ transaction: Transaction) async {
        isLoading = true; defer { isLoading = false }
        
        try? await storage.upsert([transaction])
        
        do {
            let createdTransaction = try await networkService.createTransaction(from: transaction)
            try await storage.delete(id: transaction.id) // Удаляем временную
            try await storage.upsert([createdTransaction]) // Сохраняем серверную
            await accountsRepository.fetchPrimaryAccount() // Обновляем баланс
        } catch {
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .create, transaction: transaction)
            try? await backupStorage.save(pendingOp)
        }
        await refreshCurrentTransactionList()
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        isLoading = true; defer { isLoading = false }
        
        try? await storage.upsert([transaction])
        
        do {
            let updatedTransaction = try await networkService.updateTransaction(transaction)
            try await storage.upsert([updatedTransaction])
            await accountsRepository.fetchPrimaryAccount() // Обновляем баланс
        } catch {
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .update, transaction: transaction)
            try? await backupStorage.save(pendingOp)
        }
        await refreshCurrentTransactionList()
    }
    
    func deleteTransaction(id: Int) async {
        isLoading = true; defer { isLoading = false }
        
        try? await storage.delete(id: id)
        
        do {
            try await networkService.deleteTransaction(id: id)
            await accountsRepository.fetchPrimaryAccount() // Обновляем баланс
        } catch {
            self.error = error; self.isOffline = true
            let pendingOp = PendingOperation(type: .delete, transactionId: id)
            try? await backupStorage.save(pendingOp)
        }
        await refreshCurrentTransactionList()
    }

    // MARK: - Private Helper Methods
    
    private func syncPendingOperations() async {
        guard let pending = try? await backupStorage.fetchAll(), !pending.isEmpty else { return }
        print("Starting sync for \(pending.count) pending operations.")
        
        for operation in pending {
            do {
                switch operation.type {
                case .create:
                    if let data = operation.transactionData, let tx = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.createTransaction(from: tx)
                    }
                case .update:
                    if let data = operation.transactionData, let tx = try? JSONDecoder.custom.decode(Transaction.self, from: data) {
                        _ = try await networkService.updateTransaction(tx)
                    }
                case .delete:
                    if let id = operation.transactionId {
                       try await networkService.deleteTransaction(id: id)
                    }
                }
                try await backupStorage.delete(operation)
            } catch {
                print("Sync failed for operation \(operation.id): \(error). Stopping sync.")
                break // Прерываем синхронизацию при первой же ошибке
            }
        }
        // После успешной синхронизации нужно обновить баланс
        await accountsRepository.fetchPrimaryAccount()
    }
    
    private func merge(local: [Transaction], pending: [PendingOperation]) -> [Transaction] {
        var mergedDict = [Int: Transaction]()
        local.forEach { mergedDict[$0.id] = $0 }
        
        let decoder = JSONDecoder.custom
        
        for op in pending {
            switch op.type {
            case .create, .update:
                if let data = op.transactionData, let tx = try? decoder.decode(Transaction.self, from: data) {
                    mergedDict[tx.id] = tx
                }
            case .delete:
                if let id = op.transactionId {
                    mergedDict.removeValue(forKey: id)
                }
            }
        }
        return Array(mergedDict.values)
    }
    
    // Перезагружает текущий список транзакций, чтобы UI обновился
    private func refreshCurrentTransactionList() async {
        guard let accountId = accountsRepository.currentAccountId else { return }
        // Используем очень широкий диапазон дат, чтобы захватить все транзакции.
        // В реальном приложении здесь могла бы быть более сложная логика.
        let veryOldDate = Date.distantPast
        let futureDate = Date.distantFuture
        await getTransactions(for: accountId, from: veryOldDate, to: futureDate)
    }
}

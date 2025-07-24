import SwiftUI
import Combine

@MainActor
class TransactionsListViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var transactions: [Transaction] = [] // Отфильтрованные транзакции для этого View
    @Published var totalAmount: Decimal = 0
    @Published var sortOption: SortOption = .byDate
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let direction: Direction
    // Делаем репозитории публичными, чтобы View могли их передавать дальше
    let transactionsRepository: TransactionsRepository
    let accountsRepository: AccountsRepository
    let categoryRepository: CategoryRepository

    private var cancellables = Set<AnyCancellable>()

    init(direction: Direction,
         transactionsRepository: TransactionsRepository,
         accountsRepository: AccountsRepository,
         categoryRepository: CategoryRepository) {
        self.direction = direction
        self.transactionsRepository = transactionsRepository
        self.accountsRepository = accountsRepository
        self.categoryRepository = categoryRepository
        
        // --- КЛЮЧЕВЫЕ ИЗМЕНЕНИЯ ---
        
        // 1. Подписываемся на isLoading из репозитория
        transactionsRepository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        // 2. Подписываемся на ошибки из репозитория
        transactionsRepository.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in self?.errorMessage = error?.localizedDescription }
            .store(in: &cancellables)
            
        // 3. Подписываемся на ОБЩИЙ список транзакций из репозитория
        transactionsRepository.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allTransactions in
                guard let self = self else { return }
                
                // Фильтруем полученный список по нашему направлению (доход/расход)
                self.transactions = allTransactions.filter {
                    self.category(for: $0)?.direction == self.direction
                }
                
                // Пересчитываем сумму и применяем сортировку
                self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
                self.applySort()
            }
            .store(in: &cancellables)
    }

    func loadInitialData() async {
        // Убеждаемся, что базовые данные загружены
        if accountsRepository.currentAccountId == nil {
            await accountsRepository.fetchPrimaryAccount()
        }
        if categoryRepository.allCategories.isEmpty {
            await categoryRepository.fetchAllCategories()
        }
        
        guard let accountId = accountsRepository.currentAccountId else {
            errorMessage = "Не удалось загрузить счет пользователя."
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // Просто запускаем загрузку в репозитории.
        // Результат придет через подписку (sink) выше.
        await transactionsRepository.getTransactions(for: accountId, from: startOfDay, to: endOfDay)
    }
    
    func applySort() {
        switch sortOption {
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        return categoryRepository.getCategory(id: transaction.categoryId)
    }
}

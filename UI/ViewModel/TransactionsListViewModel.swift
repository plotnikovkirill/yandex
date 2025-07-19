import SwiftUI
import Combine

@MainActor
class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var sortOption: SortOption = .byDate
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        
        // Подписки на изменения в репозиториях
        transactionsRepository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        transactionsRepository.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in self?.errorMessage = error?.localizedDescription }
            .store(in: &cancellables)
    }

    func loadInitialData() async {
        // Сначала убедимся, что базовые данные (счет, категории) загружены
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
        
        let loadedTransactions = await transactionsRepository.getTransactions(for: accountId, from: startOfDay, to: endOfDay)
        
        self.transactions = loadedTransactions.filter { category(for: $0)?.direction == direction }
        self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
        applySort()
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

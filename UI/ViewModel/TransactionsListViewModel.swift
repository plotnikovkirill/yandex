//
//  TransactionsListViewModel.swift
//  yandexSMR
//
//  Created by kirill on 26.06.2025.
//
import SwiftUI
import Combine

@MainActor
class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var sortOption: SortOption = .byDate
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let direction: Direction
    private let repository: TransactionsRepository
    private var cancellables = Set<AnyCancellable>()
    // Для получения ID счета
    private let accountsRepository: AccountsRepository

    init(direction: Direction, repository: TransactionsRepository, accountsRepository: AccountsRepository) {
        self.direction = direction
        self.repository = repository
        self.accountsRepository = accountsRepository
        
        repository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        repository.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error?.localizedDescription
            }
            .store(in: &cancellables)
    }

    func loadInitialData() async {
        guard let accountId = accountsRepository.currentAccountId else {
            // Если ID еще не загружен, ждем его
            await accountsRepository.fetchPrimaryAccount()
            // Повторяем попытку
            await loadInitialData()
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        let loadedTransactions = await repository.getTransactions(for: accountId, from: startOfDay, to: endOfDay)
        
        // Фильтруем по направлению
        self.transactions = loadedTransactions.filter { ($0.categoryId < 9 && direction == .outcome) || ($0.categoryId == 9 && direction == .income) }
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
    
    // Старые методы для категорий и пагинации пока убираем, они будут в репозитории
}

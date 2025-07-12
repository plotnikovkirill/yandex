//
//  TransactionsListViewModel.swift
//  yandexSMR
//
//  Created by kirill on 26.06.2025.
//
import SwiftUI

class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var sortOption: SortOption = .byDate
    @Published var categories: [Category] = []
    
    private var currentPage = 0
    private let pageSize = 20
    private let direction: Direction
    
    var page: Int {
        currentPage
    }
    
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    
    init(direction: Direction) {
        self.direction = direction
    }
    
    func loadInitialData() async {
        await loadCategories()
        await loadTransactions(page: 0)
    }
    
    private func loadCategories() async {
        do {
            let loadedCategories = try await categoriesService.getCategories(by: direction)
            DispatchQueue.main.async {
                self.categories = loadedCategories
            }
        } catch {
            print("Error loading categories: \(error)")
        }
    }
    
    func loadTransactions(page: Int) async {
        guard !isLoading else { return }
        
        isLoading = true
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
        
        do {
            let allTransactions = try await transactionsService.transactions(accountId: 1, from: startOfDay, to: endOfDay)
            
            // Фильтрация по категориям
            let categoryIds = Set(categories.map { $0.id })
            let filteredTransactions = allTransactions.filter { categoryIds.contains($0.categoryId) }
            
            // Сортировка и пагинация
            let sortedTransactions = sort(transactions: filteredTransactions)
            let startIndex = page * pageSize
            let endIndex = min(startIndex + pageSize, sortedTransactions.count)
            
            if startIndex >= sortedTransactions.count {
                hasMore = false
                isLoading = false
                return
            }
            
            let pageItems = Array(sortedTransactions[startIndex..<endIndex])
            
            DispatchQueue.main.async {
                if page == 0 {
                    self.transactions = pageItems
                } else {
                    self.transactions += pageItems
                }
                
                self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
                self.currentPage = page + 1
                self.hasMore = endIndex < sortedTransactions.count
                self.isLoading = false
            }
        } catch {
            print("Error loading transactions: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func loadNextPage() async {
        await loadTransactions(page: currentPage)
    }
    func loadMoreIfNeeded(for transaction: Transaction) {
            // Проверяем, является ли появившаяся на экране транзакция последней в нашем списке
            if transactions.last?.id == transaction.id && hasMore {
                Task {
                    // Если да, и есть еще страницы, грузим следующую
                    await loadNextPage()
                }
            }
        }
    func applySort() {
        transactions = sort(transactions: transactions)
    }
    
    private func sort(transactions: [Transaction]) -> [Transaction] {
        switch sortOption {
        case .byDate:
            return transactions.sorted { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            return transactions.sorted { $0.amount > $1.amount }
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        categories.first { $0.id == transaction.categoryId }
    }
}

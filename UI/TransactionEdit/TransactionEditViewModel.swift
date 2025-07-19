//
//  TransactionEditViewModel.swift
//  yandexSMR
//
//  Created by kirill on 12.07.2025.
//


import Foundation

enum TransactionScreenMode {
    case create(direction: Direction)
    case edit(transaction: Transaction)

    var isCreating: Bool {
        if case .create = self { return true }
        return false
    }
}

@MainActor
final class TransactionEditViewModel: ObservableObject {
    // MARK: - Зависимости
    private let categoriesService = CategoriesService()
    private let bankAccountService = BankAccountsService()
    private let transactionsService: TransactionsServiceLogic
    // MARK: - Состояние формы
    @Published var amountString: String = ""
    @Published var selectedCategory: Category?
    @Published var transactionDate: Date = Date()
    @Published var comment: String = ""
    
    // MARK: - UI
    @Published var categories: [Category] = []
    @Published var isShowingAlert = false
    @Published var alertText = ""
    
    let mode: TransactionScreenMode
    var navigationTitle: String {
        switch mode {
        case .create(let direction):
            return direction == .income ? "Новый доход" : "Новый расход"
        case .edit(let transaction):
            // Тут можно усложнить и тоже определять направление,
            // но для простоты оставим так.
            return "Редактирование"
        }
    }
    init(mode: TransactionScreenMode, transactionsService: TransactionsServiceLogic = TransactionsService()) {
        self.mode = mode
        self.transactionsService = transactionsService
        switch mode {
        case .create(let direction):
            Task { await fetchCategories(for: direction) }

        case .edit(let transaction):
            self.amountString = "\(transaction.amount)"
            self.transactionDate = transaction.transactionDate
            self.comment = transaction.comment
            
            Task {
                let direction: Direction = (try? await categoriesService.getAllCategories().first(where: { $0.id == transaction.categoryId })?.direction) ?? .outcome
                await fetchCategories(for: direction)
                self.selectedCategory = self.categories.first { $0.id == transaction.categoryId }
            }
        }
    }
    
    // MARK: - Методы
    private func fetchCategories(for direction: Direction) async {
        // Сначала выполняем то, что в скобках, потом применяем `??`
        self.categories = (try? await categoriesService.getCategories(by: direction)) ?? []
    }
    
    // (Задание **) Валидация
    private func validate() -> Bool {
        // (Задание *) Валидация суммы, разрешаем запятую для русской локали
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        let decimalSeparator = formatter.decimalSeparator ?? "."
        
        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        
        guard Decimal(string: cleanedAmount) != nil, !cleanedAmount.isEmpty else {
            alertText = "Пожалуйста, введите корректную сумму."
            isShowingAlert = true
            return false
        }

        guard selectedCategory != nil else {
            alertText = "Пожалуйста, выберите статью."
            isShowingAlert = true
            return false
        }
        return true
    }

    func save() async throws {
            guard validate() else { return }
            
            let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
            
            switch mode {
            case .create:
                guard let primaryAccount = try? await bankAccountService.fetchAccount(userId: 1),
                      let selectedCategory = selectedCategory else { return }
                
                // ИЗМЕНЕНО: Создаем DTO для запроса
                let requestBody = TransactionRequest(
                    accountId: primaryAccount.id,
                    categoryId: selectedCategory.id,
                    amount: cleanedAmount,
                    transactionDate: transactionDate,
                    comment: comment
                )
                _ = try await transactionsService.createTransaction(requestBody: requestBody)

            case .edit(let transaction):
                // ИЗМЕНЕНО: Создаем DTO для запроса
                let requestBody = TransactionRequest(
                    accountId: transaction.accountId,
                    categoryId: selectedCategory!.id,
                    amount: cleanedAmount,
                    transactionDate: transactionDate,
                    comment: comment
                )
                _ = try await transactionsService.updateTransaction(id: transaction.id, requestBody: requestBody)
            }
        }

        func delete() async throws {
            guard case let .edit(transaction) = mode else { return }
            // ИЗМЕНЕНО: Вызываем новый метод
            try await transactionsService.deleteTransaction(id: transaction.id)
        }
}


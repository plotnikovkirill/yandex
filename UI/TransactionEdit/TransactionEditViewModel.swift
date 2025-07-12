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
    private let transactionsService = TransactionsService()
    private let bankAccountService = BankAccountsService()

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
    init(mode: TransactionScreenMode) {
        self.mode = mode
        
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
        let amount = Decimal(string: cleanedAmount) ?? 0

        switch mode {
        case .create:
            guard let primaryAccount = try? await bankAccountService.accountForUser(userId: 1),
                  let selectedCategory = selectedCategory else { return }
                  
            _ = try await transactionsService.create(
                accountId: primaryAccount.id,
                categoryId: selectedCategory.id,
                amount: amount,
                transactionDate: transactionDate,
                comment: comment
            )

        case .edit(let transaction):
            // Создаем совершенно новый экземпляр Transaction с обновленными данными
            let updatedTransaction = Transaction(
                id: transaction.id,                         // Старое значение
                accountId: transaction.accountId,           // Старое значение
                categoryId: selectedCategory!.id,           // Новое значение
                amount: amount,                             // Новое значение
                transactionDate: transactionDate,           // Новое значение
                comment: comment,                           // Новое значение
                createdAt: transaction.createdAt,           // Старое значение
                updatedAt: Date()                           // Новое значение
            )
            _ = try await transactionsService.update(updatedTransaction)
        }
    }

    func delete() async throws {
        guard case let .edit(transaction) = mode else { return }
        _ = try await transactionsService.delete(id: transaction.id)
    }
}

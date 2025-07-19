import Foundation

enum TransactionScreenMode {
    case create(direction: Direction)
    case edit(transaction: Transaction)
    var isCreating: Bool { if case .create = self { return true }; return false }
}

@MainActor
final class TransactionEditViewModel: ObservableObject {
    @Published var amountString: String = ""
    @Published var selectedCategory: Category?
    @Published var transactionDate: Date = Date()
    @Published var comment: String = ""
    
    @Published var categories: [Category] = []
    @Published var isShowingAlert = false
    @Published var alertText = ""
    
    let mode: TransactionScreenMode
    let transactionsRepository: TransactionsRepository
    let categoryRepository: CategoryRepository
    let accountsRepository: AccountsRepository

    var navigationTitle: String {
        switch mode {
        case .create(let direction): return direction == .income ? "Новый доход" : "Новый расход"
        case .edit: return "Редактирование"
        }
    }

    init(mode: TransactionScreenMode,
         transactionsRepository: TransactionsRepository,
         categoryRepository: CategoryRepository,
         accountsRepository: AccountsRepository) {
        
        self.mode = mode
        self.transactionsRepository = transactionsRepository
        self.categoryRepository = categoryRepository
        self.accountsRepository = accountsRepository
        
        switch mode {
        case .create(let direction):
            self.categories = categoryRepository.getCategories(by: direction)
            self.transactionDate = Date()
            
        case .edit(let transaction):
            self.amountString = "\(transaction.amount)"
            self.transactionDate = transaction.transactionDate
            self.comment = transaction.comment
            
            if let category = categoryRepository.getCategory(id: transaction.categoryId) {
                self.selectedCategory = category
                self.categories = categoryRepository.getCategories(by: category.direction)
            }
        }
    }
    
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

    func save() async {
        guard validate(), let accountId = accountsRepository.currentAccountId else { return }
        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        let amount = Decimal(string: cleanedAmount) ?? 0

        switch mode {
        case .create:
            guard let selectedCategory = selectedCategory else { return }
            let newTransaction = Transaction(id: Int.random(in: 1000...Int.max), accountId: accountId, categoryId: selectedCategory.id, amount: amount, transactionDate: transactionDate, comment: comment, createdAt: Date(), updatedAt: Date())
            await transactionsRepository.createTransaction(newTransaction)

        case .edit(let transaction):
            let updatedTransaction = Transaction(id: transaction.id, accountId: transaction.accountId, categoryId: selectedCategory!.id, amount: amount, transactionDate: transactionDate, comment: comment, createdAt: transaction.createdAt, updatedAt: Date())
            await transactionsRepository.updateTransaction(updatedTransaction)
        }
    }

    func delete() async {
        guard case let .edit(transaction) = mode else { return }
        await transactionsRepository.deleteTransaction(id: transaction.id)
    }
}

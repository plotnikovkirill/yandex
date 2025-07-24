import SwiftUI

@MainActor
final class AppDependencies: ObservableObject {
    // Сетевые сервисы
    private let networkClient = NetworkClient()
    let transactionService: TransactionsServiceLogic
    let bankAccountService: BankAccountsServiceLogic
    let categoryService: CategoriesServiceLogic
    
    // Хранилище
    private let swiftDataStorage = SwiftDataStorage()
    
    // Репозитории
    let transactionsRepository: TransactionsRepository
    let accountsRepository: AccountsRepository
    let categoryRepository: CategoryRepository

    init() {
        // Инициализация сетевых сервисов
        self.transactionService = TransactionsService(networkClient: networkClient)
        self.bankAccountService = BankAccountsService(networkClient: networkClient)
        self.categoryService = CategoriesService(networkClient: networkClient)
        
        // Сначала создаем AccountsRepository, так как он нужен другому репозиторию
        self.accountsRepository = AccountsRepository(
            networkService: self.bankAccountService,
            storage: self.swiftDataStorage
        )
        
        // Теперь создаем TransactionsRepository, передавая ему accountsRepository
        self.transactionsRepository = TransactionsRepository(
            networkService: self.transactionService,
            storage: self.swiftDataStorage,
            backupStorage: self.swiftDataStorage,
            accountsRepository: self.accountsRepository
        )
        
        // Создаем репозиторий для категорий
        self.categoryRepository = CategoryRepository(
            networkService: self.categoryService,
            storage: self.swiftDataStorage
        )
    }
}

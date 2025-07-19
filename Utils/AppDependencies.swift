//
//  AppDependencies.swift
//  yandexSMR
//
//  Created by kirill on 04.07.2025.
//

import SwiftUI

@MainActor
final class AppDependencies: ObservableObject {
    // Сетевые сервисы
    private let networkClient = NetworkClient()
    private let transactionService: TransactionsServiceLogic
    private let bankAccountService: BankAccountsServiceLogic
    private let categoryService: CategoriesServiceLogic
    
    // Хранилище
    private let swiftDataStorage = SwiftDataStorage()
    
    // Репозитории
    let transactionsRepository: TransactionsRepository
    let accountsRepository: AccountsRepository
    // TODO: Добавить CategoryRepository

    init() {
        self.transactionService = TransactionsService(networkClient: networkClient)
        self.bankAccountService = BankAccountsService(networkClient: networkClient)
        self.categoryService = CategoriesService(networkClient: networkClient)
        
        self.transactionsRepository = TransactionsRepository(
            networkService: self.transactionService,
            storage: self.swiftDataStorage
        )
        self.accountsRepository = AccountsRepository(
            networkService: self.bankAccountService,
            storage: self.swiftDataStorage
        )
    }
}

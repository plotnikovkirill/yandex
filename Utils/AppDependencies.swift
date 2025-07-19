//
//  AppDependencies.swift
//  yandexSMR
//
//  Created by kirill on 04.07.2025.
//

import SwiftUI

@MainActor
final class AppDependencies: ObservableObject {
    // Единый сетевой клиент для всего приложения
    private let networkClient = NetworkClient()
    
    // Сервисы, которые будут использовать этот клиент
    let bankAccountService: BankAccountsServiceLogic
    let transactionService: TransactionsServiceLogic
    let categoryService: CategoriesServiceLogic
    
    init() {
        // Создаем сервисы, передавая им наш единый networkClient
        self.bankAccountService = BankAccountsService(networkClient: networkClient)
        self.transactionService = TransactionsService(networkClient: networkClient)
        self.categoryService = CategoriesService(networkClient: networkClient)
    }
}

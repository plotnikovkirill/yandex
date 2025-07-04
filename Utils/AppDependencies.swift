//
//  AppDependencies.swift
//  yandexSMR
//
//  Created by kirill on 04.07.2025.
//

import SwiftUI

@MainActor
final class AppDependencies: ObservableObject {
    let bankAccountService: BankAccountsService
    let transactionService: TransactionsService
    let categoryService: CategoriesService
    
    init() {
        self.bankAccountService = BankAccountsService()
        self.transactionService = TransactionsService()
        self.categoryService = CategoriesService()
    }
}

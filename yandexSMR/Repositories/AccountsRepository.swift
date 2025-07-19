//
//  AccountsRepository.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

@MainActor
final class AccountsRepository: ObservableObject {
    @Published private(set) var primaryAccount: BankAccount?
    @Published var isLoading = false
    private let networkService: BankAccountsServiceLogic
    private let storage: AccountStorage
    
    init(networkService: BankAccountsServiceLogic, storage: AccountStorage) {
        self.networkService = networkService
        self.storage = storage
    }
    
    func fetchPrimaryAccount() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let account = try await networkService.fetchAccount(userId: 107)
            try await storage.upsert([account])
            self.primaryAccount = account
        } catch {
            self.primaryAccount = (try? await storage.fetchAll())?.first
        }
    }
    
    var currentAccountId: Int? {
        primaryAccount?.id
    }
}

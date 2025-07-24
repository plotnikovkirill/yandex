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
    func updateAccount(_ account: BankAccount) async {
           isLoading = true
           defer { isLoading = false }
           
           // Оптимистично обновляем UI
           self.primaryAccount = account
           try? await storage.upsert([account])
           
           // Создаем DTO для сети
           let requestBody = AccountUpdateRequest(
               name: account.name,
               balance: "\(account.balance)",
               currency: account.currency
           )
           
           do {
               // Пытаемся отправить на сервер
               let updatedAccount = try await networkService.updateAccount(id: account.id, requestBody: requestBody)
               // Если успешно, сохраняем серверную версию в базу
               try await storage.upsert([updatedAccount])
               // И снова обновляем UI, чтобы получить актуальные данные (например, updatedAt)
               self.primaryAccount = updatedAccount
           } catch {
               // Если сети нет, нужно будет добавить логику бэкапа для счетов
               // (пока просто выводим ошибку)
               print("Failed to update account online: \(error.localizedDescription)")
               // TODO: Добавить операцию обновления счета в BackupStorage
           }
       }
    var currentAccountId: Int? {
        primaryAccount?.id
    }
}

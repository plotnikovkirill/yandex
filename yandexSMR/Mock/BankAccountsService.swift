//
//  BankAccountsService.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation

protocol BankAccountsServiceLogic {
    func fetchAccount(userId: Int) async throws -> BankAccount
    func updateAccount(id: Int, requestBody: AccountUpdateRequest) async throws -> BankAccount
}

final class BankAccountsService: BankAccountsServiceLogic {
    
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func fetchAccount(userId: Int) async throws -> BankAccount {
        // API возвращает массив счетов, берем первый.
        let emptyBody: EmptyBody? = nil
        let accounts: [BankAccount] = try await networkClient.request(
            endpoint: "accounts",
            method: .get,
            body: emptyBody
        )
        guard let firstAccount = accounts.first else {
            throw NSError(domain: "BankAccountsService", code: 404, userInfo: nil) // Создать кастомную ошибку
        }
        return firstAccount
    }
    
    func updateAccount(id: Int, requestBody: AccountUpdateRequest) async throws -> BankAccount {
        return try await networkClient.request(
            endpoint: "/accounts/\(id)",
            method: .put,
            body: requestBody
        )
    }
}

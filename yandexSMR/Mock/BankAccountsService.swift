//
//  BankAccountsService.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//


import Foundation

final class BankAccountsService {
    
    private var account: BankAccount = BankAccount(
        id: 1,
        userId: 1,
        name: "Main accaunt",
        balance: 10_000.00,
        currency: "RUB",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    func accountForUser(userId: Int) async throws -> BankAccount {
        return account
    }
    
    func updateAccount(id: Int, name: String, balance: Decimal, currency: String) async throws -> BankAccount {
        guard id == account.id else {
            throw NSError(domain: "BankAccountsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Account not found"])
        }
        account = BankAccount(
            id: id,
            userId: account.userId,
            name: name,
            balance: balance,
            currency: currency,
            createdAt: account.createdAt,
            updatedAt: Date()
        )
        
        return account
    }


}

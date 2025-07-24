//
//  TransactionsService.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation

protocol TransactionsServiceLogic {
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction]
    func createTransaction(from transaction: Transaction) async throws -> Transaction
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction
    func deleteTransaction(id: Int) async throws
}

final class TransactionsService: TransactionsServiceLogic {
    
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let endpoint = "transactions/account/\(accountId)/period"
        let formatter = ISO8601DateFormatter.withFractionalSeconds
        
        let query = [
            "from": formatter.string(from: startDate),
            "to": formatter.string(from: endDate)
        ]
        
        let emptyBody: EmptyBody? = nil
        let responses: [TransactionResponse] = try await networkClient.request(endpoint: endpoint, method: .get, body: emptyBody, query: query)
        
        let transactions = responses.map { response in
            return Transaction(id: response.id, accountId: response.account.id, categoryId: response.category.id, amount: Decimal(string: response.amount) ?? 0, transactionDate: response.transactionDate, comment: response.comment, createdAt: response.createdAt, updatedAt: response.updatedAt)
        }
        return transactions
    }

    // ИЗМЕНЕНО: Метод теперь принимает Transaction и создает из него DTO
    func createTransaction(from transaction: Transaction) async throws -> Transaction {
        let requestBody = TransactionRequest(
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: "\(transaction.amount)",
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
        
        let response: TransactionResponse = try await networkClient.request(endpoint: "transactions", method: .post, body: requestBody)
        
        return Transaction(id: response.id, accountId: response.account.id, categoryId: response.category.id, amount: Decimal(string: response.amount) ?? 0, transactionDate: response.transactionDate, comment: response.comment, createdAt: response.createdAt, updatedAt: response.updatedAt)
    }
    
    // ИЗМЕНЕНО: Метод теперь принимает Transaction и создает из него DTO
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        let requestBody = TransactionRequest(
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: "\(transaction.amount)",
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
        
        let response: TransactionResponse = try await networkClient.request(endpoint: "transactions/\(transaction.id)", method: .put, body: requestBody)
        
        return Transaction(id: response.id, accountId: response.account.id, categoryId: response.category.id, amount: Decimal(string: response.amount) ?? 0, transactionDate: response.transactionDate, comment: response.comment, createdAt: response.createdAt, updatedAt: response.updatedAt)
    }

    func deleteTransaction(id: Int) async throws {
        struct EmptyResponse: Decodable {}
        let emptyBody: EmptyBody? = nil
        let _: EmptyResponse = try await networkClient.request(endpoint: "transactions/\(id)", method: .delete, body: emptyBody)
    }
}

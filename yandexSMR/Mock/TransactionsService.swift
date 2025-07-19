//
//  TransactionsService.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation

protocol TransactionsServiceLogic {
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction]
    func createTransaction(requestBody: TransactionRequest) async throws -> Transaction
    func updateTransaction(id: Int, requestBody: TransactionRequest) async throws -> Transaction
    func deleteTransaction(id: Int) async throws
}

final class TransactionsService: TransactionsServiceLogic {
    
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let endpoint = "transactions/account/\(accountId)/period"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // ИЗМЕНЕНО: Создаем словарь с query-параметрами
        let query = [
            "from": formatter.string(from: startDate),
            "to": formatter.string(from: endDate)
        ]
        
        let emptyBody: EmptyBody? = nil
        let responses: [TransactionResponse] = try await networkClient.request(
            endpoint: endpoint,
            method: .get,
            body: emptyBody, // <--- Добавлено
            query: query
        )
        
        // ИЗМЕНЕНО: Теперь нам не нужна клиентская фильтрация, сервер сделал это за нас!
        let transactions = responses.map { response in
            return Transaction(id: response.id,
                               accountId: response.account.id,           // <-- Извлекаем id
                               categoryId: response.category.id,         // <-- Извлекаем id
                               amount: Decimal(string: response.amount) ?? 0, // <-- Конвертируем String в Decimal
                               transactionDate: response.transactionDate,
                               comment: response.comment,
                               createdAt: response.createdAt,
                               updatedAt: response.updatedAt)
        }
        
        return transactions

    }

    func createTransaction(requestBody: TransactionRequest) async throws -> Transaction {
        // Сервер, скорее всего, в ответ на POST вернет тот же TransactionResponse
        let response: TransactionResponse = try await networkClient.request(
            endpoint: "transactions",
            method: .post,
            body: requestBody
        )
        // Мапим ответ в нашу внутреннюю модель
        return Transaction(
            id: response.id,
            accountId: response.account.id,
            categoryId: response.category.id,
            amount: Decimal(string: response.amount) ?? 0,
            transactionDate: response.transactionDate,
            comment: response.comment,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )
    }
    
    func updateTransaction(id: Int, requestBody: TransactionRequest) async throws -> Transaction {
        // Аналогично для PUT
        let response: TransactionResponse = try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: .put,
            body: requestBody
        )
        return Transaction(
            id: response.id,
            accountId: response.account.id,
            categoryId: response.category.id,
            amount: Decimal(string: response.amount) ?? 0,
            transactionDate: response.transactionDate,
            comment: response.comment,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )
    }

    func deleteTransaction(id: Int) async throws {
        struct EmptyResponse: Decodable {}
        let emptyBody: EmptyBody? = nil
        let _: EmptyResponse = try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: .delete,
            body: emptyBody
        )
    }
}

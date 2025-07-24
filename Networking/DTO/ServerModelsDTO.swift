//
//  ServerModelsDTO.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

// Эта структура соответствует JSON'у, который присылает сервер
struct TransactionResponse: Decodable {
    let id: Int
    let account: AccountInTransaction
    let category: Category // Наша существующая модель Category подходит, так как поля совпадают
    let amount: String
    let transactionDate: Date
    let comment: String
    let createdAt: Date
    let updatedAt: Date
}

// Вспомогательная структура для объекта "account" внутри транзакции
struct AccountInTransaction: Decodable {
    let id: Int
    let name: String
    // balance и currency нам здесь не нужны для создания Transaction,
    // но если понадобятся в будущем, их можно раскомментировать.
    // let balance: String
    // let currency: String
}


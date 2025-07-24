//
//  TransactionDTO.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

// DTO для запроса на создание/обновление (оставим его здесь же для удобства)
struct TransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String
}

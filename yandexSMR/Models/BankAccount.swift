//
//  BankAccount.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation
import SwiftData
@Model
final class BankAccount: Identifiable{
    var id: Int
    var userId: Int
    var name: String
    var balance: Decimal
    var currency: String
    var createdAt: Date
    var updatedAt: Date

    init(id: Int, userId: Int, name: String, balance: Decimal, currency: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

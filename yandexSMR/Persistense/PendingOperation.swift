//
//  PendingOperation.swift
//  yandexSMR
//
//  Created by kirill on 19.07.2025.
//

import Foundation
import SwiftData

@Model
final class PendingOperation {
    // Уникальный идентификатор самой отложенной операции
    @Attribute(.unique)
    var id: UUID
    
    // Тип операции
    var type: OperationType
    
    // JSON-представление транзакции (для create и update)
    var transactionData: Data?
    // ID транзакции для удаления
    var transactionId: Int?
    
    init(type: OperationType, transaction: Transaction) {
        self.id = UUID()
        self.type = type
        self.transactionId = transaction.id
        
        // Кодируем транзакцию в JSON для хранения
        let encoder = JSONEncoder.custom
        self.transactionData = try? encoder.encode(transaction)
    }
    
    init(type: OperationType, transactionId: Int) {
        self.id = UUID()
        self.type = type
        self.transactionId = transactionId
        self.transactionData = nil
    }
    
    // Enum для типов операций
    enum OperationType: String, Codable {
        case create
        case update
        case delete
    }
}

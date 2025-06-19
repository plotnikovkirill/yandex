//
//  yandex2Tests.swift
//  yandex2Tests
//
//  Created by kirill on 13.06.2025.
//

import Testing
import XCTest
@testable import yandexSMR

struct yandex2Tests {

    @Test func testJsonRoundTripConversion() throws {
        let transaction = Transaction(
            id: 1,
            accountId: 101,
            categoryId: 201,
            amount: 123.45,
            transactionDate: Date(timeIntervalSince1970: 1672531200),
            comment: "Test transaction",
            createdAt: Date(timeIntervalSince1970: 1672530000),
            updatedAt: Date(timeIntervalSince1970: 1672530000)
        )
        
        // Convert to JSON
        let jsonObject = transaction.jsonObject
        XCTAssertNotNil(jsonObject)
        
        // Convert back to Transaction
        guard let restored = Transaction.parse(jsonObject: jsonObject) else {
            XCTFail("Failed to parse JSON object")
            return
        }
        
        // Verify all properties
        XCTAssertEqual(transaction.id, restored.id)
        XCTAssertEqual(transaction.accountId, restored.accountId)
        XCTAssertEqual(transaction.categoryId, restored.categoryId)
        XCTAssertEqual(transaction.amount, restored.amount)
        XCTAssertEqual(transaction.transactionDate.timeIntervalSinceReferenceDate,
                       restored.transactionDate.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
        XCTAssertEqual(transaction.comment, restored.comment)
        XCTAssertEqual(transaction.createdAt.timeIntervalSinceReferenceDate,
                       restored.createdAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
        XCTAssertEqual(transaction.updatedAt.timeIntervalSinceReferenceDate,
                       restored.updatedAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }
    @Test func testInvalidJson() {
        let invalidJson: [String: Any] = [
            "id": "not_an_int",
            "accountId": 101,
            "categoryId": 201,
            "amount": "invalid",
            "transactionDate": "2023-01-01T00:00:00Z",
            "comment": "Test",
            "createdAt": "2023-01-01T00:00:00Z",
            "updatedAt": "2023-01-01T00:00:00Z"
        ]
        
        XCTAssertNil(Transaction.parse(jsonObject: invalidJson))
    }
    @Test func testCsvRoundTripConversion() {
        let transaction = Transaction(
            id: 2,
            accountId: 102,
            categoryId: 202,
            amount: 99.99,
            transactionDate: Date(timeIntervalSince1970: 1672617600),
            comment: "Test, CSV",
            createdAt: Date(timeIntervalSince1970: 1672617000),
            updatedAt: Date(timeIntervalSince1970: 1672617000)
        )
        
        // Convert to CSV
        let csvString = transaction.csvRow
        
        // Convert back from CSV
        guard let restored = Transaction.parse(csvRow: csvString) else {
            XCTFail("Failed to parse CSV row")
            return
        }
        
        // Verify all properties
        XCTAssertEqual(transaction.id, restored.id)
        XCTAssertEqual(transaction.accountId, restored.accountId)
        XCTAssertEqual(transaction.categoryId, restored.categoryId)
        XCTAssertEqual(transaction.amount, restored.amount)
        XCTAssertEqual(transaction.transactionDate.timeIntervalSinceReferenceDate,
                       restored.transactionDate.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
        XCTAssertEqual(transaction.comment, restored.comment)
        XCTAssertEqual(transaction.createdAt.timeIntervalSinceReferenceDate,
                       restored.createdAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
        XCTAssertEqual(transaction.updatedAt.timeIntervalSinceReferenceDate,
                       restored.updatedAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }
    
    @Test func testFileCacheOperations() {
        let cache = TransactionsFileCache()
        let transaction = Transaction(
            id: 3,
            accountId: 103,
            categoryId: 203,
            amount: 50.0,
            transactionDate: Date(),
            comment: "Test cache",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test add
        cache.addTransaction(transaction)
        XCTAssertEqual(cache.transactions.count, 1)
        XCTAssertEqual(cache.transactions.first?.id, 3)
        
        // Test update
        let updated = Transaction(
            id: 3,
            accountId: 103,
            categoryId: 203,
            amount: 100.0,
            transactionDate: Date(),
            comment: "Updated",
            createdAt: Date(),
            updatedAt: Date()
        )
        cache.addTransaction(updated)
        XCTAssertEqual(cache.transactions.count, 1)
        XCTAssertEqual(cache.transactions.first?.amount, 100.0)
        
        // Test delete
        cache.deleteTransaction(id: 3)
        XCTAssertTrue(cache.transactions.isEmpty)
    }

}

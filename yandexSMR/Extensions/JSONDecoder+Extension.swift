//
//  JSONDecoder+Extension.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

extension JSONDecoder {
    static var custom: JSONDecoder {
        let decoder = JSONDecoder()
        
        // Указываем, что нужно поддерживать формат ISO8601,
        // включая те, что содержат миллисекунды.
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Создаем массив форматеров. Декодер попробует каждый по очереди.
            let formatters = [
                ISO8601DateFormatter(), // Стандартный ISO8601
                ISO8601DateFormatter.withFractionalSeconds, // ISO8601 с миллисекундами
            ]

            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Cannot decode date string \(dateString)")
        })
        
        return decoder
    }
}

// Создаем статический экземпляр форматера, чтобы не создавать его каждый раз
extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

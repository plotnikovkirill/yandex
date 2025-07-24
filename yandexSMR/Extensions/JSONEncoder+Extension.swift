//
//  JSONEncoder+Extension.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

extension JSONEncoder {
    static var custom: JSONEncoder {
        let encoder = JSONEncoder()
        
        // Указываем, что даты нужно кодировать в формат ISO8601 с миллисекундами
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            var container = encoder.singleValueContainer()
            let dateString = ISO8601DateFormatter.withFractionalSeconds.string(from: date)
            try container.encode(dateString)
        })
        
        return encoder
    }
}

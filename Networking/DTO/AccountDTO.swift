//
//  AccountDTO.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

struct AccountUpdateRequest: Encodable {
    let name: String
    let balance: String // Сервер ожидает строку
    let currency: String
}

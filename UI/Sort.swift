//
//  Sort.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case byDate = "По дате"
    case byAmount = "По сумме"

    var id: String { rawValue }
}

//
//  CategoriesViewModel.swift
//  yandexSMR
//
//  Created by kirill on 04.07.2025.
//

import Foundation
import Combine
@MainActor
final class CategoriesViewModel: ObservableObject {
    // MARK: - Properties
    private let repository: CategoryRepository
    @Published private(set) var categories: [Category] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    
    var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return categories }
        return categories.filter { $0.name.fuzzyMatch(searchText) }
    }

    var suggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        return categories
            .map(\.name)
            .filter { $0.fuzzyMatch(searchText) }
    }
    
    // MARK: - Lifecycle
    init(repository: CategoryRepository) {
            self.repository = repository
            
            repository.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: &$isLoading)
                
            repository.$allCategories
                .receive(on: DispatchQueue.main)
                .assign(to: &$categories)
        }
    
    // MARK: - Methods
    func fetchCategories() async {
            isLoading = true
            errorMessage = nil // Сбрасываем старую ошибку
            defer { isLoading = false }
            
            await repository.fetchAllCategories()
        }
}

// MARK: - Fuzzy Search Extension
fileprivate extension String {
    func damerauLevenshteinDistance(to other: String) -> Int {
        let s = Array(self.lowercased())
        let t = Array(other.lowercased())
        let n = s.count, m = t.count
        guard n > 0 else { return m }
        guard m > 0 else { return n }

        var d = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { d[i][0] = i }
        for j in 0...m { d[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                let cost = s[i-1] == t[j-1] ? 0 : 1
                d[i][j] = [
                    d[i-1][j] + 1,
                    d[i][j-1] + 1,
                    d[i-1][j-1] + cost
                ].min()!

                if i > 1, j > 1,
                   s[i-1] == t[j-2],
                   s[i-2] == t[j-1] {
                    d[i][j] = Swift.min(d[i][j], d[i-2][j-2] + 1)
                }
            }
        }
        return d[n][m]
    }

    func fuzzyMatch(_ pattern: String) -> Bool {
        let text = self.lowercased()
        let pat  = pattern.lowercased()
        guard !pat.isEmpty else { return true }

        let tChars = Array(text)
        let pLen   = pat.count

        let maxLen   = max(text.count, pLen)
        let threshold = max(1, Int(Double(maxLen) * 0.1))

        let windowMin = max(1, pLen - threshold)
        let windowMax = pLen + threshold

        for start in 0..<(tChars.count) {
            for w in windowMin...windowMax {
                let end = start + w
                guard end <= tChars.count else { break }
                let substring = String(tChars[start..<end])
                let dist = substring.damerauLevenshteinDistance(to: pat)
                if dist <= threshold {
                    return true
                }
            }
        }
        return false
    }
}


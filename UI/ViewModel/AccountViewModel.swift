//
//  AccountViewModel.swift
//  yandexSMR
//
//  Created by kirill on 25.06.2025.
//
import SwiftUI
import Combine

@MainActor
class AccountViewModel: ObservableObject {
    @Published var balance: Decimal = 0.0
    @Published var currency: String = "RUB"
    @Published var balanceHidden = false
    @Published var balanceInput = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    let currencies = ["RUB", "USD", "EUR"]
    
    private let repository: AccountsRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: AccountsRepository) {
        self.repository = repository
        
        repository.$isLoading
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$isLoading)
                    
        repository.$primaryAccount
    }
    
    func refreshData() async {
        await repository.fetchPrimaryAccount()
    }

    func applyBalanceInput() {
        if let newBalance = Decimal(string: balanceInput) {
            balance = newBalance
        }
    }
    
    func saveChanges() {
        // TODO: Реализовать через репозиторий с логикой бэкапа
    }
    
    func filterBalanceInput(_ input: String) {
        // Разрешаем только цифры и точку
        let filtered = input.filter { "0123456789.".contains($0) }
        
        // Разрешаем только одну точку
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            // Если больше одной точки, оставляем только первую часть
            balanceInput = components[0] + "." + components[1]
        } else {
            balanceInput = filtered
        }
        
        // Ограничиваем 2 знака после запятой
        if components.count == 2 && components[1].count > 2 {
            balanceInput = components[0] + "." + String(components[1].prefix(2))
        }
    }
    
    // Вставка из буфера обмена
    func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            balanceInput = clipboardContent
            filterBalanceInput(clipboardContent)
        }
    }
}

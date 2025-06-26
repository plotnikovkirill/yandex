//
//  AccountViewModel.swift
//  yandexSMR
//
//  Created by kirill on 25.06.2025.
//
import SwiftUI
// MARK: - ViewModel для экрана счета
class AccountViewModel: ObservableObject {
    let currencies = ["RUB", "USD", "EUR", "GBP", "JPY", "CNY"]
    @Published var balance: Decimal = 0.0
    @Published var currency: String = "RUB"
    @Published var balanceHidden = false
    @Published var editingBalance = false
    @Published var balanceInput = ""
    
    private let accountsService = BankAccountsService()
    
    init() {
        loadAccountData()
    }
    
    // Загрузка данных счета
    func loadAccountData() {
        Task {
            do {
                let account = try await accountsService.accountForUser(userId: 1)
                DispatchQueue.main.async {
                    self.balance = account.balance
                    self.currency = account.currency
                }
            } catch {
                print("Ошибка загрузки данных счета: \(error)")
            }
        }
    }
    
    // Обновление данных (pull to refresh)
    func refreshData() async {
        await MainActor.run {
            balanceInput = ""
            editingBalance = false
        }
        loadAccountData()
    }
    
    // Сохранение изменений
    func saveChanges() {
        let newAccount = BankAccount(
            id: 1, // Пример ID
            userId: 1, // Пример ID пользователя
            name: "Основной счет",
            balance: balance,
            currency: currency,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                try await accountsService.updateAccount(id: newAccount.id, name: newAccount.name, balance: newAccount.balance, currency: newAccount.currency)
            } catch {
                print("Ошибка сохранения счета: \(error)")
            }
        }
    }
    
    // Фильтрация ввода баланса
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
    
    // Применение введенного баланса
    func applyBalanceInput() {
        if let newBalance = Decimal(string: balanceInput) {
            balance = newBalance
        }
        balanceInput = ""
    }
    
    // Вставка из буфера обмена
    func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            balanceInput = clipboardContent
            filterBalanceInput(clipboardContent)
        }
    }
}

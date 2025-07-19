//
//  AccountViewModel.swift
//  yandexSMR
//
//  Created by kirill on 25.06.2025.
//
import SwiftUI
// MARK: - ViewModel для экрана счета
class AccountViewModel: ObservableObject {
    let currencies = ["RUB", "USD", "EUR"]
    @Published var balance: Decimal = 0.0
    @Published var currency: String = "RUB"
    @Published var balanceHidden = false
    @Published var editingBalance = false
    @Published var balanceInput = ""
    @Published var errorMessage: String?
        @Published var isLoading = false
    
    private let accountsService: BankAccountsServiceLogic
    
    init(accountsService: BankAccountsServiceLogic) {
        self.accountsService = accountsService
        loadAccountData()
    }
    
    // Загрузка данных счета
    func loadAccountData() {
            Task { @MainActor in
                isLoading = true
                errorMessage = nil
                defer { isLoading = false }
                
                do {
                    let account = try await accountsService.fetchAccount(userId: 1)
                    self.balance = account.balance
                    self.currency = account.currency
                } catch {
                    self.errorMessage = error.localizedDescription
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
            Task { @MainActor in
                isLoading = true
                errorMessage = nil
                defer { isLoading = false }
                
                let requestBody = AccountUpdateRequest(
                    name: "Основной счет", // Имя пока захардкожено
                    balance: "\(balance)",
                    currency: currency
                )
                
                do {
                    // Предполагаем, что id счета всегда 1
                    let updatedAccount = try await accountsService.updateAccount(id: 1, requestBody: requestBody)
                    self.balance = updatedAccount.balance
                    self.currency = updatedAccount.currency
                } catch {
                    self.errorMessage = error.localizedDescription
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

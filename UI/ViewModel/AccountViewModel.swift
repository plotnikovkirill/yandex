import SwiftUI
import Combine

@MainActor
class AccountViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var balance: Decimal = 0.0
    @Published var currency: String = "RUB"
    @Published var balanceHidden = false
    @Published var balanceInput = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    let currencies = ["RUB", "USD", "EUR"]
    
    // MARK: - Dependencies
    private let repository: AccountsRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private State
    private var accountId: Int?

    init(repository: AccountsRepository) {
        self.repository = repository
        
        // Подписываемся на состояние загрузки из репозитория
        repository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
                    
        // Подписываемся на основной счет из репозитория
        repository.$primaryAccount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let self = self, let account = account else { return }
                
                // Обновляем все наши Published свойства, когда счет меняется
                self.accountId = account.id
                self.balance = account.balance
                self.currency = account.currency
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods (Intents)
    
    func refreshData() async {
        await repository.fetchPrimaryAccount()
    }

    func applyBalanceInput() {
        // Применяем введенное значение к нашему локальному состоянию
        if let newBalance = Decimal(string: balanceInput) {
            balance = newBalance
        }
    }
    
    func saveChanges() {
            // Убеждаемся, что у нас есть текущий счет для обновления
            guard var accountToUpdate = repository.primaryAccount else {
                errorMessage = "Невозможно сохранить изменения, счет не загружен."
                return
            }
            
            // Обновляем данные счета из полей ViewModel
            accountToUpdate.balance = self.balance
            accountToUpdate.currency = self.currency
            
            Task {
                // Вызываем метод репозитория для обновления
                await repository.updateAccount(accountToUpdate)
            }
        }
    
    func filterBalanceInput(_ input: String) {
        let filtered = input.filter { "0123456789.".contains($0) }
        
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            balanceInput = components[0] + "." + components[1]
        } else {
            balanceInput = filtered
        }
        
        if components.count == 2 && components[1].count > 2 {
            balanceInput = components[0] + "." + String(components[1].prefix(2))
        }
    }
    
    func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            balanceInput = clipboardContent
            filterBalanceInput(clipboardContent)
        }
    }
}

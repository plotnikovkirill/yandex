import SwiftUI
import Combine

// MARK: - History View Model

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var transactions: [Transaction] = [] // Отфильтрованные транзакции для этого View
    @Published var totalAmount: Decimal = 0
    @Published var sortOption: SortOption = .byDate
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var transactionToEdit: Transaction?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    let direction: Direction
    let transactionsRepository: TransactionsRepository
    let accountsRepository: AccountsRepository
    let categoryRepository: CategoryRepository
    
    private var cancellables = Set<AnyCancellable>()

    init(direction: Direction,
         transactionsRepository: TransactionsRepository,
         accountsRepository: AccountsRepository,
         categoryRepository: CategoryRepository) {
        self.direction = direction
        self.transactionsRepository = transactionsRepository
        self.accountsRepository = accountsRepository
        self.categoryRepository = categoryRepository
        
        // --- РЕАКТИВНЫЕ ПОДПИСКИ ---
        
        transactionsRepository.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        transactionsRepository.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in self?.errorMessage = error?.localizedDescription }
            .store(in: &cancellables)
        
        // Подписываемся на ОБЩИЙ список транзакций из репозитория
        transactionsRepository.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allTransactions in
                self?.process(allTransactions)
            }
            .store(in: &cancellables)
            
        // Подписываемся на изменения дат, чтобы автоматически перезагружать транзакции
        $startDate.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main).sink { [weak self] _ in self?.loadTransactions() }.store(in: &cancellables)
        $endDate.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main).sink { [weak self] _ in self?.loadTransactions() }.store(in: &cancellables)
    }
    
    // Метод, который запускает загрузку в репозитории
    func loadTransactions() {
        Task {
            guard let accountId = accountsRepository.currentAccountId else { return }
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            
            // Просто триггерим загрузку. Результат придет через подписку.
            await transactionsRepository.getTransactions(for: accountId, from: dayStart, to: dayEnd)
        }
    }
    
    // Метод для обработки и фильтрации данных, полученных от репозитория
    private func process(_ allTransactions: [Transaction]) {
        self.transactions = allTransactions.filter { category(for: $0)?.direction == direction }
        self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
        applySort()
    }
    
    func applySort() {
        switch sortOption {
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        return categoryRepository.getCategory(id: transaction.categoryId)
    }
}

// MARK: - History View

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var showSortOptions = false

    init(direction: Direction,
         transactionsRepository: TransactionsRepository,
         accountsRepository: AccountsRepository,
         categoryRepository: CategoryRepository) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(
            direction: direction,
            transactionsRepository: transactionsRepository,
            accountsRepository: accountsRepository,
            categoryRepository: categoryRepository
        ))
    }
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            mainContent
        }
        .sheet(item: $viewModel.transactionToEdit, onDismiss: { viewModel.loadTransactions() }) { transaction in
            TransactionEditView(
                mode: .edit(transaction: transaction),
                transactionsRepository: viewModel.transactionsRepository,
                categoryRepository: viewModel.categoryRepository,
                accountsRepository: viewModel.accountsRepository
            )
        }
        .confirmationDialog("Сортировать по:", isPresented: $showSortOptions) {
            ForEach(SortOption.allCases) { option in
                Button(option.rawValue) {
                    viewModel.sortOption = option
                    viewModel.applySort()
                }
            }
        }
        .task {
            // Загружаем данные при первом появлении экрана
            viewModel.loadTransactions()
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла ошибка")
        }
    }
    
    // MARK: - Subviews
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Моя история").font(.largeTitle).bold().padding(.horizontal)
            
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                listContent
            }
        }
        .background(Color("Background"))
        .toolbar { toolbarContent }
    }
    
    private var listContent: some View {
        List {
            dateSelectionSection
            amountSection
            operationsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private var dateSelectionSection: some View {
        Section {
            DatePicker("Начало", selection: $viewModel.startDate, displayedComponents: .date)
            DatePicker("Конец", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
        }
    }
    
    private var amountSection: some View {
        Section {
            HStack {
                Text("Сумма")
                Spacer()
                Text("\(viewModel.totalAmount.formatted()) ₽")
            }
        }
    }
    
    private var operationsSection: some View {
        Section(header: Text("ОПЕРАЦИИ")) {
            ForEach(viewModel.transactions) { transaction in
                Button(action: { viewModel.transactionToEdit = transaction }) {
                    TransactionRow(
                        transaction: transaction,
                        category: viewModel.category(for: transaction),
                        showEmojiBackground: true
                    )
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: { showSortOptions = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                }
                
                NavigationLink(destination: AnalysisView(
                    direction: viewModel.direction,
                    transactionsRepository: viewModel.transactionsRepository,
                    categoryRepository: viewModel.categoryRepository,
                    accountsRepository: viewModel.accountsRepository
                ).ignoresSafeArea()) {
                    Image(systemName: "doc")
                }
            }
            .foregroundColor(Color("ClockColor"))
        }
    }
}


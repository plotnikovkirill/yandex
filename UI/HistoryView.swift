import SwiftUI
import Combine

// MARK: - History View Model

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var sortOption: SortOption = .byDate
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var transactionToEdit: Transaction?
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    public let direction: Direction
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
        
        // Подписываемся на изменения дат, чтобы автоматически перезагружать транзакции
        $startDate.dropFirst().sink { [weak self] _ in self?.loadTransactionsDebounced() }.store(in: &cancellables)
        $endDate.dropFirst().sink { [weak self] _ in self?.loadTransactionsDebounced() }.store(in: &cancellables)
    }

    func loadTransactions() async {
        guard let accountId = accountsRepository.currentAccountId else {
            errorMessage = "Счет пользователя не найден."
            return
        }
        
        isLoading = true
        let dayStart = Calendar.current.startOfDay(for: startDate)
        let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        let loadedTransactions = await transactionsRepository.getTransactions(for: accountId, from: dayStart, to: dayEnd)
        
        self.transactions = loadedTransactions.filter { category(for: $0)?.direction == direction }
        self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
        applySort()
        isLoading = false
    }
    
    // Перезагрузка с небольшой задержкой, чтобы не дергать сеть при каждом изменении пикера
    private func loadTransactionsDebounced() {
        // Отменяем предыдущий запланированный вызов
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerLoad), object: nil)
        // Планируем новый через 0.5 секунды
//        self.perform(#selector(triggerLoad), with: nil, afterDelay: 0.5)
    }
    
    @objc private func triggerLoad() {
        Task { await loadTransactions() }
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
        .sheet(item: $viewModel.transactionToEdit, onDismiss: { Task { await viewModel.loadTransactions() }}) { transaction in
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
            await viewModel.loadTransactions()
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

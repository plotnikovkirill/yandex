import SwiftUI

struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var viewModel: TransactionsListViewModel
    
    // Состояния для управления модальными окнами
    @State private var isShowingAddSheet = false
    @State private var transactionToEdit: Transaction?
    @State private var showSortOptions = false

    // ViewModel инжектируется снаружи (из MainTabView)
    init(direction: Direction, viewModel: TransactionsListViewModel) {
        self.direction = direction
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            mainContentView
            
            // Кнопка "плюс" показывается только когда нет загрузки
            if !viewModel.isLoading {
                addButton
            }
        }
        .sheet(isPresented: $isShowingAddSheet, onDismiss: { Task { await viewModel.loadInitialData() }}) {
            // Открываем экран создания, передавая все репозитории
            TransactionEditView(
                mode: .create(direction: direction),
                transactionsRepository: viewModel.transactionsRepository,
                categoryRepository: viewModel.categoryRepository,
                accountsRepository: viewModel.accountsRepository
            )
        }
        .sheet(item: $transactionToEdit, onDismiss: { Task { await viewModel.loadInitialData() }}) { transaction in
            // Открываем экран редактирования, передавая все репозитории
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
            // Загружаем данные один раз при первом появлении
            await viewModel.loadInitialData()
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка")
        }
    }
    
    // MARK: - Subviews
    
    private var mainContentView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                
                // Показываем индикатор загрузки, если данных еще нет
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    transactionsList
                }
            }
            .background(Color("Background"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    private var headerView: some View {
        Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .font(.largeTitle).bold()
            .padding(.horizontal)
            .padding(8)
    }
    
    private var transactionsList: some View {
        List {
            totalAmountSection
            transactionsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadInitialData() } // Pull-to-refresh
    }
    
    @ViewBuilder
    private var totalAmountSection: some View {
        if !viewModel.transactions.isEmpty {
            Section {
                HStack {
                    Text("Всего")
                    Spacer()
                    Text("\(viewModel.totalAmount.formatted()) ₽")
                }
            }
            .listRowBackground(Color("TransactionBackColor"))
        }
    }
    
    private var transactionsSection: some View {
        Section(header: Text("ОПЕРАЦИИ").font(.caption).foregroundColor(.gray)) {
            ForEach(viewModel.transactions) { transaction in
                Button(action: { transactionToEdit = transaction }) {
                    TransactionRow(
                        transaction: transaction,
                        category: viewModel.category(for: transaction)
                    )
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { isShowingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AccentColor"))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: { showSortOptions = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                }
                
                NavigationLink(destination: HistoryView(
                    direction: direction,
                    transactionsRepository: viewModel.transactionsRepository,
                    accountsRepository: viewModel.accountsRepository,
                    categoryRepository: viewModel.categoryRepository
                )) {
                    Image(systemName: "clock")
                }
            }
            .foregroundColor(Color("ClockColor"))
        }
    }
}

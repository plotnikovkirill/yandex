//
//  TransactionsListView.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//


import SwiftUI

//struct TransactionsListView: View {
//    let direction: Direction
//
//    @State private var transactions: [Transaction] = []
//    @State private var totalAmount: Decimal = 0
//    @State private var page = 0
//    @State private var isLoadingMore = false
//    @State private var hasMore = true
//
//    @State private var showSortOptions = false
//    @State private var sortOption: SortOption = .byDate
//
//    private let pageSize = 20
//    private let transactionsService = TransactionsService()
//    private let categoriesService = CategoriesService()
//
//    var body: some View {
//        ZStack {
//            Color("Background").ignoresSafeArea()
//
//            NavigationView {
//                VStack(alignment: .leading, spacing: 0) {
//                    Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
//                        .font(.largeTitle).bold()
//                        .padding(.horizontal)
//                        .padding(8)
//
//                    List {
//                        Section {
//                            HStack {
//                                Text("Всего")
//                                Spacer()
//                                Text("\(totalAmount.formatted()) ₽")
//                                    .foregroundColor(.black)
//                            }
//                        }
//                        .listRowBackground(Color.white)
//
//                        Section(header: Text("ОПЕРАЦИИ").font(.caption).foregroundColor(.gray)) {
//                            ForEach(transactions.indices, id: \.self) { index in
//                                let transaction = transactions[index]
//
//                                TransactionRow(transaction: transaction)
//                                    .listRowBackground(Color.white)
//                                    .onAppear {
//                                        if index == transactions.count - 1, hasMore {
//                                            Task { await loadTransactions(page: page) }
//                                        }
//                                    }
//                            }
//
//                            if isLoadingMore {
//                                HStack {
//                                    Spacer()
//                                    ProgressView()
//                                    Spacer()
//                                }
//                                .listRowBackground(Color.white)
//                            }
//                        }
//                    }
//                    .listStyle(.insetGrouped)
//                    .scrollContentBackground(.hidden)
//                }
//                .background(Color("Background"))
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        HStack {
//                            Button(action: { showSortOptions = true }) {
//                                Image(systemName: "arrow.up.arrow.down")
//                                    .foregroundColor(.black)
//                            }
//                            NavigationLink(destination: HistoryView(direction: direction)) {
//                                Image(systemName: "clock")
//                                    .foregroundColor(.black)
//                            }
//                        }
//                    }
//                }
//            }
//
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        //do
//                    }) {
//                        Image(systemName: "plus")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color("AccentColor"))
//                            .clipShape(Circle())
//                            .shadow(radius: 4)
//                    }
//                    .padding(.trailing, 16)
//                    .padding(.bottom, 16)
//                }
//            }
//        }
//        .confirmationDialog("Сортировать по:", isPresented: $showSortOptions, titleVisibility: .visible) {
//            ForEach(SortOption.allCases) { option in
//                Button(option.rawValue) {
//                    sortOption = option
//                    applySort()
//                }
//            }
//            Button("Отмена", role: .cancel) {}
//        }
//        .task {
//            if transactions.isEmpty {
//                await loadTransactions(page: 0)
//            }
//        }
//    }
//
//    private func loadTransactions(page: Int) async {
//        guard !isLoadingMore else { return }
//        isLoadingMore = true
//
//        let calendar = Calendar.current
//        let startOfDay = calendar.startOfDay(for: Date())
//        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
//	
//        do {
//            let all = try await transactionsService.transactions(accountId: 1, from: startOfDay, to: endOfDay)
//            let filteredCategories = try await categoriesService.categories(for: direction)
//            let categoryIds = Set(filteredCategories.map { $0.id })
//
//            let filtered = all
//                .filter { categoryIds.contains($0.categoryId) }
//                .sorted(by: { $0.createdAt > $1.createdAt })
//
//            let startIndex = page * pageSize
//            let endIndex = min(startIndex + pageSize, filtered.count)
//
//            if startIndex >= filtered.count {
//                hasMore = false
//                isLoadingMore = false
//                return
//            }
//
//            let pageItems = Array(filtered[startIndex..<endIndex])
//
//            DispatchQueue.main.async {
//                transactions += pageItems
//                totalAmount = transactions.reduce(0) { $0 + $1.amount }
//                self.page += 1
//                hasMore = endIndex < filtered.count
//                isLoadingMore = false
//                applySort()
//            }
//        } catch {
//            print("Ошибка загрузки: \(error)")
//            isLoadingMore = false
//        }
//    }
//
//    private func applySort() {
//        switch sortOption {
//        case .byDate:
//            transactions.sort { $0.transactionDate > $1.transactionDate }
//        case .byAmount:
//            transactions.sort { $0.amount > $1.amount }
//        }
//    }
//}
struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var viewModel: TransactionsListViewModel
        
    init(direction: Direction) {
        self.direction = direction
        // Инициализация ViewModel с правильным направлением
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
    }
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            mainContentView
            addButton
        }
        // Добавляем обработчики для всего контейнера
        .confirmationDialog("Сортировать по:", isPresented: $showSortOptions, titleVisibility: .visible) {
            ForEach(SortOption.allCases) { option in
                Button(option.rawValue) {
                    viewModel.sortOption = option
                    viewModel.applySort()
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .task {
            // Загружаем данные при первом появлении
            if viewModel.transactions.isEmpty {
                await viewModel.loadInitialData()
            }
        }
    }
//    let direction: Direction
//    @StateObject private var viewModel: TransactionsListViewModel
//    
//    init(direction: Direction) {
//        self.direction = direction
//        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
//    }
    
//    var body: some View {
//        ZStack {
//            Color("Background")
//                .ignoresSafeArea()
//            
//            mainContentView
//            addButton
//        }
//    }
    
    // Основной контент экрана
    private var mainContentView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                transactionsList
            }
            .background(Color("Background"))
//            .navigationTitle("Мои расходы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    // Заголовок экрана
    private var headerView: some View {
        Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .font(.largeTitle).bold()
            .padding(.horizontal)
            .padding(8)
    }
    
    // Список транзакций
    private var transactionsList: some View {
        List {
            totalAmountSection
            transactionsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // Секция с общей суммой
    private var totalAmountSection: some View {
        Section {
            HStack {
                Text("Всего")
                Spacer()
                Text("\(viewModel.totalAmount.formatted()) ₽")
                    .foregroundColor(.black)
            }
        }
        .listRowBackground(Color.white)
    }
    
    // Секция со списком операций
    private var transactionsSection: some View {
        Section(header: sectionHeader) {
            ForEach(viewModel.transactions.indices, id: \.self) { index in
                transactionRow(for: index)
                    .onAppear { loadMoreIfNeeded(at: index) }
            }
            
            if viewModel.isLoading {
                loadingIndicator
            }
        }
    }
    
    // Заголовок секции
    private var sectionHeader: some View {
        Text("ОПЕРАЦИИ")
            .font(.caption)
            .foregroundColor(.gray)
    }
    
    // Строка транзакции
    private func transactionRow(for index: Int) -> some View {
        let transaction = viewModel.transactions[index]
        return TransactionRow(
            transaction: transaction,
            category: viewModel.category(for: transaction))
                .listRowBackground(Color.white)
    }
    
    // Индикатор загрузки
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowBackground(Color.white)
    }
    
    // Кнопка добавления
    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { /* Действие добавления */ }) {
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
    
    // Контент тулбара
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                sortButton
                historyButton
            }
        }
    }
    
    // Кнопка сортировки
    private var sortButton: some View {
        Button(action: { showSortOptions = true }) {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(Color("ClockColor"))
        }
    }
    
    // Кнопка истории
    private var historyButton: some View {
        NavigationLink(destination: HistoryView(direction: direction)) {
            Image(systemName: "clock")
                .foregroundColor(Color("ClockColor"))
        }
    }
    
    // Загрузка дополнительных данных при необходимости
//    private func loadMoreIfNeeded(at index: Int) {
//        if index == viewModel.transactions.count - 1, viewModel.hasMore {
//            Task { await viewModel.loadTransactions(page: viewModel.page) }
//        }
//    }
    private func loadMoreIfNeeded(at index: Int) {
        if index == viewModel.transactions.count - 1, viewModel.hasMore {
            Task { await viewModel.loadNextPage() }
        }
    }
    
    @State private var showSortOptions = false
    
//    var body: some View {
//        ZStack {
//            Color("Background").ignoresSafeArea()
//            
//            NavigationView {
//                VStack(alignment: .leading, spacing: 0) {
//                    Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
//                        .font(.largeTitle).bold()
//                        .padding(.horizontal)
//                        .padding(8)
//                    
//                    List {
//                        Section {
//                            HStack {
//                                Text("Всего")
//                                Spacer()
//                                Text("\(viewModel.totalAmount.formatted()) ₽")
//                                    .foregroundColor(.black)
//                            }
//                        }
//                        .listRowBackground(Color.white)
//                        
//                        Section(header: Text("ОПЕРАЦИИ").font(.caption).foregroundColor(.gray)) {
//                            ForEach(viewModel.transactions.indices, id: \.self) { index in
//                                let transaction = viewModel.transactions[index]
//                                
//                                TransactionRow(
//                                    transaction: transaction,
//                                    category: viewModel.category(for: transaction)
//                                .listRowBackground(Color.white)
//                                .onAppear {
//                                    if index == viewModel.transactions.count - 1, viewModel.hasMore {
//                                        Task { await viewModel.loadTransactions(page: viewModel.page) }
//                                    }
//                                }
//                            }
//                            
//                            if viewModel.isLoading {
//                                HStack {
//                                    Spacer()
//                                    ProgressView()
//                                    Spacer()
//                                }
//                                .listRowBackground(Color.white)
//                            }
//                        }
//                    }
//                    .listStyle(.insetGrouped)
//                    .scrollContentBackground(.hidden)
//                }
//                .background(Color("Background"))
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        HStack {
//                            Button(action: { showSortOptions = true }) {
//                                Image(systemName: "arrow.up.arrow.down")
//                                    .foregroundColor(.black)
//                            }
//                            NavigationLink(destination: HistoryView(direction: direction)) {
//                                Image(systemName: "clock")
//                                    .foregroundColor(.black)
//                            }
//                        }
//                    }
//                }
//            }
//            
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Button(action: { /* Действие добавления */ }) {
//                        Image(systemName: "plus")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color("AccentColor"))
//                            .clipShape(Circle())
//                            .shadow(radius: 4)
//                    }
//                    .padding(.trailing, 16)
//                    .padding(.bottom, 16)
//                }
//            }
//        }
//        .confirmationDialog("Сортировать по:", isPresented: $showSortOptions, titleVisibility: .visible) {
//            ForEach(SortOption.allCases) { option in
//                Button(option.rawValue) {
//                    viewModel.sortOption = option
//                    viewModel.applySort()
//                }
//            }
//            Button("Отмена", role: .cancel) {}
//        }
//        .task {
//            if viewModel.transactions.isEmpty {
//                await viewModel.loadInitialData()
//            }
//        }
//    }
}

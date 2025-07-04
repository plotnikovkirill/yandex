//
//  TransactionsListView.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//


import SwiftUI


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
                    .foregroundColor(Color("TextColor"))
                Spacer()
                Text("\(viewModel.totalAmount.formatted()) ₽")
                    .foregroundColor(.black)
            }
        }
        .listRowBackground(Color("TransactionBackColor"))
        
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
        .listRowBackground(Color("TransactionBackColor"))
        
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

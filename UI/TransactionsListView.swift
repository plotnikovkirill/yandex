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
    @State private var isShowingAddSheet = false
    @State private var transactionToEdit: Transaction?
    init(direction: Direction, viewModel: TransactionsListViewModel) {
        self.direction = direction
        // Инициализация ViewModel с правильным направлением
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            mainContentView
            addButton
        }
        .sheet(isPresented: $isShowingAddSheet, onDismiss: { Task { await viewModel.loadInitialData() }}) {
            TransactionEditView(mode: .create(direction: direction),transactionsService: viewModel.transactionsService)
        }
        .sheet(item: $transactionToEdit, onDismiss: { Task { await viewModel.loadInitialData() }}) { transaction in
            TransactionEditView(mode: .edit(transaction: transaction),transactionsService: viewModel.transactionsService)
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
            // ВАЖНО: ForEach теперь итерирует по объектам, а не индексам
            ForEach(viewModel.transactions) { transaction in
                Button(action: {
                    transactionToEdit = transaction
                }) {
                    // Вызываем обновленную функцию transactionRow
                    transactionRow(for: transaction)
                }
                .onAppear {
                    // Теперь этот вызов корректен, так как функция есть в ViewModel
                    viewModel.loadMoreIfNeeded(for: transaction)
                }
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
    private func transactionRow(for transaction: Transaction) -> some View {
        TransactionRow(
            transaction: transaction,
            category: viewModel.category(for: transaction))
                .listRowBackground(Color.white)
                .foregroundColor(.primary) // Чтобы текст не был синим, как у стандартной кнопки
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
                Button(action: {  isShowingAddSheet = true }) {
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
    
    @State private var showSortOptions = false
    
}

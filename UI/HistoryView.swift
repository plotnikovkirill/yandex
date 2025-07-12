//
//  HistoryView.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//
import SwiftUI

struct HistoryView: View {
    let direction: Direction
    @State private var transactionToEdit: Transaction?
    @State private var allCategories: [Category] = []
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    @State private var transactions: [Transaction] = []
    @State private var totalAmount: Decimal = 0
    
    @State private var showSortOptions = false
    @State private var sortOption: SortOption = .byDate
    
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    
    var body: some View {
        ZStack {
            backgroundColor
            mainContent
        }
        .sheet(item: $transactionToEdit, onDismiss: { loadTransactionsAsync() }) { transaction in
                    TransactionEditView(mode: .edit(transaction: transaction))
                }
        .confirmationDialog(
            "Сортировать по:",
            isPresented: $showSortOptions,
            titleVisibility: .visible
        ) {
            sortOptionsContent
        }
        .onAppear {
            Task { await loadTransactions() }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundColor: some View {
        Color("Background")
            .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 1) {
            headerTitle
            listContent
        }
        .background(Color("Background"))
        .toolbar { toolbarContent }
    }
    
    private var headerTitle: some View {
        Text("Моя история")
            .font(.largeTitle).bold()
            .padding(.horizontal)
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
            startDatePicker
            endDatePicker
        }
        .listRowBackground(Color.white)
    }
    
    private var startDatePicker: some View {
        HStack {
            Text("Начало")
            Spacer()
            DatePicker("", selection: $startDate, displayedComponents: [.date])
                .labelsHidden()
                .accentColor(Color("LightAccentColor"))
                .background(Color("LightAccentColor"))
                .cornerRadius(10)
                .onChange(of: startDate) { _ in
                    adjustDatesIfNeeded()
                    loadTransactionsAsync()
                }
        }
    }
    
    private var endDatePicker: some View {
        HStack {
            Text("Конец")
            Spacer()
            DatePicker("", selection: $endDate, in: ...Date(), displayedComponents: [.date])
                .labelsHidden()
                .accentColor(Color("LightAccentColor"))
                .background(Color("LightAccentColor"))
                .cornerRadius(10)
                .onChange(of: endDate) { _ in
                    adjustDatesIfNeeded()
                    loadTransactionsAsync()
                }
        }
    }
    
    private var amountSection: some View {
        Section {
            HStack {
                Text("Сумма")
                Spacer()
                Text("\(totalAmount.formatted()) ₽")
            }
        }
        .listRowBackground(Color.white)
    }
    
    private var operationsSection: some View {
        Section(header: sectionHeader) {
            ForEach(transactions) { transaction in
                            let category = allCategories.first { $0.id == transaction.categoryId }
                            
                            // ИЗМЕНЕНО: Оборачиваем в Button
                            Button(action: {
                                transactionToEdit = transaction
                            }) {
                                TransactionRow(transaction: transaction, category: category, showEmojiBackground: true)
                                    .foregroundColor(.primary)
                            }
                            .listRowBackground(Color.white)
                        }
        }
    }
    
    private var sectionHeader: some View {
        Text("ОПЕРАЦИИ")
            .font(.caption)
            .foregroundColor(.gray)
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                sortButton
                exportButton
            }
        }
    }
    
    private var sortButton: some View {
        Button {
            showSortOptions = true
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.black)
        }
    }
    
    private var exportButton: some View {
        NavigationLink(destination: AnalysisView(direction: direction).ignoresSafeArea()) {
            Image(systemName: "doc")
                .foregroundColor(Color("ClockColor"))
        }
    }
    
    private var sortOptionsContent: some View {
        Group {
            ForEach(SortOption.allCases) { option in
                Button(option.rawValue) {
                    sortOption = option
                    applySort()
                }
            }
            Button("Отмена", role: .cancel) { }
        }
    }
    
    // MARK: - Private Methods
    
    private func adjustDatesIfNeeded() {
        if startDate > endDate {
            endDate = startDate
        } else if endDate < startDate {
            startDate = endDate
        }
    }
    
    private func loadTransactionsAsync() {
        Task {
            await loadTransactions()
        }
    }
    
    private func loadTransactions() async {
        let dayStart = Calendar.current.startOfDay(for: startDate)
        let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        do {
            let all = try await transactionsService.transactions(
                accountId: 1,
                from: dayStart,
                to: dayEnd
            )
            let ids = try await categoriesService
                .getCategories(by: direction)
                .map(\.id)
            
            let filtered = all.filter { ids.contains($0.categoryId) }
            let categories = try await categoriesService.getCategories(by: direction)
            let categoryIds = Set(categories.map(\.id))
            DispatchQueue.main.async {
                self.allCategories = categories
                transactions = filtered
                applySort()
                totalAmount = filtered.reduce(0) { $0 + $1.amount }
            }
        } catch {
            print("Ошибка: \(error)")
        }
    }
    
    private func applySort() {
        switch sortOption {
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
    }
}

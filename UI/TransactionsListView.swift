//
//  TransactionsListView.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//


import SwiftUI

struct TransactionsListView: View {
    let direction: Direction

    @State private var transactions: [Transaction] = []
    @State private var totalAmount: Decimal = 0
    @State private var page = 0
    @State private var isLoadingMore = false
    @State private var hasMore = true

    @State private var showSortOptions = false
    @State private var sortOption: SortOption = .byDate

    private let pageSize = 20
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            NavigationView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
                        .font(.largeTitle).bold()
                        .padding(.horizontal)
                        .padding(8)

                    List {
                        Section {
                            HStack {
                                Text("Всего")
                                Spacer()
                                Text("\(totalAmount.formatted()) ₽")
                                    .foregroundColor(.black)
                            }
                        }
                        .listRowBackground(Color.white)

                        Section(header: Text("ОПЕРАЦИИ").font(.caption).foregroundColor(.gray)) {
                            ForEach(transactions.indices, id: \.self) { index in
                                let transaction = transactions[index]

                                TransactionRow(transaction: transaction)
                                    .listRowBackground(Color.white)
                                    .onAppear {
                                        if index == transactions.count - 1, hasMore {
                                            Task { await loadTransactions(page: page) }
                                        }
                                    }
                            }

                            if isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
                .background(Color("Background"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: { showSortOptions = true }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(.black)
                            }
                            NavigationLink(destination: HistoryView(direction: direction)) {
                                Image(systemName: "clock")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        //do
                    }) {
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
        .confirmationDialog("Сортировать по:", isPresented: $showSortOptions, titleVisibility: .visible) {
            ForEach(SortOption.allCases) { option in
                Button(option.rawValue) {
                    sortOption = option
                    applySort()
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .task {
            if transactions.isEmpty {
                await loadTransactions(page: 0)
            }
        }
    }

    private func loadTransactions(page: Int) async {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
	
        do {
            let all = try await transactionsService.transactions(accountId: 1, from: startOfDay, to: endOfDay)
            let filteredCategories = try await categoriesService.categories(for: direction)
            let categoryIds = Set(filteredCategories.map { $0.id })

            let filtered = all
                .filter { categoryIds.contains($0.categoryId) }
                .sorted(by: { $0.createdAt > $1.createdAt })

            let startIndex = page * pageSize
            let endIndex = min(startIndex + pageSize, filtered.count)

            if startIndex >= filtered.count {
                hasMore = false
                isLoadingMore = false
                return
            }

            let pageItems = Array(filtered[startIndex..<endIndex])

            DispatchQueue.main.async {
                transactions += pageItems
                totalAmount = transactions.reduce(0) { $0 + $1.amount }
                self.page += 1
                hasMore = endIndex < filtered.count
                isLoadingMore = false
                applySort()
            }
        } catch {
            print("Ошибка загрузки: \(error)")
            isLoadingMore = false
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

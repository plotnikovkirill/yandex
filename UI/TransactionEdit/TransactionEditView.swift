//
//  TransactionEditView.swift
//  yandexSMR
//
//  Created by kirill on 12.07.2025.
//


import SwiftUI

struct TransactionEditView: View {
    @StateObject private var viewModel: TransactionEditViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: TransactionScreenMode,
             transactionsRepository: TransactionsRepository,
             categoryRepository: CategoryRepository,
             accountsRepository: AccountsRepository) {
            
            _viewModel = StateObject(wrappedValue: TransactionEditViewModel(
                mode: mode,
                transactionsRepository: transactionsRepository,
                categoryRepository: categoryRepository,
                accountsRepository: accountsRepository
            ))
        }

    var body: some View {
        NavigationView {
            Form {
                // Секция для основных полей
                Section {
                    // Поле Статья (Picker)
                    Picker("Статья", selection: $viewModel.selectedCategory) {
                        Text("Не выбрана").tag(nil as Category?)
                        ForEach(viewModel.categories, id: \.self) { category in
                            HStack {
                                Text(String(category.emoji))
                                Text(category.name)
                            }.tag(category as Category?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Поле Сумма
                    HStack {
                        Text("Сумма")
                        TextField("0", text: $viewModel.amountString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }

                // Секция для Даты и Времени, раздельно, как на макете
                Section {
                    // (Задание *) Ограничиваем выбор даты
                    DatePicker("Дата", selection: $viewModel.transactionDate, in: ...Date(), displayedComponents: .date)
                    DatePicker("Время", selection: $viewModel.transactionDate, displayedComponents: .hourAndMinute)
                }
                
                // Секция для комментария
                Section(header: Text("Комментарий")) {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 80)
                }

                // Кнопка "Удалить" - видна только в режиме редактирования
                if !viewModel.mode.isCreating {
                    Section {
                        Button(action: {
                            Task {
                                try? await viewModel.delete()
                                dismiss()
                            }
                        }) {
                            Text("Удалить расход")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            // Используем новый заголовок из ViewModel
            .navigationTitle(viewModel.navigationTitle)
            // Делаем заголовок большим, как на макете
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Кнопки "Отмена" и "Сохранить"
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.mode.isCreating ? "Создать" : "Сохранить") {
                        Task {
                           if (try? await viewModel.save()) != nil {
                               dismiss()
                           }
                        }
                    }
                }
            }
            .alert("Ошибка", isPresented: $viewModel.isShowingAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertText)
            }
        }
    }
}

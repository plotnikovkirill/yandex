//
//  AccountView.swift
//  yandexSMR
//
//  Created by kirill on 25.06.2025.
//

import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").ignoresSafeArea()
                
                List {
                    Section(header: Text("Баланс")) {
                        if isEditing {
                            HStack {
                                Text("💰 Баланс")
                                    .font(.headline)
                                    .foregroundColor(Color("TextColor"))
                                Spacer()
                                TextField("Введите сумму", text: $viewModel.balanceInput) //TODO: сделать отображение текущего баланса
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: viewModel.balanceInput) { newValue in
                                        viewModel.filterBalanceInput(newValue)
                                    }
                                    .onSubmit {
                                        viewModel.applyBalanceInput()
                                    }
                                    .contextMenu {
                                        Button("Вставить") {
                                            viewModel.pasteFromClipboard()
                                        }
                                    }
                            }
                            
                        } else {
                            HStack {
                                Text("💰 Баланс")
                                    .font(.headline)
                                    .foregroundColor(Color("TextColor"))
                                Spacer()
                                
                                if viewModel.balanceHidden {
                                    Text("******")
                                        .redacted(reason: .placeholder)
                                } else {
                                    Text(viewModel.balance, format: .currency(code: viewModel.currency))
                                }
                            }
                        }
                    }
                    .listRowBackground(isEditing ? Color.white : Color("AccentColor"))
                    
                    // Секция валюты
                    Section(header: Text("Валюта")) {
                        HStack {
                            Text("Валюта")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(viewModel.currency)
                            
                            if isEditing {
                                Button(action: {
                                    showCurrencyPicker = true
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isEditing {
                                showCurrencyPicker = true
                            }
                        }
                    }
                    .listRowBackground(isEditing ? Color.white : Color("AccentColor").opacity(0.5))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden) // Важно!
                .navigationTitle("Мой счёт")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Сохранить" : "Редактировать") {
                            if isEditing {
                                viewModel.applyBalanceInput()
                                viewModel.saveChanges()
                            }
                            isEditing.toggle()
                        }
                    }
                }
                .confirmationDialog(
                    "Выберите валюту",
                    isPresented: $showCurrencyPicker,
                    titleVisibility: .visible
                ) {
                    ForEach(viewModel.currencies, id: \.self) { currency in
                        Button(currency) {
                            if currency != viewModel.currency {
                                viewModel.currency = currency
                            }
                        }
                    }
                    Button("Отмена", role: .cancel) {}
                }
                .onShake {
                    viewModel.balanceHidden.toggle()
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
        }
        .background(Color("Background").ignoresSafeArea()) // Фон для NavigationView
    }
}




extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct ShakeDetector: ViewModifier {
    let onShake: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                onShake()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(onShake: action))
    }
}

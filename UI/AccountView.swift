import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel: AccountViewModel
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    
    init(viewModel: AccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            // ZStack теперь является корневым элементом внутри NavigationView
            ZStack {
                Color("Background").ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.balance == 0 {
                    ProgressView()
                } else {
                    contentList
                }
            }
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
            // --- ВСЕ МОДИФИКАТОРЫ ПЕРЕНЕСЕНЫ СЮДА ---
            // Они применяются к ZStack, который является главным View
            .onShake {
                viewModel.balanceHidden.toggle()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка.")
            }
        }
    }
    
    private var contentList: some View {
        List {
            Section(header: Text("Баланс")) {
                if isEditing {
                    HStack {
                        Text("💰 Баланс")
                            .font(.headline)
                        Spacer()
                        TextField("Введите сумму", text: $viewModel.balanceInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onAppear {
                                viewModel.balanceInput = "\(viewModel.balance)"
                            }
                    }
                } else {
                    HStack {
                        Text("💰 Баланс")
                            .font(.headline)
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
            
            Section(header: Text("Валюта")) {
                HStack {
                    Text("Валюта")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.currency)
                    if isEditing {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
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
        .scrollContentBackground(.hidden)
        .confirmationDialog("Выберите валюту", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(viewModel.currencies, id: \.self) { currency in
                Button(currency) {
                    viewModel.currency = currency
                }
            }
        }
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

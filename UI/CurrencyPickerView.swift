//
//  CurrencyPickerView.swift
//  yandexSMR
//
//  Created by kirill on 25.06.2025.
//
import SwiftUI

// MARK: - Валютный пикер
struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    let currencies = ["RUB", "USD", "EUR"]
    
    var body: some View {
        NavigationView {
            List(currencies, id: \.self) { currency in
                HStack {
                    Text(currency)
                        .font(.title3)
                    
                    Spacer()
                    
                    if currency == selectedCurrency {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if currency != selectedCurrency {
                        selectedCurrency = currency
                    }
                }
            }
            .navigationTitle("Выберите валюту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        // Закрываем пикер
                    }
                }
            }
        }
    }
}

//
//  DateSelectionView.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//
import SwiftUI
struct DateSelectionView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        HStack {
            VStack {
                Text("Начало")
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
            }
            
            VStack {
                Text("Конец")
                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding()
    }
}

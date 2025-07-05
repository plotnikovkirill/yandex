//
//  TransactionRow.swift
//  yandexSMR
//
//  Created by kirill on 19.06.2025.
//

import SwiftUI


struct TransactionRow: View {
    let transaction: Transaction
    let category: Category?  // Категория передаётся извне
    
    var body: some View {
        HStack(spacing: 12) {
            if let category = category {
                ZStack {
                    Circle()
                        .fill(Color("ImageBackgroundColor"))
                        .frame(width: 22, height: 22)
                    
                    Text(String(category.emoji))
                        .font(.system(size: 12))
                }
                .frame(width: 34, height: 34)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .foregroundColor(Color("TextColor"))
                    
                    if !transaction.comment.isEmpty {
                        Text(transaction.comment)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(Color("TextColor"))
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    Text(transaction.comment)
                        .font(.body)
                }
            }
            
            Spacer()
            
            HStack(spacing: 14) {
                Text("\(transaction.amount.formatted()) ₽")
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.black)
                    .font(.system(size: 13, weight: .semibold))
            }
            
        }
        .listRowBackground(Color("TransactionBackColor"))
    }
}

//
//  CategoriesView.swift
//  yandexSMR
//
//  Created by kirill on 04.07.2025.
//

import SwiftUI

struct CategoriesView: View {
    // MARK: - Properties
    @StateObject private var viewModel: CategoriesViewModel
    
    // MARK: - Lifecycle
    init(viewModel: CategoriesViewModel) {
        UITableView.appearance().backgroundColor = UIColor(named: "Background")
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                else{
                    List {
                        Section(String.categoriesSectionTitle) {
                            ForEach(viewModel.filteredCategories) { category in
                                CategoryCell(
                                    category: category
                                )
                            }
                        }
                    }
                    .background(Color("Background"))
                    .scrollDismissesKeyboard(.immediately)
                    .scrollContentBackground(.hidden)
                    .navigationTitle(String.categoriesTitle)
                    
                    .searchable(
                        text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Поиск статей"
                    ) {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Text(suggestion).searchCompletion(suggestion)
                        }
                    }
                    .task {
                        await viewModel.fetchCategories()
                    }
                }
                
            }
            .background(Color("Background"))
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                            Button("OK") {
                                viewModel.errorMessage = nil // Скрываем алерт
                            }
                        }, message: {
                            Text(viewModel.errorMessage ?? "Произошла неизвестная ошибка.")
                        })
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let categoriesTitle: String = "Мои статьи"
    static let categoriesSectionTitle: String = "СТАТЬИ"
}

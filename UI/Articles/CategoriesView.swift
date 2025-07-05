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
    init(categoriesService: CategoriesService) {
        UITableView.appearance().backgroundColor = UIColor(named: "Background")
        let vm = CategoriesViewModel(
            categoriesService: categoriesService
        )
        _viewModel = StateObject(wrappedValue: vm)
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
            .background(Color("Background"))
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let categoriesTitle: String = "Мои статьи"
    static let categoriesSectionTitle: String = "СТАТЬИ"
}

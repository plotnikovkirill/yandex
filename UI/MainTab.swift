import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    
    var body: some View {
        TabView {
            Group {
                // MARK: - Tab 1: Расходы
                TransactionsListView(
                    direction: .outcome,
                    viewModel: TransactionsListViewModel(
                        direction: .outcome,
                        transactionsRepository: dependencies.transactionsRepository,
                        accountsRepository: dependencies.accountsRepository,
                        categoryRepository: dependencies.categoryRepository
                    )
                )
                .tabItem {
                    Image("Expenses")
                        .renderingMode(.template)
                    Text("Расходы")
                }
                
                // MARK: - Tab 2: Доходы
                TransactionsListView(
                    direction: .income,
                    viewModel: TransactionsListViewModel(
                        direction: .income,
                        transactionsRepository: dependencies.transactionsRepository,
                        accountsRepository: dependencies.accountsRepository,
                        categoryRepository: dependencies.categoryRepository
                    )
                )
                .tabItem {
                    Image("Income")
                        .renderingMode(.template)
                    Text("Доходы")
                }
                
                // MARK: - Tab 3: Счет
                AccountView(
                    viewModel: AccountViewModel(repository: dependencies.accountsRepository)
                )
                .tabItem {
                    Image("Score")
                        .renderingMode(.template)
                    Text("Счет")
                }
                
                // MARK: - Tab 4: Статьи
                CategoriesView(
                    viewModel: CategoriesViewModel(repository: dependencies.categoryRepository)
                )
                .tabItem {
                    Image("Articles")
                        .renderingMode(.template)
                    Text("Статьи")
                }
                
                // MARK: - Tab 5: Настройки
                Text("Настройки")
                    .tabItem {
                        Image("Settings")
                            .renderingMode(.template)
                        Text("Настройки")
                    }
            }
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .task {
            // Запускаем загрузку основных данных один раз при старте приложения
            // Эти запросы будут выполняться параллельно
            async let fetchAccounts: () = dependencies.accountsRepository.fetchPrimaryAccount()
            async let fetchCategories: () = dependencies.categoryRepository.fetchAllCategories()
            
            _ = await [fetchAccounts, fetchCategories]
        }
        .accentColor(Color("AccentColor"))
    }
}

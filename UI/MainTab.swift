import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    var body: some View {
        TabView {
            Group{
                TransactionsListView(
                    direction: .outcome,
                    viewModel: TransactionsListViewModel(
                        direction: .outcome,
                        repository: dependencies.transactionsRepository,
                        accountsRepository: dependencies.accountsRepository
                    ))
                .tabItem {
                    Image("Expenses")
                        .renderingMode(.template)
                    Text("Расходы")
                }
                
                TransactionsListView(
                    direction: .income,
                    viewModel: TransactionsListViewModel(
                        direction: .income,
                        repository: dependencies.transactionsRepository,
                        accountsRepository: dependencies.accountsRepository
                    ))
                .tabItem {
                    Image("Income")
                        .renderingMode(.template)
                    Text("Доходы")
                }
                
                AccountView(
                    viewModel: AccountViewModel(repository: dependencies.accountsRepository)
                )
                .tabItem {
                    Image("Score")
                        .renderingMode(.template)
                    Text("Счет")
                }
                
                CategoriesView(
                    viewModel: CategoriesViewModel(
                        categoriesService: dependencies.categoryService
                    )
                )
                .tabItem {
                    Image("Articles")
                        .renderingMode(.template)
                    Text("Статьи")
                }
                
                Text("Настройки")
                    .tabItem {
                        Image("Settings")
                            .renderingMode(.template)
                        Text("Настройки")
                    }
            }
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .task {
                // Запускаем загрузку счета один раз при старте приложения
                await dependencies.accountsRepository.fetchPrimaryAccount()
            }
            .accentColor(Color("AccentColor"))
            
        }
    }
}
//#Preview {
//    MainTabView()
//}

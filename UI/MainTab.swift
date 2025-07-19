import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    var body: some View {
        TabView {
            
            Group{
                TransactionsListView(direction: .outcome,
                                     viewModel: TransactionsListViewModel(
                                         direction: .outcome,
                                         transactionsService: dependencies.transactionService,
                                         categoriesService: dependencies.categoryService
                                     ))
                    .tabItem {
                        Image("Expenses")
                            .renderingMode(.template)
                        Text("Расходы")
                    }
                
                TransactionsListView(direction: .income,
                                     viewModel: TransactionsListViewModel(
                                         direction: .income,
                                         transactionsService: dependencies.transactionService,
                                         categoriesService: dependencies.categoryService
                                     ))
                    .tabItem {
                        Image("Income")
                            .renderingMode(.template)
                        Text("Доходы")
                    }
                
                AccountView(viewModel: AccountViewModel(
                    accountsService: dependencies.bankAccountService
                ))
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
        }
        .accentColor(Color("AccentColor"))
    }
}

//#Preview {
//    MainTabView()
//}

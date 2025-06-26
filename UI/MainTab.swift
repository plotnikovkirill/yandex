import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            
            Group{
                TransactionsListView(direction: .outcome)
                    .tabItem {
                        Image("Expenses")
                            .renderingMode(.template)
                        Text("Расходы")
                    }
                
                TransactionsListView(direction: .income)
                    .tabItem {
                        Image("Income")
                            .renderingMode(.template)
                        Text("Доходы")
                    }
                
                AccountView()
                    .tabItem {
                        Image("Score")
                            .renderingMode(.template)
                        Text("Счет")
                    }
                
                Text("Статьи")
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

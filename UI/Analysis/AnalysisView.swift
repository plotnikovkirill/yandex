import SwiftUI

struct AnalysisView: UIViewControllerRepresentable {
    let direction: Direction
    
    // Зависимости, которые мы получим от родительского View (HistoryView)
    let transactionsRepository: TransactionsRepository
    let categoryRepository: CategoryRepository
    let accountsRepository: AccountsRepository

    // Создаем наш UIViewController и передаем ему все зависимости
    func makeUIViewController(context: Context) -> AnalysisViewController {
        let analysisVC = AnalysisViewController(
            direction: direction,
            transactionsRepository: transactionsRepository,
            categoryRepository: categoryRepository,
            accountsRepository: accountsRepository
        )
        return analysisVC
    }

    // Этот метод не требуется для нашей задачи
    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
    }
}

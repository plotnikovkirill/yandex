//
//  AnalysisView.swift
//  yandexSMR
//
//  Created by kirill on 12.07.2025.
//

import SwiftUI

struct AnalysisView: UIViewControllerRepresentable {
    let direction: Direction

    func makeUIViewController(context: Context) -> UINavigationController {
        // Оборачиваем наш контроллер в UINavigationController,
        // чтобы у него был свой заголовок и панель навигации.
        let analysisVC = AnalysisViewController(direction: direction)
        let navController = UINavigationController(rootViewController: analysisVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Пока не требуется обновлять
    }
}

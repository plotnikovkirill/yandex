//
//  yandexSMRApp.swift
//  yandexSMR
//
//  Created by kirill on 13.06.2025.
//

import SwiftUI

@main
struct yandexSMRApp: App {
    @StateObject private var dependencies = AppDependencies()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dependencies)
        }
    }
}

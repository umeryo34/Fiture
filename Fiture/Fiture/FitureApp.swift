//
//  FitureApp.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/16.
//

import SwiftUI

@main
struct FitureApp: App {
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                // ローディング画面
                VStack {
                    Text("読み込み中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            } else if authManager.isAuthenticated {
                // 認証済み → メイン画面
                RootView()
                    .environmentObject(authManager)
            } else {
                // 未認証 → 登録画面
                SignUpView()
                    .environmentObject(authManager)
            }
        }
        .preferredColorScheme(colorScheme == "light" ? .light : colorScheme == "dark" ? .dark : nil)
    }
}

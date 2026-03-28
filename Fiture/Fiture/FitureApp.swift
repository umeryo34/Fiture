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
            Group {
                if authManager.isLoading {
                    // ローディング画面
                    VStack {
                        Text("読み込み中...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                } else {
                    // ログイン導線は一時停止し、メイン画面を常時表示
                    RootView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(colorScheme == "light" ? .light : colorScheme == "dark" ? .dark : nil)
        }
    }
}

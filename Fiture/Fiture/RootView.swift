//
//  RootView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            FoodView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Food")
                }
            
            RunView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Run")
                }
            
            TrainingBodyView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("筋トレ")
                }
            
            ProgressView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("記録")
                }
            
            UserView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("ユーザー")
                }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager.shared)
}

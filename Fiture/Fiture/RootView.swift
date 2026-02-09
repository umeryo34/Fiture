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
            HomeView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "house.fill")
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

struct RecordView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            Text("記録")
                .font(.title2)
                .fontWeight(.semibold)
            Text("データを可視化します")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager.shared)
}

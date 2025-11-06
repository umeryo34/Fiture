//
//  RootView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
            
            TargetView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
            
            RecordView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("記録")
                }
            
            UserView()
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
}

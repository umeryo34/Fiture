//
//  TargetTabView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/17.
//

import SwiftUI

struct TargetView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Training")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 30)
            
            // カスタムタブバー
            HStack(spacing: 0) {
                TabButton(
                    icon: "long.text.page.and.pencil",
                    title: "登録",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "進捗",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabButton(
                    icon: "fork.knife",
                    title: "達成済み",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // コンテンツエリア
            TabView(selection: $selectedTab) {
                SettingView()
                    .tag(0)
                
                ProgressView()
                    .tag(1)
                
                NutritionView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// カスタムタブボタン
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
}


struct ProgressView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            Text("進捗")
                .font(.title2)
                .fontWeight(.semibold)
            Text("あなたの成長を確認")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct NutritionView: View {
    var body: some View {
        VStack {
            Image(systemName: "fork.knife")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .padding()
            Text("栄養")
                .font(.title2)
                .fontWeight(.semibold)
            Text("食事を記録しましょう")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    TargetTabView()
}

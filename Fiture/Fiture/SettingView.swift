//
//  SettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/23.
//

import SwiftUI

struct SettingView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let settingItems = [
        SettingItem(imageName: "run", text: "run", color: .blue),
        SettingItem(imageName: "training", text: "training", color: .red),
        SettingItem(imageName: "calories", text: "calories", color: .green),
        SettingItem(imageName: "weight", text: "weight", color: .purple),
        SettingItem(imageName: "water", text: "water", color: .cyan),
        SettingItem(imageName: "others", text: "others", color: .orange)
    ]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(settingItems) { item in
                    SettingCard(item: item)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct SettingItem: Identifiable {
    let id = UUID()
    let imageName: String
    let text: String
    let color: Color
}

struct SettingCard: View {
    let item: SettingItem
    
    var body: some View {
        Button(action: {
            // アクション
        }) {
            ZStack {
                // 背景画像
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                
                // 半透明のオーバーレイ
                RoundedRectangle(cornerRadius: 15)
                    .fill(item.color.opacity(0.6))
                
                // 中央のテキスト
                Text(item.text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    SettingView()
}

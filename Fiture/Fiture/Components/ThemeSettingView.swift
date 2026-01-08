//
//  ThemeSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct ThemeSettingView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("テーマ設定")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                VStack(spacing: 0) {
                    ThemeOptionRow(
                        title: "ライト",
                        icon: "sun.max.fill",
                        isSelected: colorScheme == "light"
                    ) {
                        colorScheme = "light"
                    }
                    
                    Divider()
                        .padding(.leading, 65)
                    
                    ThemeOptionRow(
                        title: "ダーク",
                        icon: "moon.fill",
                        isSelected: colorScheme == "dark"
                    ) {
                        colorScheme = "dark"
                    }
                    
                    Divider()
                        .padding(.leading, 65)
                    
                    ThemeOptionRow(
                        title: "システム",
                        icon: "circle.lefthalf.filled",
                        isSelected: colorScheme == "system"
                    ) {
                        colorScheme = "system"
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("テーマ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ThemeOptionRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeSettingView()
}


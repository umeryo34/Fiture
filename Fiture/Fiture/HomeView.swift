//
//  HomeView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    
    private var userName: String {
        authManager.currentUser?.name ?? "ユーザー"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                // ロゴが入る予定
                Text("")
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        .padding(.trailing, 15)
                }
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // ユーザーヘッダー: ユーザーアイコン / 挨拶
            HStack(spacing: 14) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                    .padding(10)
                Text("こんにちは \(userName)さん")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // 連続達成記録
            StreakCard(streakDays: 7)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // 今日達成していない目標
            VStack(alignment: .leading, spacing: 12) {
                Text("今日はこれをやろう")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        TodayGoalCard(title: "ランニング", icon: "run", color: .blue, isCompleted: false)
                        TodayGoalCard(title: "筋トレ", icon: "training", color: .red, isCompleted: false)
                        TodayGoalCard(title: "水分補給", icon: "water", color: .cyan, isCompleted: false)
                        TodayGoalCard(title: "体重記録", icon: "weight", color: .purple, isCompleted: true)
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
    }
}

// 連続達成記録カード
struct StreakCard: View {
    let streakDays: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streakDays)日連続達成中！")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("この調子で続けよう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// 今日の目標カード
struct TodayGoalCard: View {
    let title: String
    let icon: String
    let color: Color
    let isCompleted: Bool
    
    var body: some View {
        Button(action: {
            // 記録画面へ遷移
        }) {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.green.opacity(0.05) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}

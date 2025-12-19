//
//  ProgressView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/24.
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var weightTargetManager = WeightTargetManager()
    @StateObject private var caloriesTargetManager = CaloriesTargetManager()
    @State private var caloriesHistory: [(date: Date, totalCalories: Double)] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("進捗")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    Text("あなたの成長を確認")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                
                // カロリーグラフ
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image("calories")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("カロリー摂取量")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 20)
                    
                    CaloriesChartView(chartData: caloriesHistory)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                }
                
                // 体重グラフ
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image("weight")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("体重の変化")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 20)
                    
                    WeightChartView(weightEntries: weightTargetManager.weightEntries)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .task {
            // 体重データとカロリーデータを取得
            if let userId = authManager.currentUser?.id {
                async let fetchWeight = weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
                async let fetchCalories = caloriesTargetManager.fetchCaloriesHistory(userId: userId, days: 30)
                
                do {
                    try await fetchWeight
                    print("体重データ取得完了: \(weightTargetManager.weightEntries.count)件")
                } catch {
                    print("体重データ取得エラー: \(error)")
                }
                
                do {
                    caloriesHistory = try await fetchCalories
                    print("カロリーデータ取得完了: \(caloriesHistory.count)件")
                } catch {
                    print("カロリーデータ取得エラー: \(error)")
                }
            } else {
                print("ユーザーIDが取得できません")
            }
        }
    }
}

#Preview {
    ProgressView()
        .environmentObject(AuthManager.shared)
}

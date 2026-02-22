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
    @State private var showingWeightSetting = false
    @State private var hasTodayWeight = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                    
                    if hasTodayWeight {
                        // 今日の体重がある場合はグラフを表示
                        WeightChartView(weightEntries: weightTargetManager.weightEntries)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal, 20)
                    } else {
                        // 今日の体重がない場合はボタンを表示
                        Button(action: {
                            showingWeightSetting = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                
                                Text("今日の体重を追加")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("体重を記録してグラフを表示")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
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
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingWeightSetting) {
            WeightSettingView()
                .environmentObject(authManager)
                .environmentObject(weightTargetManager)
                .onAppear {
                    // 今日の日付を設定
                    weightTargetManager.selectedDate = Date()
                }
        }
        .task {
            // 体重データ、カロリーデータを取得
            if let userId = authManager.currentUser?.id {
                async let fetchWeight = weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
                async let fetchTodayWeight = weightTargetManager.fetchWeightEntry(userId: userId, date: Date())
                async let fetchCalories = caloriesTargetManager.fetchCaloriesHistory(userId: userId, days: 30)
                
                do {
                    try await fetchWeight
                    print("体重データ取得完了: \(weightTargetManager.weightEntries.count)件")
                } catch {
                    print("体重データ取得エラー: \(error)")
                }
                
                do {
                    try await fetchTodayWeight
                    // 今日の体重があるかチェック
                    await MainActor.run {
                        hasTodayWeight = weightTargetManager.weightEntry != nil
                    }
                } catch {
                    print("今日の体重データ取得エラー: \(error)")
                    await MainActor.run {
                        hasTodayWeight = false
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: .init("WeightDataDidUpdate"))) { _ in
            // 体重データが更新された時に再チェック
            Task {
                if let userId = authManager.currentUser?.id {
                    try? await weightTargetManager.fetchWeightEntry(userId: userId, date: Date())
                    try? await weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
                    await MainActor.run {
                        hasTodayWeight = weightTargetManager.weightEntry != nil
                    }
                }
            }
        }
    }
}

#Preview {
    ProgressView()
        .environmentObject(AuthManager.shared)
}

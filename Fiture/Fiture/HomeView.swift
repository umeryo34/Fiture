//
//  HomeView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var caloriesTargetManager = CaloriesTargetManager()
    @State private var showingTargetSetting = false
    
    private var userName: String {
        authManager.currentUser?.name ?? "ユーザー"
    }
    
    // 目標カロリー値
    private var targetCalories: Double? {
        caloriesTargetManager.caloriesTarget?.target
    }
    
    // 合計カロリーの色を決定（目標超過時は赤色）
    private var totalCaloriesColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        return caloriesTargetManager.totalCalories > target ? .red : .green
    }
    
    // 合計カロリーの背景色を決定
    private var totalCaloriesBackgroundColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.1)
        }
        return caloriesTargetManager.totalCalories > target ? Color.red.opacity(0.1) : Color.green.opacity(0.1)
    }
    
    // 合計カロリーのボーダー色を決定
    private var totalCaloriesBorderColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.3)
        }
        return caloriesTargetManager.totalCalories > target ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                    Text("こんにちは \(userName)さん")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .lineLimit(1)
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
            
         

            // カロリー画像表示（中央）
            VStack(spacing: 16) {
                CaloriesImageDisplayView(
                    totalCalories: caloriesTargetManager.totalCalories,
                    targetCalories: targetCalories
                )
                
                // 目標設定ボタン
                if caloriesTargetManager.caloriesTarget == nil {
                    Button(action: {
                        showingTargetSetting = true
                    }) {
                        HStack {
                            Image(systemName: "target")
                                .font(.system(size: 16))
                            Text("カロリー目標を設定")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                } else {
                    Button(action: {
                        showingTargetSetting = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                            Text("目標を変更")
                                .font(.subheadline)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.vertical, 20)

            Spacer()

            // 今日の食事（下部）
            VStack(alignment: .leading, spacing: 12) {
                Text("今日の食事")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                if caloriesTargetManager.caloriesEntries.isEmpty {
                    // 食事がない場合
                    HStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("まだ食事を記録していません")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("カロリー目標を設定して記録しよう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
                } else {
                    // 食事リスト
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(caloriesTargetManager.caloriesEntries) { entry in
                                HStack {
                                    Text(entry.foodName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.0f", entry.calories)) kcal")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200)
                    
                    // 合計カロリー
                    HStack {
                        Text("合計")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) kcal")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(totalCaloriesColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(totalCaloriesBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(totalCaloriesBorderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingTargetSetting) {
            CaloriesTargetSettingView(
                caloriesTargetManager: caloriesTargetManager,
                initialTarget: targetCalories
            )
            .environmentObject(authManager)
        }
        .task {
            // 今日の食事と目標を取得
            if let userId = authManager.currentUser?.id {
                async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId)
                async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId)
                try? await fetchEntries
                try? await fetchTarget
            }
        }
    }
}

// カロリー目標設定ビュー
struct CaloriesTargetSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var caloriesTargetManager: CaloriesTargetManager
    let initialTarget: Double?
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetValue: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("calories")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("カロリー目標設定")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
                
                // 目標設定フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1日の目標カロリー (kcal)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("カロリーを入力", text: $targetValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                .padding(.horizontal, 20)
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 保存ボタン
                Button(action: saveCaloriesTarget) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text(caloriesTargetManager.caloriesTarget == nil ? "目標を作成" : "目標を更新")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Color.green : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let initial = initialTarget {
                targetValue = String(format: "%.0f", initial)
            }
        }
    }
    
    private var isFormValid: Bool {
        !targetValue.isEmpty && Double(targetValue) != nil
    }
    
    private func saveCaloriesTarget() {
        guard let target = Double(targetValue),
              let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                let currentDate = caloriesTargetManager.selectedDate
                
                // UPSERT: 既存レコードがあれば更新、なければ作成
                try await caloriesTargetManager.createOrUpdateCaloriesTarget(userId: userId, target: target, date: currentDate)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}



#Preview {
    HomeView()
}

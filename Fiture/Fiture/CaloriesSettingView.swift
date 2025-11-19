//
//  CaloriesSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct CaloriesSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var caloriesTargetManager: CaloriesTargetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var foodName: String = ""
    @State private var caloriesValue: String = ""
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
                    
                    Text("カロリー")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
                
                // 現在の目標表示
                if let caloriesTarget = caloriesTargetManager.caloriesTarget {
                    VStack(spacing: 10) {
                        Text("現在の目標")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) / \(String(format: "%.0f", caloriesTarget.target)) kcal")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        let percentage = caloriesTarget.target > 0 ? (caloriesTargetManager.totalCalories / caloriesTarget.target * 100) : 0
                        Text("\(String(format: "%.0f", min(percentage, 100)))% 達成")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 進捗バー
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(min(percentage / 100.0, 1.0)), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                }
                
                // 食事入力フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("食べ物の名前")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("例: ご飯", text: $foodName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("カロリー")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $caloriesValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("単位: kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                // 食事リスト
                if !caloriesTargetManager.caloriesEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日食べたもの")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(caloriesTargetManager.caloriesEntries) { entry in
                                    HStack {
                                        Text(entry.foodName)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(String(format: "%.0f", entry.calories)) kcal")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Button(action: {
                                            deleteEntry(entry)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 食事追加ボタン
                Button(action: addFood) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("食事を追加")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFoodFormValid ? Color.green : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .disabled(!isFoodFormValid || isLoading)
            }
            .navigationTitle("食事記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            // 既存の目標と食事を取得
            if let userId = authManager.currentUser?.id {
                async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId)
                async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId)
                try? await fetchTarget
                try? await fetchEntries
            }
        }
    }
    
    private var isFoodFormValid: Bool {
        !foodName.isEmpty && !caloriesValue.isEmpty && Double(caloriesValue) != nil
    }
    
    private func addFood() {
        guard let calories = Double(caloriesValue),
              let userId = authManager.currentUser?.id else {
            errorMessage = "有効な数値を入力してください"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await caloriesTargetManager.addCaloriesEntry(
                    userId: userId,
                    foodName: foodName,
                    calories: calories,
                    date: caloriesTargetManager.selectedDate
                )
                
                await MainActor.run {
                    isLoading = false
                    // フォームをクリア
                    foodName = ""
                    caloriesValue = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "食事の追加に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteEntry(_ entry: CaloriesEntry) {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                try await caloriesTargetManager.deleteCaloriesEntry(
                    entryId: entry.id,
                    userId: userId,
                    date: caloriesTargetManager.selectedDate
                )
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    CaloriesSettingView()
        .environmentObject(AuthManager.shared)
        .environmentObject(CaloriesTargetManager())
}


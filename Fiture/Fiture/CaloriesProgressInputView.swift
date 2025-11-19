//
//  CaloriesProgressInputView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct CaloriesProgressInputView: View {
    let caloriesTargetManager: CaloriesTargetManager
    let userId: UUID
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var foodName: String = ""
    @State private var caloriesValue: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
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
                    
                    Text("食事を追加")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
                
                // 今日の合計カロリー表示
                VStack(spacing: 10) {
                    Text("今日の合計カロリー")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) kcal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
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
                        .frame(maxHeight: 150)
                    }
                }
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // 追加ボタン
                Button(action: {
                    addFood()
                }) {
                    Text("食事を追加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.green : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("食事追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !foodName.isEmpty && !caloriesValue.isEmpty
    }
    
    private func addFood() {
        guard let calories = Double(caloriesValue) else {
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
                    date: date
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
        Task {
            do {
                try await caloriesTargetManager.deleteCaloriesEntry(entryId: entry.id, userId: userId, date: date)
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
    CaloriesProgressInputView(caloriesTargetManager: CaloriesTargetManager(), userId: UUID(), date: Date())
}


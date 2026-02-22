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
    @State private var proteinValue: String = ""
    @State private var fatValue: String = ""
    @State private var carbsValue: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var suggestedFoodEntries: [FoodEntry] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 食事入力フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("食べ物の詳細")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("例: 〇〇のハンバーグ200g", text: $foodName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: foodName) { newValue in
                                updateSuggestions(query: newValue)
                            }
                        
                        // 予測変換候補を表示
                        if !suggestedFoodEntries.isEmpty && !foodName.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(suggestedFoodEntries, id: \.foodName) { entry in
                                    Button(action: {
                                        selectSuggestion(entry)
                                    }) {
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.foodName)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                HStack(spacing: 8) {
                                                    Text("\(String(format: "%.0f", entry.calories)) kcal")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                    if let protein = entry.protein {
                                                        Text("P:\(String(format: "%.1f", protein))g")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    if let fat = entry.fat {
                                                        Text("F:\(String(format: "%.1f", fat))g")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    if let carbs = entry.carbs {
                                                        Text("C:\(String(format: "%.1f", carbs))g")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("炭水化物")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $carbsValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("単位: g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タンパク質")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $proteinValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("単位: g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("脂質")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $fatValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("単位: g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
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
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("食事を追加")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(isFormValid ? Color.red : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
        !foodName.isEmpty && !caloriesValue.isEmpty && Double(caloriesValue) != nil
    }
    
    private func addFood() {
        guard let calories = Double(caloriesValue) else {
            errorMessage = "カロリーに有効な数値を入力してください"
            showError = true
            return
        }
        
        // 栄養素はオプショナル（空の場合はnil）
        var protein: Double? = nil
        var fat: Double? = nil
        var carbs: Double? = nil
        
        if !proteinValue.isEmpty {
            guard let proteinDouble = Double(proteinValue) else {
                errorMessage = "タンパク質に有効な数値を入力してください"
                showError = true
                return
            }
            protein = proteinDouble
        }
        
        if !fatValue.isEmpty {
            guard let fatDouble = Double(fatValue) else {
                errorMessage = "脂質に有効な数値を入力してください"
                showError = true
                return
            }
            fat = fatDouble
        }
        
        if !carbsValue.isEmpty {
            guard let carbsDouble = Double(carbsValue) else {
                errorMessage = "炭水化物に有効な数値を入力してください"
                showError = true
                return
            }
            carbs = carbsDouble
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await caloriesTargetManager.addCaloriesEntry(
                    userId: userId,
                    foodName: foodName,
                    calories: calories,
                    protein: protein,
                    fat: fat,
                    carbs: carbs,
                    date: date
                )
                
                await MainActor.run {
                    isLoading = false
                    // 食べ物名と栄養素を履歴に保存
                    FoodNameHistory.shared.addFoodEntry(
                        foodName: foodName,
                        calories: calories,
                        protein: protein,
                        fat: fat,
                        carbs: carbs
                    )
                    // フォームをクリア
                    foodName = ""
                    caloriesValue = ""
                    proteinValue = ""
                    fatValue = ""
                    carbsValue = ""
                    suggestedFoodEntries = []
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
    
    // 予測変換候補を更新
    private func updateSuggestions(query: String) {
        if query.isEmpty {
            suggestedFoodEntries = []
        } else {
            suggestedFoodEntries = FoodNameHistory.shared.searchFoodEntries(query: query)
        }
    }
    
    // 候補を選択
    private func selectSuggestion(_ entry: FoodEntry) {
        foodName = entry.foodName
        caloriesValue = String(format: "%.0f", entry.calories)
        
        // 栄養素も自動入力（値がある場合のみ）
        if let protein = entry.protein {
            proteinValue = String(format: "%.1f", protein)
        } else {
            proteinValue = ""
        }
        
        if let fat = entry.fat {
            fatValue = String(format: "%.1f", fat)
        } else {
            fatValue = ""
        }
        
        if let carbs = entry.carbs {
            carbsValue = String(format: "%.1f", carbs)
        } else {
            carbsValue = ""
        }
        
        suggestedFoodEntries = []
    }
}

#Preview {
    CaloriesProgressInputView(caloriesTargetManager: CaloriesTargetManager(), userId: UUID(), date: Date())
}


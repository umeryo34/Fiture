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
    @State private var caloriesKcal: Int = 500
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var suggestedFoodEntries: [FoodEntry] = []

    private let minCaloriesKcal = 0
    private let maxCaloriesKcal = 3000

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("名前")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("例: 〇〇のハンバーグ", text: $foodName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: foodName) { newValue in
                                updateSuggestions(query: newValue)
                            }

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
                                                Text("\(String(format: "%.0f", entry.calories)) kcal")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
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

                    RulerScrollValuePicker(
                        title: "カロリー",
                        unit: "kcal",
                        minTenth: minCaloriesKcal,
                        maxTenth: maxCaloriesKcal,
                        valueScale: 1,
                        selectionTenth: $caloriesKcal
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

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
        !foodName.isEmpty && caloriesKcal > 0
    }

    private func addFood() {
        guard caloriesKcal > 0 else {
            errorMessage = "カロリーを1以上にしてください"
            showError = true
            return
        }

        isLoading = true
        showError = false

        let calories = Double(caloriesKcal)

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
                    FoodNameHistory.shared.addFoodEntry(
                        foodName: foodName,
                        calories: calories,
                        protein: nil,
                        fat: nil,
                        carbs: nil
                    )
                    foodName = ""
                    caloriesKcal = 500
                    suggestedFoodEntries = []
                    dismiss()
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

    private func updateSuggestions(query: String) {
        if query.isEmpty {
            suggestedFoodEntries = []
        } else {
            suggestedFoodEntries = FoodNameHistory.shared.searchFoodEntries(query: query)
        }
    }

    private func selectSuggestion(_ entry: FoodEntry) {
        foodName = entry.foodName
        caloriesKcal = min(maxCaloriesKcal, max(minCaloriesKcal, Int(entry.calories.rounded())))
        suggestedFoodEntries = []
    }
}

#Preview {
    CaloriesProgressInputView(caloriesTargetManager: CaloriesTargetManager(), userId: UUID(), date: Date())
}

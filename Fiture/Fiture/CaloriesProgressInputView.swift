//
//  CaloriesProgressInputView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

/// ごはんの記録（カロリーと PFC）
struct CaloriesProgressInputView: View {
    let caloriesTargetManager: CaloriesTargetManager
    let userId: UUID
    let date: Date
    /// 記録前の今日の合計（記録後の様子のプレビューに使う）
    var todayTotals = NutritionTotals()
    var burnedKcal: Double = 0
    var targetKcal: Double?

    @Environment(\.dismiss) private var dismiss
    @State private var mealType = MealType.guess()
    @State private var foodName = ""
    @State private var caloriesText = ""
    @State private var gramsText: [Macro: String] = [:]
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, calories, macro(Macro)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    mealTypePicker
                    nameCard
                    calorieCard
                    macroCard
                    previewCard
                    if let errorMessage {
                        Text(errorMessage)
                            .font(FitureTheme.rounded(13, .semibold))
                            .foregroundColor(FitureTheme.devil)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FitureTheme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().tint(.white) }
                        Text("記録する")
                    }
                }
                .buttonStyle(PuffyButtonStyle(isEnabled: isFormValid))
                .disabled(!isFormValid || isSaving)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(FitureTheme.background)
            }
            .navigationTitle("ごはんを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focusedField = nil }
                }
            }
        }
    }

    // MARK: - 入力

    private var mealTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(MealType.allCases) { type in
                let isSelected = mealType == type
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mealType = type }
                } label: {
                    VStack(spacing: 2) {
                        Text(type.emoji).font(.system(size: 22))
                        Text(type.shortName)
                            .font(FitureTheme.rounded(13, .heavy))
                    }
                    .foregroundColor(isSelected ? .white : FitureTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? FitureTheme.coral : Color.white)
                            .shadow(color: FitureTheme.coral.opacity(isSelected ? 0.3 : 0.08), radius: 6, y: 3)
                    )
                    .scaleEffect(isSelected ? 1.04 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CuteSectionTitle(emoji: "🍽️", title: "なにを食べた？")
            TextField("例: 鮭おにぎり", text: $foodName)
                .font(FitureTheme.rounded(17, .semibold))
                .foregroundColor(FitureTheme.ink)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(FitureTheme.background))
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .calories }

            let suggestions = suggestionEntries
            if !suggestions.isEmpty {
                Text(foodName.isEmpty ? "最近のごはん" : "履歴から選ぶ")
                    .font(FitureTheme.rounded(12, .bold))
                    .foregroundColor(FitureTheme.subInk)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.foodName) { entry in
                            Button { select(entry) } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.foodName)
                                        .font(FitureTheme.rounded(13, .bold))
                                        .foregroundColor(FitureTheme.ink)
                                        .lineLimit(1)
                                    Text("\(NutritionFormat.kcal(entry.calories)) kcal")
                                        .font(FitureTheme.rounded(11, .semibold))
                                        .foregroundColor(FitureTheme.coral)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(FitureTheme.blushLight))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .cuteCard()
    }

    private var calorieCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CuteSectionTitle(emoji: "🔥", title: "カロリー")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $caloriesText)
                    .keyboardType(.numberPad)
                    .font(FitureTheme.rounded(40, .heavy))
                    .foregroundColor(FitureTheme.ink)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .calories)
                Text("kcal")
                    .font(FitureTheme.rounded(17, .heavy))
                    .foregroundColor(FitureTheme.subInk)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(FitureTheme.background))

            HStack(spacing: 8) {
                ForEach([-50, 50, 100], id: \.self) { step in
                    Button {
                        caloriesText = String(max(0, (Int(caloriesText) ?? 0) + step))
                    } label: {
                        Text(step > 0 ? "+\(step)" : "\(step)")
                            .font(FitureTheme.rounded(14, .heavy))
                            .foregroundColor(FitureTheme.coral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(FitureTheme.blushLight))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let estimate = macroCalories, estimate > 0 {
                Button {
                    caloriesText = NutritionFormat.kcal(estimate)
                } label: {
                    Label("PFCから計算すると \(NutritionFormat.kcal(estimate)) kcal（反映する）", systemImage: "wand.and.stars")
                        .font(FitureTheme.rounded(12, .bold))
                        .foregroundColor(FitureTheme.leaf)
                }
                .buttonStyle(.plain)
            }
        }
        .cuteCard()
    }

    private var macroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CuteSectionTitle(emoji: "🥗", title: "PFC", trailing: "わかる分だけでOK")
            ForEach(Macro.allCases) { macro in
                HStack(spacing: 10) {
                    Text(macro.emoji)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(macro.lightColor))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(macro.name)
                            .font(FitureTheme.rounded(14, .bold))
                            .foregroundColor(FitureTheme.ink)
                        Text(macro.letter)
                            .font(FitureTheme.rounded(11, .heavy))
                            .foregroundColor(macro.color)
                    }
                    Spacer()
                    TextField("0", text: binding(for: macro))
                        .keyboardType(.decimalPad)
                        .font(FitureTheme.rounded(22, .heavy))
                        .foregroundColor(FitureTheme.ink)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(FitureTheme.background))
                        .focused($focusedField, equals: .macro(macro))
                    Text("g")
                        .font(FitureTheme.rounded(15, .heavy))
                        .foregroundColor(FitureTheme.subInk)
                }
            }
            Text("食品パッケージの「栄養成分表示」の値を入れてね")
                .font(FitureTheme.rounded(11))
                .foregroundColor(FitureTheme.subInk)
        }
        .cuteCard()
    }

    /// 記録したあとの今日の様子
    @ViewBuilder
    private var previewCard: some View {
        if let target = targetKcal, target > 0, let calories, calories > 0 {
            let net = todayTotals.calories + calories - burnedKcal
            let willBeDevil = net > target
            let wasDevil = todayTotals.calories - burnedKcal > target
            HStack(spacing: 12) {
                Image(willBeDevil ? CharacterMood.devil.imageName : CharacterMood.angel.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 4) {
                    Text("記録すると…")
                        .font(FitureTheme.rounded(12, .bold))
                        .foregroundColor(FitureTheme.subInk)
                    Text("\(NutritionFormat.kcal(net)) / \(NutritionFormat.kcal(target)) kcal")
                        .font(FitureTheme.rounded(20, .heavy))
                        .foregroundColor(willBeDevil ? FitureTheme.devil : FitureTheme.ink)
                    Text(previewMessage(willBeDevil: willBeDevil, wasDevil: wasDevil, over: net - target, remaining: target - net))
                        .font(FitureTheme.rounded(13, .bold))
                        .foregroundColor(willBeDevil ? FitureTheme.devil : FitureTheme.leaf)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .cuteCard(padding: 14, fill: willBeDevil ? FitureTheme.devilLight : Color.white)
            .animation(.easeInOut(duration: 0.2), value: willBeDevil)
        }
    }

    private func previewMessage(willBeDevil: Bool, wasDevil: Bool, over: Double, remaining: Double) -> String {
        if willBeDevil && !wasDevil {
            return "\(NutritionFormat.kcal(over)) kcal オーバーで悪魔に…😈 Runで取り返せるよ"
        }
        if willBeDevil {
            return "\(NutritionFormat.kcal(over)) kcal オーバー中😈"
        }
        return "天使のまま！あと \(NutritionFormat.kcal(remaining)) kcal😇"
    }

    // MARK: - 値

    private var calories: Double? {
        Double(caloriesText)
    }

    private func grams(_ macro: Macro) -> Double? {
        gramsText[macro].flatMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
    }

    private var macroCalories: Double? {
        let values = Macro.allCases.compactMap { macro in grams(macro).map { $0 * macro.kcalPerGram } }
        return values.isEmpty ? nil : values.reduce(0, +)
    }

    private func binding(for macro: Macro) -> Binding<String> {
        Binding(get: { gramsText[macro] ?? "" }, set: { gramsText[macro] = $0 })
    }

    private var suggestionEntries: [FoodEntry] {
        if foodName.isEmpty {
            return Array(FoodNameHistory.shared.getAllHistory().prefix(8))
        }
        return FoodNameHistory.shared.searchFoodEntries(query: foodName)
            .filter { $0.foodName != foodName }
    }

    private var isFormValid: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty && (calories ?? 0) > 0
    }

    private func select(_ entry: FoodEntry) {
        foodName = entry.foodName
        caloriesText = NutritionFormat.kcal(entry.calories)
        gramsText[.protein] = entry.protein.map(Self.gramsText)
        gramsText[.fat] = entry.fat.map(Self.gramsText)
        gramsText[.carbs] = entry.carbs.map(Self.gramsText)
        focusedField = nil
    }

    private static func gramsText(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    private func save() {
        guard let calories, calories > 0 else {
            errorMessage = "カロリーを入れてね"
            return
        }
        let name = foodName.trimmingCharacters(in: .whitespaces)
        let protein = grams(.protein), fat = grams(.fat), carbs = grams(.carbs)
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await caloriesTargetManager.addCaloriesEntry(
                    userId: userId,
                    foodName: name,
                    calories: calories,
                    protein: protein,
                    fat: fat,
                    carbs: carbs,
                    mealType: mealType,
                    date: date
                )
                FoodNameHistory.shared.addFoodEntry(foodName: name, calories: calories, protein: protein, fat: fat, carbs: carbs)
                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "記録できませんでした: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    CaloriesProgressInputView(
        caloriesTargetManager: CaloriesTargetManager(),
        userId: UUID(),
        date: Date(),
        todayTotals: NutritionTotals(calories: 1400, protein: 50, fat: 40, carbs: 180),
        targetKcal: 2000
    )
}

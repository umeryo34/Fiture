//
//  HomeView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var runCalorieReminder: RunCalorieReminderState
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var weightTargetManager = WeightTargetManager()
    @StateObject private var caloriesTargetManager = CaloriesTargetManager()
    @State private var caloriesHistory: [(date: Date, totalCalories: Double)] = []
    @State private var hasTodayWeight = false
    
    var body: some View {
        HomeViewContent(
            viewModel: viewModel,
            weightTargetManager: weightTargetManager,
            caloriesTargetManager: caloriesTargetManager,
            caloriesHistory: caloriesHistory,
            hasTodayWeight: hasTodayWeight
        )
            .environmentObject(authManager)
            .onAppear {
                viewModel.setAuthManager(authManager)
            }
            .task(id: authManager.currentUser?.id) {
                await refreshChartData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .weightDataDidUpdate)) { _ in
                Task { await refreshWeightDataOnly() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
                Task {
                    await refreshChartData()
                    syncRunTabReminder()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .runRecordDidSave)) { _ in
                Task {
                    await viewModel.fetchCaloriesData()
                    syncRunTabReminder()
                }
            }
    }

    private func syncRunTabReminder() {
        runCalorieReminder.apply(excessKcal: viewModel.excessCaloriesOverTarget)
    }

    private func refreshWeightDataOnly() async {
        guard let userId = authManager.currentUser?.id else { return }
        try? await weightTargetManager.fetchWeightEntry(userId: userId, date: Date())
        try? await weightTargetManager.fetchWeightEntries(userId: userId, days: 7)
        await MainActor.run {
            hasTodayWeight = weightTargetManager.weightEntry != nil
        }
    }

    private func refreshChartData() async {
        guard let userId = authManager.currentUser?.id else { return }

        async let fetchWeightEntries = weightTargetManager.fetchWeightEntries(userId: userId, days: 7)
        async let fetchTodayWeight = weightTargetManager.fetchWeightEntry(userId: userId, date: Date())
        async let fetchCalories = caloriesTargetManager.fetchCaloriesHistory(userId: userId, days: 30)

        _ = try? await fetchWeightEntries
        _ = try? await fetchTodayWeight
        let history = (try? await fetchCalories) ?? []

        await MainActor.run {
            hasTodayWeight = weightTargetManager.weightEntry != nil
            caloriesHistory = history
        }
    }
}

private struct HomeViewContent: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var runCalorieReminder: RunCalorieReminderState
    @Environment(\.openRunTab) private var openRunTab
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var weightTargetManager: WeightTargetManager
    @ObservedObject var caloriesTargetManager: CaloriesTargetManager
    let caloriesHistory: [(date: Date, totalCalories: Double)]
    let hasTodayWeight: Bool
    @State private var showingWeightSetting = false
    @State private var entryToDelete: CaloriesEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    CharacterGreeting(viewModel: viewModel, onRun: openRunTab)

                    CalorieRingCard(viewModel: viewModel)

                    MacroBalanceCard(totals: viewModel.nutritionTotals, goal: viewModel.nutritionGoal)

                    MealListCard(
                        sections: viewModel.mealSections,
                        onAdd: openMealInput,
                        onDelete: { entryToDelete = $0 }
                    )

                    historyCards
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .fitureScreenBackground()
            .safeAreaInset(edge: .bottom) {
                addMealButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $viewModel.showingCaloriesInput) {
            if let userId = authManager.currentUser?.id {
                CaloriesProgressInputView(
                    caloriesTargetManager: viewModel.getCaloriesTargetManager(),
                    userId: userId,
                    date: Date(),
                    todayTotals: viewModel.nutritionTotals,
                    burnedKcal: viewModel.burnedCaloriesKcal,
                    targetKcal: viewModel.targetCalories
                )
            }
        }
        .sheet(isPresented: $viewModel.showingSearch) {
            CaloriesSearchView()
                .environmentObject(authManager)
                .environmentObject(viewModel.getCaloriesTargetManager())
        }
        .sheet(isPresented: $showingWeightSetting) {
            WeightSettingView()
                .environmentObject(authManager)
                .environmentObject(weightTargetManager)
                .onAppear {
                    weightTargetManager.selectedDate = Date()
                }
        }
        .confirmationDialog(
            entryToDelete.map { "「\($0.foodName)」を削除しますか？" } ?? "",
            isPresented: Binding(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                if let entry = entryToDelete { delete(entry) }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .task {
            await viewModel.fetchCaloriesData()
            syncRunTabReminder()
        }
        .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
            Task {
                await viewModel.fetchCaloriesData()
                syncRunTabReminder()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .runRecordDidSave)) { _ in
            Task {
                await viewModel.fetchCaloriesData()
                syncRunTabReminder()
            }
        }
    }

    private func syncRunTabReminder() {
        runCalorieReminder.apply(excessKcal: viewModel.excessCaloriesOverTarget)
    }

    private func openMealInput() {
        if hasTodayWeight {
            viewModel.showingCaloriesInput = true
        } else {
            showingWeightSetting = true
        }
    }

    private func delete(_ entry: CaloriesEntry) {
        guard let userId = authManager.currentUser?.id else { return }
        Task {
            try? await viewModel.getCaloriesTargetManager().deleteCaloriesEntry(entryId: entry.id, userId: userId, date: Date())
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateText)
                    .font(FitureTheme.rounded(13, .bold))
                    .foregroundColor(FitureTheme.coral)
                Text("きょうのごはん")
                    .font(FitureTheme.rounded(28, .heavy))
                    .foregroundColor(FitureTheme.ink)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private static var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: Date())
    }

    private var historyCards: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                CuteSectionTitle(emoji: "⚖️", title: "体重の変化", trailing: "7日間")
                WeightChartView(weightEntries: weightTargetManager.weightEntries)
            }
            .cuteCard()

            VStack(alignment: .leading, spacing: 10) {
                CuteSectionTitle(emoji: "📈", title: "カロリーの記録", trailing: "30日間")
                CaloriesChartView(chartData: caloriesHistory)
            }
            .cuteCard()
        }
    }

    private var addMealButton: some View {
        Button(action: openMealInput) {
            HStack(spacing: 8) {
                Image(systemName: hasTodayWeight ? "fork.knife" : "scalemass.fill")
                Text(hasTodayWeight ? "ごはんを記録" : "まずは体重を記録")
            }
        }
        .buttonStyle(PuffyButtonStyle())
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [FitureTheme.background.opacity(0), FitureTheme.background],
                startPoint: .top,
                endPoint: .center
            )
        )
    }
}

/// キャラクターと吹き出し。目標を超えたら Run に誘う
private struct CharacterGreeting: View {
    @ObservedObject var viewModel: HomeViewModel
    let onRun: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.characterMood != nil {
                SpeechBubble(tint: isDevil ? FitureTheme.devil : FitureTheme.coral) {
                    VStack(spacing: 8) {
                        Text(message)
                            .font(FitureTheme.rounded(16, .bold))
                            .foregroundColor(FitureTheme.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if isDevil {
                            Button(action: onRun) {
                                Label("Runで取り返す", systemImage: "figure.run")
                                    .font(FitureTheme.rounded(14, .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(FitureTheme.devil))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            CharacterView(mood: viewModel.characterMood, height: 250)
                .padding(.top, -4)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.characterMood)
    }

    private var isDevil: Bool { viewModel.characterMood == .devil }

    private var message: String {
        if let excess = viewModel.excessCaloriesOverTarget {
            return "\(NutritionFormat.kcal(excess)) kcal オーバー…😈\n動いてチャラにしちゃお！"
        }
        if viewModel.caloriesEntries.isEmpty {
            return "きょうは何を食べる？\n記録してくれたら応援するよ🍙"
        }
        guard let goal = viewModel.nutritionGoal else {
            return "記録えらい！その調子😇"
        }
        let remaining = goal.calories - viewModel.netCaloriesAfterBurn
        // いちばん足りていない栄養素をすすめる
        let totals = viewModel.nutritionTotals
        let lacking = Macro.allCases
            .map { ($0, goal.grams($0) - totals.grams($0), totals.grams($0) / max(goal.grams($0), 1)) }
            .filter { $0.1 >= 5 }
            .min { $0.2 < $1.2 }
        var text = "あと \(NutritionFormat.kcal(remaining)) kcal 食べられるよ✨"
        if let (macro, grams, _) = lacking, remaining > 150 {
            text += "\n\(macro.name)をあと \(NutritionFormat.grams(grams)) とろう\(macro.emoji)"
        }
        return text
    }
}

/// 食べた・動いた・のこりのカロリーを輪で見せる
private struct CalorieRingCard: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CuteSectionTitle(emoji: "🔥", title: "カロリー", trailing: target.map { "目標 \(NutritionFormat.kcal($0)) kcal" })

            HStack(spacing: 20) {
                ring
                VStack(spacing: 10) {
                    row(emoji: "🍽️", title: "食べた", value: viewModel.totalCalories, color: FitureTheme.ink)
                    row(emoji: "👟", title: "動いた", value: viewModel.burnedCaloriesKcal, color: FitureTheme.leaf, sign: "−")
                    Divider()
                    row(emoji: "🧮", title: "差し引き", value: viewModel.netCaloriesAfterBurn, color: isOver ? FitureTheme.devil : FitureTheme.ink)
                }
            }

            if let message = viewModel.healthKitErrorMessage {
                Text(message)
                    .font(FitureTheme.rounded(11))
                    .foregroundColor(FitureTheme.subInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("「動いた」はヘルスアプリのアクティブエネルギー（今日の合計）です")
                    .font(FitureTheme.rounded(11))
                    .foregroundColor(FitureTheme.subInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HealthSourcesLink(label: "カロリー目標の出典を見る")
        }
        .cuteCard()
    }

    private var target: Double? {
        guard let target = viewModel.targetCalories, target > 0 else { return nil }
        return target
    }

    private var isOver: Bool { viewModel.excessCaloriesOverTarget != nil }

    private var progress: Double {
        guard let target else { return 0 }
        return max(viewModel.netCaloriesAfterBurn, 0) / target
    }

    private var ringColor: Color {
        if isOver { return FitureTheme.devil }
        return progress > 0.85 ? FitureTheme.halo : FitureTheme.leaf
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)
            VStack(spacing: 0) {
                if let target {
                    let remaining = target - viewModel.netCaloriesAfterBurn
                    Text(remaining >= 0 ? "のこり" : "オーバー")
                        .font(FitureTheme.rounded(11, .bold))
                        .foregroundColor(remaining >= 0 ? FitureTheme.subInk : FitureTheme.devil)
                    Text(NutritionFormat.kcal(abs(remaining)))
                        .font(FitureTheme.rounded(26, .heavy))
                        .foregroundColor(remaining >= 0 ? FitureTheme.ink : FitureTheme.devil)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                } else {
                    Text(NutritionFormat.kcal(viewModel.totalCalories))
                        .font(FitureTheme.rounded(26, .heavy))
                        .foregroundColor(FitureTheme.ink)
                }
                Text("kcal")
                    .font(FitureTheme.rounded(11, .bold))
                    .foregroundColor(FitureTheme.subInk)
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 122, height: 122)
    }

    private func row(emoji: String, title: String, value: Double, color: Color, sign: String = "") -> some View {
        HStack {
            Text(emoji)
            Text(title)
                .font(FitureTheme.rounded(13, .semibold))
                .foregroundColor(FitureTheme.subInk)
            Spacer()
            Text("\(value > 0 ? sign : "")\(NutritionFormat.kcal(value))")
                .font(FitureTheme.rounded(17, .heavy))
                .foregroundColor(color)
            Text("kcal")
                .font(FitureTheme.rounded(10, .bold))
                .foregroundColor(FitureTheme.subInk)
        }
    }
}

/// PFC（たんぱく質・脂質・炭水化物）の目安と今日の合計
private struct MacroBalanceCard: View {
    let totals: NutritionTotals
    let goal: NutritionGoal?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CuteSectionTitle(emoji: "🥗", title: "PFCバランス", trailing: goal == nil ? nil : "1日の目安")

            ForEach(Macro.allCases) { macro in
                macroRow(macro)
            }

            if goal == nil {
                Text("目標を設定すると、PFCの目安が表示されます")
                    .font(FitureTheme.rounded(11))
                    .foregroundColor(FitureTheme.subInk)
            }
            HealthSourcesLink(label: "PFCの目安の出典を見る")
        }
        .cuteCard()
    }

    private func macroRow(_ macro: Macro) -> some View {
        let eaten = totals.grams(macro)
        let target = goal?.grams(macro)
        let progress = target.map { eaten / max($0, 1) } ?? 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(macro.emoji)
                Text(macro.name)
                    .font(FitureTheme.rounded(14, .bold))
                    .foregroundColor(FitureTheme.ink)
                Text(macro.letter)
                    .font(FitureTheme.rounded(11, .heavy))
                    .foregroundColor(macro.color)
                Spacer()
                Text(NutritionFormat.grams(eaten))
                    .font(FitureTheme.rounded(16, .heavy))
                    .foregroundColor(progress > 1.15 ? FitureTheme.devil : FitureTheme.ink)
                if let target {
                    Text("/ \(NutritionFormat.grams(target))")
                        .font(FitureTheme.rounded(12, .semibold))
                        .foregroundColor(FitureTheme.subInk)
                }
                if target != nil {
                    statusBadge(progress: progress)
                }
            }
            CuteProgressBar(progress: progress, color: progress > 1.15 ? FitureTheme.devil : macro.color, track: macro.lightColor)
        }
    }

    @ViewBuilder
    private func statusBadge(progress: Double) -> some View {
        let (text, color): (String, Color) = {
            if progress > 1.15 { return ("とりすぎ", FitureTheme.devil) }
            if progress >= 0.85 { return ("ぴったり", FitureTheme.leaf) }
            return ("あと少し", FitureTheme.subInk)
        }()
        Text(text)
            .font(FitureTheme.rounded(10, .heavy))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

/// 朝・昼・夜・間食ごとの今日の記録
private struct MealListCard: View {
    let sections: [(type: MealType?, entries: [CaloriesEntry])]
    let onAdd: () -> Void
    let onDelete: (CaloriesEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CuteSectionTitle(emoji: "🍱", title: "食べたもの", trailing: sections.isEmpty ? nil : "タップで削除")

            if sections.isEmpty {
                Button(action: onAdd) {
                    VStack(spacing: 6) {
                        Text("🍙")
                            .font(.system(size: 34))
                        Text("まだ記録がないよ")
                            .font(FitureTheme.rounded(14, .bold))
                            .foregroundColor(FitureTheme.ink)
                        Text("タップして最初のごはんを記録しよう")
                            .font(FitureTheme.rounded(12))
                            .foregroundColor(FitureTheme.subInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(FitureTheme.blush, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    )
                }
                .buttonStyle(.plain)
            } else {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(section.type?.emoji ?? "🍽️")
                            Text(section.type?.name ?? "その他")
                                .font(FitureTheme.rounded(13, .heavy))
                                .foregroundColor(FitureTheme.coral)
                            Spacer()
                            Text("\(NutritionFormat.kcal(section.entries.reduce(0) { $0 + $1.calories })) kcal")
                                .font(FitureTheme.rounded(12, .bold))
                                .foregroundColor(FitureTheme.subInk)
                        }
                        ForEach(section.entries) { entry in
                            Button { onDelete(entry) } label: { row(entry) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .cuteCard()
    }

    private func row(_ entry: CaloriesEntry) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.foodName)
                    .font(FitureTheme.rounded(15, .bold))
                    .foregroundColor(FitureTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    MacroChip(macro: .protein, grams: entry.protein)
                    MacroChip(macro: .fat, grams: entry.fat)
                    MacroChip(macro: .carbs, grams: entry.carbs)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text(NutritionFormat.kcal(entry.calories))
                    .font(FitureTheme.rounded(18, .heavy))
                    .foregroundColor(FitureTheme.ink)
                Text(Self.timeText(entry.createdAt))
                    .font(FitureTheme.rounded(10, .semibold))
                    .foregroundColor(FitureTheme.subInk)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(FitureTheme.background))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("ダブルタップで削除")
    }

    private static func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
                Text("カロリー目標設定")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
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

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
        try? await weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
        await MainActor.run {
            hasTodayWeight = weightTargetManager.weightEntry != nil
        }
    }

    private func refreshChartData() async {
        guard let userId = authManager.currentUser?.id else { return }

        async let fetchWeightEntries = weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
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
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var weightTargetManager: WeightTargetManager
    @ObservedObject var caloriesTargetManager: CaloriesTargetManager
    let caloriesHistory: [(date: Date, totalCalories: Double)]
    let hasTodayWeight: Bool
    @State private var showingWeightSetting = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    calorieSummarySection
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                    CalorieBalanceCard(viewModel: viewModel)
                        .padding(.top, 12)

                    homeChartsSection
                        .padding(.top, 16)
                }
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom) {
                addMealButton
            }
        }
        .sheet(isPresented: $viewModel.showingCaloriesInput) {
            if let userId = authManager.currentUser?.id {
                CaloriesProgressInputView(
                    caloriesTargetManager: viewModel.getCaloriesTargetManager(),
                    userId: userId,
                    date: Date()
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

    @ViewBuilder
    private var calorieSummarySection: some View {
        if let target = viewModel.targetCalories, target > 0 {
            VStack(spacing: 8) {
                Text("\(String(format: "%.0f", viewModel.totalCalories)) / \(String(format: "%.0f", target)) kcal")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(viewModel.totalCalories > target ? .red : .black)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.12))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(viewModel.progressColor)
                            .frame(
                                width: min(
                                    geometry.size.width,
                                    geometry.size.width * CGFloat(min(viewModel.totalCalories / target, 1.0))
                                ),
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        } else {
            Text("\(String(format: "%.0f", viewModel.totalCalories)) kcal")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
        }
    }

    private var homeChartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("体重の変化")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)

                WeightChartView(weightEntries: weightTargetManager.weightEntries)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("カロリー摂取量")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)

                CaloriesChartView(chartData: caloriesHistory)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
            }
        }
    }

    private var addMealButton: some View {
        Button {
            if hasTodayWeight {
                viewModel.showingCaloriesInput = true
            } else {
                showingWeightSetting = true
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text(hasTodayWeight ? "食事を追加" : "体重を記録")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
}

/// 食事摂取と Run 消費カロリーの差・目標との関係
private struct CalorieBalanceCard: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カロリー収支")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)

            balanceRow(title: "食事の摂取", kcal: viewModel.totalCalories, isWarning: false)
            balanceRow(title: "消費カロリー", kcal: viewModel.burnedCaloriesKcal, isWarning: false)

            Divider()

            balanceRow(
                title: "結果（摂取 − 消費）",
                kcal: viewModel.netCaloriesAfterBurn,
                isWarning: netExceedsTarget
            )

            if let target = viewModel.targetCalories, target > 0 {
                let margin = target - viewModel.netCaloriesAfterBurn
                HStack(alignment: .firstTextBaseline) {
                    Text(margin >= 0 ? "1日の目標までの余白" : "1日の目標の超過")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                    Spacer()
                    Text("\(String(format: "%.0f", abs(margin))) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(margin >= 0 ? .black : .red)
                }
            }

            if viewModel.excessCaloriesOverTarget != nil {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.caption)
                    Text("目標超過中 — Runタブで運動の目安を確認できます")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let message = viewModel.healthKitErrorMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("消費カロリーは、ヘルスアプリの「アクティブエネルギー」（その日の合計）を表示しています。")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }

    private var netExceedsTarget: Bool {
        guard let target = viewModel.targetCalories, target > 0 else { return false }
        return viewModel.netCaloriesAfterBurn > target
    }

    private func balanceRow(title: String, kcal: Double, isWarning: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.6))
            Spacer()
            Text("\(String(format: "%.0f", kcal)) kcal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isWarning ? .red : .black)
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

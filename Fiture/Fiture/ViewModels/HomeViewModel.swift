//
//  HomeViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showingTargetSetting = false
    @Published var showingCaloriesInput = false
    @Published var showingSearch = false
    @Published var isLoading = false
    /// 選択日のヘルスケア・アクティブエネルギー合計（kcal）
    @Published var burnedCaloriesKcal: Double = 0
    @Published var healthKitErrorMessage: String?
    /// 食事と消費カロリーの初回読み込みが終わったか（読み込み途中の誤ったキャラクター表示を防ぐ）
    @Published private(set) var hasLoadedBalance = false
    
    private let caloriesTargetManager = CaloriesTargetManager()
    weak var authManager: AuthManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Computed Properties
    
    var userName: String {
        authManager?.currentUser?.name ?? "ユーザー"
    }
    
    var targetCalories: Double? {
        caloriesTargetManager.caloriesTarget?.target
    }
    
    var totalCalories: Double {
        caloriesTargetManager.totalCalories
    }

    /// 食事摂取 − 消費カロリー（運動後の「正味」摂取イメージ）
    var netCaloriesAfterBurn: Double {
        totalCalories - burnedCaloriesKcal
    }

    private var dailyBalance: DailyCalorieBalance {
        DailyCalorieBalance(
            foodIntakeKcal: totalCalories,
            activeEnergyBurnedKcal: burnedCaloriesKcal,
            targetKcal: targetCalories,
            weightKg: FitnessProfileStorage.load(userId: authManager?.currentUser?.id).weightKg
        )
    }

    /// 消費カロリーを引いたあとでも目標を超えている kcal（超過時のみ正の値）
    var excessCaloriesOverTarget: Double? {
        dailyBalance.excessOverTargetKcal
    }

    /// 摂取 − 消費が目標内なら天使、超えたら悪魔。
    /// 読み込みが終わるまでは、待たせないよう今日最後に表示した状態を使う
    var characterMood: CharacterMood? {
        guard hasLoadedBalance else {
            return CharacterMoodCache.mood(userId: authManager?.currentUser?.id)
        }
        return excessCaloriesOverTarget == nil ? .angel : .devil
    }

    var caloriesEntries: [CaloriesEntry] {
        caloriesTargetManager.caloriesEntries
    }

    /// 今日食べた kcal と PFC の合計
    var nutritionTotals: NutritionTotals {
        NutritionTotals(entries: caloriesEntries)
    }

    /// 1日のPFCの目安。カロリー目標が無いときは nil
    var nutritionGoal: NutritionGoal? {
        guard let target = targetCalories, target > 0 else { return nil }
        let bodyGoal = FitnessProfileStorage.load(userId: authManager?.currentUser?.id).bodyGoal
        return NutritionGoal.make(calories: target, bodyGoal: bodyGoal)
    }

    /// 朝・昼・夜・間食ごとの記録（区分の無い以前の記録は最後にまとめる）
    var mealSections: [(type: MealType?, entries: [CaloriesEntry])] {
        let sorted = caloriesEntries.sorted { $0.createdAt < $1.createdAt }
        var sections: [(type: MealType?, entries: [CaloriesEntry])] = MealType.allCases.compactMap { type in
            let items = sorted.filter { $0.mealType == type }
            return items.isEmpty ? nil : (type, items)
        }
        let untyped = sorted.filter { $0.mealType == nil }
        if !untyped.isEmpty {
            sections.append((nil, untyped))
        }
        return sections
    }
    
    var totalCaloriesColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .black
        }
        return totalCalories > target ? .red : .black
    }
    
    var totalCaloriesBackgroundColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.black.opacity(0.05)
        }
        return totalCalories > target ? Color.red.opacity(0.08) : Color.black.opacity(0.05)
    }
    
    var totalCaloriesBorderColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.black.opacity(0.15)
        }
        return totalCalories > target ? Color.red.opacity(0.3) : Color.black.opacity(0.15)
    }
    
    /// 上部の数値・バーの色。キャラクターやカロリー収支と同じく、摂取 − 消費で判定する
    var progressColor: Color {
        excessCaloriesOverTarget == nil ? .black : .red
    }
    
    // MARK: - Methods
    
    func fetchCaloriesData() async {
        await fetchCaloriesDataForDate(Date())
    }
    
    func fetchCaloriesDataForDate(_ date: Date) async {
        guard let userId = authManager?.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId, date: date)
        async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId, date: date)
        
        try? await fetchEntries
        try? await fetchTarget
        await fetchBurnedCaloriesFromHealth(for: date)
        hasLoadedBalance = true
        if Calendar.current.isDateInToday(date), let characterMood {
            CharacterMoodCache.save(characterMood, userId: userId)
        }
    }

    func fetchBurnedCaloriesFromHealth(for date: Date) async {
        healthKitErrorMessage = nil
        guard HealthKitCalorieService.shared.isAvailable else {
            burnedCaloriesKcal = 0
            healthKitErrorMessage = "この端末ではヘルスケアを利用できません。"
            return
        }

        do {
            try await HealthKitCalorieService.shared.requestAuthorization()
            burnedCaloriesKcal = try await HealthKitCalorieService.shared.activeEnergyBurnedKcal(on: date)
        } catch {
            burnedCaloriesKcal = 0
            healthKitErrorMessage = error.localizedDescription
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    func getCaloriesTargetManager() -> CaloriesTargetManager {
        return caloriesTargetManager
    }
}

/// 最後に表示したキャラクターの状態。日付が変わったら、まだ何も食べていないので天使から始める
private enum CharacterMoodCache {
    private static func key(_ userId: UUID) -> String {
        "fiture_character_mood_\(userId.uuidString.lowercased())"
    }

    static func mood(userId: UUID?) -> CharacterMood? {
        guard let userId else { return nil }
        guard let saved = UserDefaults.standard.dictionary(forKey: key(userId)),
              let date = saved["date"] as? Date, Calendar.current.isDateInToday(date),
              let rawValue = saved["mood"] as? String else {
            return .angel
        }
        return CharacterMood(rawValue: rawValue) ?? .angel
    }

    static func save(_ mood: CharacterMood, userId: UUID) {
        UserDefaults.standard.set(["mood": mood.rawValue, "date": Date()] as [String: Any], forKey: key(userId))
    }
}

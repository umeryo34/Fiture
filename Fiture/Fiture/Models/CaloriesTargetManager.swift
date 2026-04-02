//
//  CaloriesTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

extension Notification.Name {
    static let caloriesDataDidUpdate = Notification.Name("caloriesDataDidUpdate")
}

class CaloriesTargetManager: ObservableObject {
    @Published var caloriesEntries: [CaloriesEntry] = []
    @Published var caloriesTarget: CaloriesTarget?
    @Published var selectedDate: Date = Date()
    
    // 合計カロリーを計算
    var totalCalories: Double {
        caloriesEntries.reduce(0) { $0 + $1.calories }
    }
    
    // 食事記録を取得
    func fetchCaloriesEntries(userId: UUID, date: Date = Date()) async throws {
        await MainActor.run {
            caloriesEntries = LocalDataStore.shared.caloriesEntries(userId: userId, date: date)
            selectedDate = date
        }
    }
    
    // 食事を追加
    func addCaloriesEntry(userId: UUID, foodName: String, calories: Double, protein: Double? = nil, fat: Double? = nil, carbs: Double? = nil, date: Date = Date()) async throws {
        _ = LocalDataStore.shared.addCaloriesEntry(
            userId: userId,
            date: date,
            foodName: foodName,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs
        )
        
        // 再取得
        try await fetchCaloriesEntries(userId: userId, date: date)
        
        // データ更新を通知
        await MainActor.run {
            NotificationCenter.default.post(name: .caloriesDataDidUpdate, object: nil)
        }
    }
    
    // 食事を削除
    func deleteCaloriesEntry(entryId: Int, userId: UUID, date: Date? = nil) async throws {
        LocalDataStore.shared.deleteCaloriesEntry(entryId: entryId, userId: userId)
        
        // 再取得
        let targetDate = date ?? selectedDate
        try await fetchCaloriesEntries(userId: userId, date: targetDate)
        
        // データ更新を通知
        await MainActor.run {
            NotificationCenter.default.post(name: .caloriesDataDidUpdate, object: nil)
        }
    }
    
    // カロリー目標を取得
    func fetchCaloriesTarget(userId: UUID, date: Date = Date()) async throws {
        await MainActor.run {
            caloriesTarget = LocalDataStore.shared.caloriesTarget(userId: userId, date: date)
            selectedDate = date
        }
    }
    
    // カロリー目標を作成または更新
    func createOrUpdateCaloriesTarget(userId: UUID, target: Double, date: Date = Date()) async throws {
        _ = LocalDataStore.shared.upsertCaloriesTarget(userId: userId, date: date, target: target)
        try await fetchCaloriesTarget(userId: userId, date: date)
    }
    
    // カロリー目標を更新
    func updateCaloriesTarget(userId: UUID, target: Double, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        _ = LocalDataStore.shared.upsertCaloriesTarget(userId: userId, date: targetDate, target: target)
        try await fetchCaloriesTarget(userId: userId, date: targetDate)
    }
    
    // カロリー目標を削除
    func deleteCaloriesTarget(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        LocalDataStore.shared.deleteCaloriesTarget(userId: userId, date: targetDate)
        
        await MainActor.run {
            caloriesTarget = nil
        }
    }
    
    // 過去のカロリーデータを取得（日付ごとの合計）
    func fetchCaloriesHistory(userId: UUID, days: Int = 30) async throws -> [(date: Date, totalCalories: Double)] {
        LocalDataStore.shared.caloriesHistory(userId: userId, days: days)
    }
}


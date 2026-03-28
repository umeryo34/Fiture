//
//  WeightTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

class WeightTargetManager: ObservableObject {
    @Published var weightEntry: WeightEntry?
    @Published var weightEntries: [WeightEntry] = []
    @Published var selectedDate: Date = Date()
    
    // 指定日付の体重記録を取得
    func fetchWeightEntry(userId: UUID, date: Date = Date()) async throws {
        await MainActor.run {
            weightEntry = LocalDataStore.shared.weightEntry(userId: userId, date: date)
            selectedDate = date
        }
    }
    
    // 体重を作成または更新
    func createOrUpdateWeightEntry(userId: UUID, weight: Double, date: Date = Date()) async throws {
        _ = LocalDataStore.shared.upsertWeightEntry(userId: userId, date: date, weight: weight)
        try await fetchWeightEntry(userId: userId, date: date)
    }
    
    // 体重を更新
    func updateWeightEntry(userId: UUID, weight: Double, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        _ = LocalDataStore.shared.upsertWeightEntry(userId: userId, date: targetDate, weight: weight)
        try await fetchWeightEntry(userId: userId, date: targetDate)
    }
    
    // 体重を削除
    func deleteWeightEntry(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        LocalDataStore.shared.deleteWeightEntry(userId: userId, date: targetDate)
        
        await MainActor.run {
            weightEntry = nil
        }
    }
    
    // 最新の体重を取得（日付指定なし）
    func fetchLatestWeight(userId: UUID) async throws -> WeightEntry? {
        LocalDataStore.shared.latestWeight(userId: userId)
    }
    
    // 期間内の体重記録を取得（グラフ表示用）
    func fetchWeightEntries(userId: UUID, days: Int = 30) async throws {
        await MainActor.run {
            weightEntries = LocalDataStore.shared.weightEntries(userId: userId, days: days)
        }
    }
}


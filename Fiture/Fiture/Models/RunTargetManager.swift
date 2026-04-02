//
//  RunTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/10.
//

import Foundation

class RunTargetManager: ObservableObject {
    @Published var runTarget: RunTarget?
    @Published var selectedDate: Date = Date()
    
    // 指定日付のRun目標を取得
    func fetchRunTarget(userId: UUID, date: Date = Date()) async throws {
        await MainActor.run {
            runTarget = LocalDataStore.shared.runTarget(userId: userId, date: date)
            selectedDate = date
        }
    }
    
    // Run目標を作成または更新
    func createOrUpdateRunTarget(userId: UUID, target: Double, date: Date = Date()) async throws {
        _ = LocalDataStore.shared.upsertRunTarget(userId: userId, date: date, target: target, attempt: nil)
        try await fetchRunTarget(userId: userId, date: date)
    }
    
    // Run目標を更新
    func updateRunTarget(userId: UUID, target: Double? = nil, attempt: Double? = nil, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        _ = LocalDataStore.shared.upsertRunTarget(userId: userId, date: targetDate, target: target, attempt: attempt)
        try await fetchRunTarget(userId: userId, date: targetDate)
    }
    
    // Run目標を削除
    func deleteRunTarget(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        LocalDataStore.shared.deleteRunTarget(userId: userId, date: targetDate)
        
        await MainActor.run {
            runTarget = nil
        }
    }
}


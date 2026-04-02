//
//  TrainingTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

class TrainingTargetManager: ObservableObject {
    @Published var trainingTargets: [TrainingTarget] = []
    @Published var trainingTags: [TrainingTag] = []
    @Published var selectedDate: Date = Date()
    
    // 指定日付の全筋トレ目標を取得
    func fetchTrainingTargets(userId: UUID, date: Date = Date()) async throws {
        await MainActor.run {
            trainingTargets = LocalDataStore.shared.trainingTargets(userId: userId, date: date)
            selectedDate = date
        }
    }
    
    // 特定の種目を取得
    func fetchTrainingTarget(userId: UUID, date: Date, exerciseType: String) async throws -> TrainingTarget? {
        return LocalDataStore.shared.trainingTarget(userId: userId, date: date, exerciseType: exerciseType)
    }
    
    // 筋トレ目標を作成または更新
    func createOrUpdateTrainingTarget(userId: UUID, exerciseType: String, target: Double, date: Date = Date()) async throws {
        _ = LocalDataStore.shared.upsertTrainingTarget(userId: userId, date: date, exerciseType: exerciseType, target: target, attempt: nil)
        try await fetchTrainingTargets(userId: userId, date: date)
    }
    
    // 筋トレ目標を更新
    func updateTrainingTarget(userId: UUID, exerciseType: String, target: Double? = nil, attempt: Double? = nil, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        _ = LocalDataStore.shared.upsertTrainingTarget(userId: userId, date: targetDate, exerciseType: exerciseType, target: target, attempt: attempt)
        try await fetchTrainingTargets(userId: userId, date: targetDate)
    }
    
    // 筋トレ目標を削除
    func deleteTrainingTarget(userId: UUID, exerciseType: String, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        LocalDataStore.shared.deleteTrainingTarget(userId: userId, date: targetDate, exerciseType: exerciseType)
        
        await MainActor.run {
            trainingTargets.removeAll { $0.exerciseType == exerciseType }
        }
    }
    
    // MARK: - 種目タグ
    
    func fetchTrainingTags(userId: UUID) async throws {
        await MainActor.run {
            trainingTags = LocalDataStore.shared.trainingTags(userId: userId)
        }
    }
    
    func createTrainingTag(userId: UUID, tagName: String) async throws {
        let trimmed = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = LocalDataStore.shared.createTrainingTag(userId: userId, tagName: trimmed)
        try await fetchTrainingTags(userId: userId)
    }
    
    func deleteTrainingTag(userId: UUID, tagId: UUID) async throws {
        LocalDataStore.shared.deleteTrainingTag(userId: userId, tagId: tagId)
        
        await MainActor.run {
            trainingTags.removeAll { $0.id == tagId }
        }
    }

    // MARK: - Training Record (セットの重量/回数)

    func fetchTrainingRecord(userId: UUID, date: Date, exerciseType: String) async throws -> TrainingRecord? {
        LocalDataStore.shared.trainingRecord(userId: userId, date: date, exerciseType: exerciseType)
    }

    func fetchTrainingRecords(userId: UUID, exerciseType: String) async throws -> [TrainingRecord] {
        LocalDataStore.shared.trainingRecords(userId: userId, exerciseType: exerciseType)
    }

    func upsertTrainingRecord(
        userId: UUID,
        date: Date,
        exerciseType: String,
        sets: [TrainingSetEntry]
    ) async throws {
        _ = LocalDataStore.shared.upsertTrainingRecord(userId: userId, date: date, exerciseType: exerciseType, sets: sets)
    }
}


//
//  TrainingTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation
import Supabase

class TrainingTargetManager: ObservableObject {
    @Published var trainingTargets: [TrainingTarget] = []
    @Published var selectedDate: Date = Date()
    
    // 指定日付の全筋トレ目標を取得
    func fetchTrainingTargets(userId: UUID, date: Date = Date()) async throws {
        let userIdString = userId.uuidString.lowercased()
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [TrainingTarget] = try await SupabaseManager.shared.client
            .from("targets_training")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .execute()
            .value
        
        await MainActor.run {
            trainingTargets = response
            selectedDate = date
        }
    }
    
    // 特定の種目を取得
    func fetchTrainingTarget(userId: UUID, date: Date, exerciseType: String) async throws -> TrainingTarget? {
        let userIdString = userId.uuidString.lowercased()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [TrainingTarget] = try await SupabaseManager.shared.client
            .from("targets_training")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .eq("exercise_type", value: exerciseType)
            .execute()
            .value
        
        return response.first
    }
    
    // 筋トレ目標を作成または更新
    func createOrUpdateTrainingTarget(userId: UUID, exerciseType: String, target: Double, date: Date = Date()) async throws {
        // まず既存レコードを確認
        let existing = try await fetchTrainingTarget(userId: userId, date: date, exerciseType: exerciseType)
        
        if existing != nil {
            // 既存レコードがあれば更新
            try await updateTrainingTarget(userId: userId, exerciseType: exerciseType, target: target, date: date)
        } else {
            // 新規作成
            struct TrainingTargetInsert: Encodable {
                let userId: String
                let date: String
                let exerciseType: String
                let target: Double
                let attempt: Double
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case date
                    case exerciseType = "exercise_type"
                    case target
                    case attempt
                }
            }
            
            // ローカルタイムゾーンで日付を文字列化
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let data = TrainingTargetInsert(
                userId: userId.uuidString.lowercased(),
                date: dateString,
                exerciseType: exerciseType,
                target: target,
                attempt: 0.0
            )
            
            try await SupabaseManager.shared.client
                .from("targets_training")
                .insert(data)
                .execute()
            
            // 再取得
            try await fetchTrainingTargets(userId: userId, date: date)
        }
    }
    
    // 筋トレ目標を更新
    func updateTrainingTarget(userId: UUID, exerciseType: String, target: Double? = nil, attempt: Double? = nil, date: Date? = nil) async throws {
        struct TrainingTargetUpdate: Encodable {
            let target: Double?
            let attempt: Double?
        }
        
        let data = TrainingTargetUpdate(target: target, attempt: attempt)
        let targetDate = date ?? selectedDate
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_training")
            .update(data)
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .eq("exercise_type", value: exerciseType)
            .execute()
        
        // 再取得
        try await fetchTrainingTargets(userId: userId, date: targetDate)
    }
    
    // 筋トレ目標を削除
    func deleteTrainingTarget(userId: UUID, exerciseType: String, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_training")
            .delete()
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .eq("exercise_type", value: exerciseType)
            .execute()
        
        await MainActor.run {
            trainingTargets.removeAll { $0.exerciseType == exerciseType }
        }
    }
}


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
        let userIdString = userId.uuidString.lowercased()
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current  // ローカルタイムゾーン（日本時間）
        let dateString = dateFormatter.string(from: date)
        
        let response: [RunTarget] = try await SupabaseManager.shared.client
            .from("targets_run")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .execute()
            .value
        
        await MainActor.run {
            runTarget = response.first
            selectedDate = date
        }
    }
    
    // Run目標を作成または更新
    func createOrUpdateRunTarget(userId: UUID, target: Double, date: Date = Date()) async throws {
        // まず既存レコードを確認
        try await fetchRunTarget(userId: userId, date: date)
        
        if runTarget != nil {
            // 既存レコードがあれば更新
            try await updateRunTarget(userId: userId, target: target, date: date)
        } else {
            // 新規作成
            struct RunTargetInsert: Encodable {
                let userId: String
                let date: String
                let target: Double
                let attempt: Double
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case date
                    case target
                    case attempt
                }
            }
            
            // ローカルタイムゾーンで日付を文字列化
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let data = RunTargetInsert(
                userId: userId.uuidString.lowercased(),
                date: dateString,
                target: target,
                attempt: 0.0
            )
            
            try await SupabaseManager.shared.client
                .from("targets_run")
                .insert(data)
                .execute()
            
            // 再取得
            try await fetchRunTarget(userId: userId, date: date)
        }
    }
    
    // Run目標を更新
    func updateRunTarget(userId: UUID, target: Double? = nil, attempt: Double? = nil, date: Date? = nil) async throws {
        // 既存の目標を取得して、attemptが更新される場合はisAchievedも更新
        let targetDate = date ?? selectedDate
        try await fetchRunTarget(userId: userId, date: targetDate)
        
        var newAttempt = attempt ?? runTarget?.attempt ?? 0.0
        var newTarget = target ?? runTarget?.target ?? 0.0
        let isAchieved = newAttempt >= newTarget
        
        struct RunTargetUpdate: Encodable {
            let target: Double?
            let attempt: Double?
            let isAchieved: Bool?
            
            enum CodingKeys: String, CodingKey {
                case target
                case attempt
                case isAchieved = "is_achieved"
            }
        }
        
        let data = RunTargetUpdate(
            target: target,
            attempt: attempt,
            isAchieved: attempt != nil ? isAchieved : nil
        )
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_run")
            .update(data)
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        // 再取得
        try await fetchRunTarget(userId: userId, date: targetDate)
    }
    
    // Run目標を削除
    func deleteRunTarget(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_run")
            .delete()
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        await MainActor.run {
            runTarget = nil
        }
    }
}


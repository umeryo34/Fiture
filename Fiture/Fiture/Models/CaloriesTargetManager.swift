//
//  CaloriesTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation
import Supabase

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
        let userIdString = userId.uuidString.lowercased()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [CaloriesEntry] = try await SupabaseManager.shared.client
            .from("calories_entries")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        await MainActor.run {
            caloriesEntries = response
            selectedDate = date
        }
    }
    
    // 食事を追加
    func addCaloriesEntry(userId: UUID, foodName: String, calories: Double, date: Date = Date()) async throws {
        struct CaloriesEntryInsert: Encodable {
            let userId: String
            let date: String
            let foodName: String
            let calories: Double
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case date
                case foodName = "food_name"
                case calories
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let data = CaloriesEntryInsert(
            userId: userId.uuidString.lowercased(),
            date: dateString,
            foodName: foodName,
            calories: calories
        )
        
        try await SupabaseManager.shared.client
            .from("calories_entries")
            .insert(data)
            .execute()
        
        // 再取得
        try await fetchCaloriesEntries(userId: userId, date: date)
    }
    
    // 食事を削除
    func deleteCaloriesEntry(entryId: Int, userId: UUID, date: Date? = nil) async throws {
        try await SupabaseManager.shared.client
            .from("calories_entries")
            .delete()
            .eq("id", value: entryId)
            .execute()
        
        // 再取得
        let targetDate = date ?? selectedDate
        try await fetchCaloriesEntries(userId: userId, date: targetDate)
    }
    
    // カロリー目標を取得
    func fetchCaloriesTarget(userId: UUID, date: Date = Date()) async throws {
        let userIdString = userId.uuidString.lowercased()
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [CaloriesTarget] = try await SupabaseManager.shared.client
            .from("targets_calories")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .execute()
            .value
        
        await MainActor.run {
            caloriesTarget = response.first
            selectedDate = date
        }
    }
    
    // カロリー目標を作成または更新
    func createOrUpdateCaloriesTarget(userId: UUID, target: Double, date: Date = Date()) async throws {
        // まず既存レコードを確認
        try await fetchCaloriesTarget(userId: userId, date: date)
        
        if caloriesTarget != nil {
            // 既存レコードがあれば更新
            try await updateCaloriesTarget(userId: userId, target: target, date: date)
        } else {
            // 新規作成
            struct CaloriesTargetInsert: Encodable {
                let userId: String
                let date: String
                let target: Double
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case date
                    case target
                }
            }
            
            // ローカルタイムゾーンで日付を文字列化
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let data = CaloriesTargetInsert(
                userId: userId.uuidString.lowercased(),
                date: dateString,
                target: target
            )
            
            try await SupabaseManager.shared.client
                .from("targets_calories")
                .insert(data)
                .execute()
            
            // 再取得
            try await fetchCaloriesTarget(userId: userId, date: date)
        }
    }
    
    // カロリー目標を更新
    func updateCaloriesTarget(userId: UUID, target: Double, date: Date? = nil) async throws {
        struct CaloriesTargetUpdate: Encodable {
            let target: Double
        }
        
        let data = CaloriesTargetUpdate(target: target)
        let targetDate = date ?? selectedDate
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_calories")
            .update(data)
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        // 再取得
        try await fetchCaloriesTarget(userId: userId, date: targetDate)
    }
    
    // カロリー目標を削除
    func deleteCaloriesTarget(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        
        // ローカルタイムゾーンで日付を文字列化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("targets_calories")
            .delete()
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        await MainActor.run {
            caloriesTarget = nil
        }
    }
}


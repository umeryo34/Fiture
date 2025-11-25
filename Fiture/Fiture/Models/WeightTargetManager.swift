//
//  WeightTargetManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation
import Supabase

class WeightTargetManager: ObservableObject {
    @Published var weightEntry: WeightEntry?
    @Published var weightEntries: [WeightEntry] = []
    @Published var selectedDate: Date = Date()
    
    // 指定日付の体重記録を取得
    func fetchWeightEntry(userId: UUID, date: Date = Date()) async throws {
        let userIdString = userId.uuidString.lowercased()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [WeightEntry] = try await SupabaseManager.shared.client
            .from("weight_entries")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .execute()
            .value
        
        await MainActor.run {
            weightEntry = response.first
            selectedDate = date
        }
    }
    
    // 体重を作成または更新
    func createOrUpdateWeightEntry(userId: UUID, weight: Double, date: Date = Date()) async throws {
        // まず既存レコードを確認
        try await fetchWeightEntry(userId: userId, date: date)
        
        if weightEntry != nil {
            // 既存レコードがあれば更新
            try await updateWeightEntry(userId: userId, weight: weight, date: date)
        } else {
            // 新規作成
            struct WeightEntryInsert: Encodable {
                let userId: String
                let date: String
                let weight: Double
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case date
                    case weight
                }
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let data = WeightEntryInsert(
                userId: userId.uuidString.lowercased(),
                date: dateString,
                weight: weight
            )
            
            try await SupabaseManager.shared.client
                .from("weight_entries")
                .insert(data)
                .execute()
            
            // 再取得
            try await fetchWeightEntry(userId: userId, date: date)
        }
    }
    
    // 体重を更新
    func updateWeightEntry(userId: UUID, weight: Double, date: Date? = nil) async throws {
        struct WeightEntryUpdate: Encodable {
            let weight: Double
        }
        
        let data = WeightEntryUpdate(weight: weight)
        let targetDate = date ?? selectedDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("weight_entries")
            .update(data)
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        // 再取得
        try await fetchWeightEntry(userId: userId, date: targetDate)
    }
    
    // 体重を削除
    func deleteWeightEntry(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("weight_entries")
            .delete()
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        await MainActor.run {
            weightEntry = nil
        }
    }
    
    // 最新の体重を取得（日付指定なし）
    func fetchLatestWeight(userId: UUID) async throws -> WeightEntry? {
        let userIdString = userId.uuidString.lowercased()
        
        let response: [WeightEntry] = try await SupabaseManager.shared.client
            .from("weight_entries")
            .select()
            .eq("user_id", value: userIdString)
            .order("date", ascending: false)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    // 期間内の体重記録を取得（グラフ表示用）
    func fetchWeightEntries(userId: UUID, days: Int = 30) async throws {
        let userIdString = userId.uuidString.lowercased()
        
        // 開始日を計算（days日前）
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let startDateString = dateFormatter.string(from: startDate)
        
        let response: [WeightEntry] = try await SupabaseManager.shared.client
            .from("weight_entries")
            .select()
            .eq("user_id", value: userIdString)
            .gte("date", value: startDateString)
            .order("date", ascending: true)
            .execute()
            .value
        
        await MainActor.run {
            weightEntries = response
        }
    }
}


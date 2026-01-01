//
//  WaterEntryManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation
import Supabase

class WaterEntryManager: ObservableObject {
    @Published var waterEntries: [WaterEntry] = []
    @Published var selectedDate: Date = Date()
    
    // 合計水量を計算
    var totalMl: Double {
        waterEntries.reduce(0) { $0 + $1.ml }
    }
    
    // 水の記録を取得
    func fetchWaterEntries(userId: UUID, date: Date = Date()) async throws {
        let userIdString = userId.uuidString.lowercased()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let response: [WaterEntry] = try await SupabaseManager.shared.client
            .from("water_entries")
            .select()
            .eq("user_id", value: userIdString)
            .eq("date", value: dateString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        await MainActor.run {
            waterEntries = response
            selectedDate = date
        }
    }
    
    // 水を作成または更新（UPSERT）
    func createOrUpdateWaterEntry(userId: UUID, ml: Double, date: Date = Date()) async throws {
        struct WaterEntryInsert: Encodable {
            let userId: String
            let date: String
            let ml: Double
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case date
                case ml
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let data = WaterEntryInsert(
            userId: userId.uuidString.lowercased(),
            date: dateString,
            ml: ml
        )
        
        // UPSERT: 既存レコードがあれば更新、なければ作成
        try await SupabaseManager.shared.client
            .from("water_entries")
            .upsert(data, onConflict: "user_id,date")
            .execute()
        
        // 再取得
        try await fetchWaterEntries(userId: userId, date: date)
    }
    
    // 水を削除
    func deleteWaterEntry(userId: UUID, date: Date? = nil) async throws {
        let targetDate = date ?? selectedDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: targetDate)
        
        try await SupabaseManager.shared.client
            .from("water_entries")
            .delete()
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("date", value: dateString)
            .execute()
        
        // 再取得
        try await fetchWaterEntries(userId: userId, date: targetDate)
    }
    
    // 過去の水のデータを取得（日付ごとの合計）
    func fetchWaterHistory(userId: UUID, days: Int = 30) async throws -> [(date: Date, totalMl: Double)] {
        let userIdString = userId.uuidString.lowercased()
        
        // 開始日を計算
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // 指定期間の水の記録を取得
        let response: [WaterEntry] = try await SupabaseManager.shared.client
            .from("water_entries")
            .select()
            .eq("user_id", value: userIdString)
            .gte("date", value: startDateString)
            .lte("date", value: endDateString)
            .order("date", ascending: true)
            .execute()
            .value
        
        // 日付ごとにグループ化して合計を計算
        var dailyTotals: [String: Double] = [:]
        for entry in response {
            let dateString = dateFormatter.string(from: entry.date)
            dailyTotals[dateString, default: 0] += entry.ml
        }
        
        // 日付順にソートして返す
        var result: [(date: Date, totalMl: Double)] = []
        var currentDate = startDate
        while currentDate <= endDate {
            let dateString = dateFormatter.string(from: currentDate)
            let total = dailyTotals[dateString] ?? 0
            result.append((date: currentDate, totalMl: total))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return result
    }
}


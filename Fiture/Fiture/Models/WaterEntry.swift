//
//  WaterEntry.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

struct WaterEntry: Codable, Identifiable {
    let userId: UUID
    let date: Date
    let ml: Double
    let createdAt: Date
    
    // Identifiableプロトコルのために、user_id + date から一意なIDを生成
    var id: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        return "\(userId.uuidString)_\(dateString)"
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case ml
        case createdAt = "created_at"
    }
    
    // 通常のイニシャライザー（Previewやテスト用）
    init(userId: UUID, date: Date, ml: Double, createdAt: Date) {
        self.userId = userId
        self.date = date
        self.ml = ml
        self.createdAt = createdAt
    }
    
    // カスタムデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(UUID.self, forKey: .userId)
        ml = try container.decode(Double.self, forKey: .ml)
        
        // created_at は ISO8601 タイムスタンプ
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let parsedCreatedAt = iso8601Formatter.date(from: createdAtString) {
            createdAt = parsedCreatedAt
        } else {
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let parsedCreatedAt = iso8601Formatter.date(from: createdAtString) {
                createdAt = parsedCreatedAt
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format: \(createdAtString)")
            }
        }
        
        // date は "YYYY-MM-DD" 形式（ローカルタイムゾーンで解釈）
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        if let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }
}


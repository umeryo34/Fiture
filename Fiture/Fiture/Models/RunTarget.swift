//
//  RunTarget.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/10.
//

import Foundation

struct RunTarget: Codable, Identifiable {
    let id: Int
    let userId: UUID
    let date: Date
    var target: Double
    var attempt: Double
    var isAchieved: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case target
        case attempt
        case isAchieved = "is_achieved"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // 通常のイニシャライザー（Previewやテスト用）
    init(id: Int, userId: UUID, date: Date, target: Double, attempt: Double, isAchieved: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.date = date
        self.target = target
        self.attempt = attempt
        self.isAchieved = isAchieved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // カスタムデコーダー（date を "2025-11-10" 形式から Date に変換）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        target = try container.decode(Double.self, forKey: .target)
        attempt = try container.decode(Double.self, forKey: .attempt)
        isAchieved = try container.decode(Bool.self, forKey: .isAchieved)
        
        // created_at と updated_at は ISO8601 タイムスタンプ
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let parsedCreatedAt = iso8601Formatter.date(from: createdAtString) {
            createdAt = parsedCreatedAt
        } else {
            // フォールバック: フラクショナル秒なし
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let parsedCreatedAt = iso8601Formatter.date(from: createdAtString) {
                createdAt = parsedCreatedAt
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format: \(createdAtString)")
            }
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsedUpdatedAt = iso8601Formatter.date(from: updatedAtString) {
            updatedAt = parsedUpdatedAt
        } else {
            // フォールバック: フラクショナル秒なし
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let parsedUpdatedAt = iso8601Formatter.date(from: updatedAtString) {
                updatedAt = parsedUpdatedAt
            } else {
                throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Invalid date format: \(updatedAtString)")
            }
        }
        
        // date は "YYYY-MM-DD" 形式（ローカルタイムゾーンで解釈）
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current  // ローカルタイムゾーン（日本時間）
        
        if let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }
    
    // 進捗率を計算
    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(attempt / target * 100, 100)
    }
}


//
//  TrainingTarget.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

struct TrainingTarget: Codable, Identifiable {
    let userId: UUID
    let date: Date
    let exerciseType: String  // 種目名
    var target: Double
    var attempt: Double
    var isAchieved: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case exerciseType = "exercise_type"
        case target
        case attempt
        case isAchieved = "is_achieved"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Identifiableプロトコルのために、user_id + date + exercise_type から一意なIDを生成
    var id: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        return "\(userId.uuidString)_\(dateString)_\(exerciseType)"
    }
    
    // 通常のイニシャライザー（Previewやテスト用）
    init(userId: UUID, date: Date, exerciseType: String, target: Double, attempt: Double, isAchieved: Bool, createdAt: Date, updatedAt: Date) {
        self.userId = userId
        self.date = date
        self.exerciseType = exerciseType
        self.target = target
        self.attempt = attempt
        self.isAchieved = isAchieved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // カスタムデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(UUID.self, forKey: .userId)
        exerciseType = try container.decode(String.self, forKey: .exerciseType)
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
        dateFormatter.timeZone = TimeZone.current
        
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


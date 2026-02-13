//
//  CaloriesEntry.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

struct CaloriesEntry: Codable, Identifiable {
    let id: Int
    let userId: UUID
    let date: Date
    let foodName: String
    let calories: Double
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case foodName = "food_name"
        case calories
        case protein
        case fat
        case carbs
        case createdAt = "created_at"
    }
    
    // 通常のイニシャライザー（Previewやテスト用）
    init(id: Int, userId: UUID, date: Date, foodName: String, calories: Double, protein: Double? = nil, fat: Double? = nil, carbs: Double? = nil, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.date = date
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.createdAt = createdAt
    }
    
    // カスタムデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        foodName = try container.decode(String.self, forKey: .foodName)
        calories = try container.decode(Double.self, forKey: .calories)
        protein = try container.decodeIfPresent(Double.self, forKey: .protein)
        fat = try container.decodeIfPresent(Double.self, forKey: .fat)
        carbs = try container.decodeIfPresent(Double.self, forKey: .carbs)
        
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


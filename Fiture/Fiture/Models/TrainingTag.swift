//
//  TrainingTag.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import Foundation

struct TrainingTag: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let tagName: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tagName = "tag_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // カスタムデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        tagName = try container.decode(String.self, forKey: .tagName)
        
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
    }
}


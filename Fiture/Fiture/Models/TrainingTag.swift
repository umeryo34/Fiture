//
//  TrainingTag.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/23.
//

import Foundation

struct TrainingTag: Codable, Identifiable, Hashable {
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

    init(id: UUID, userId: UUID, tagName: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.tagName = tagName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        tagName = try container.decode(String.self, forKey: .tagName)
        
        let iso8601Fractional = ISO8601DateFormatter()
        iso8601Fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso8601Plain = ISO8601DateFormatter()
        iso8601Plain.formatOptions = [.withInternetDateTime]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let d = iso8601Fractional.date(from: createdAtString) {
            createdAt = d
        } else if let d = iso8601Plain.date(from: createdAtString) {
            createdAt = d
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date: \(createdAtString)")
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        if let d = iso8601Fractional.date(from: updatedAtString) {
            updatedAt = d
        } else if let d = iso8601Plain.date(from: updatedAtString) {
            updatedAt = d
        } else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Invalid date: \(updatedAtString)")
        }
    }
}

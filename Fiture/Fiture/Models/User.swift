//
//  User.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/23.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
}

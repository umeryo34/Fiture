//
//  SupabaseClient.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/30.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: Config.supabaseURL)!
        let supabaseKey = Config.supabaseAnonKey
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

// ユーザーモデル
struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


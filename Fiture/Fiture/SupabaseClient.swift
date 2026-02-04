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
        // Info.plistからSupabase設定を読み込む
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "supabaseURL") as? String else {
            fatalError("Supabase URL not found in Info.plist. Please check Info.plist file.")
        }
        
        guard let supabaseURL = URL(string: urlString) else {
            fatalError("Invalid Supabase URL format: \(urlString)")
        }
        
        guard let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "supabaseAnonKey") as? String else {
            fatalError("Supabase Anon Key not found in Info.plist. Please check Info.plist file.")
        }
        
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


//
//  AuthManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/30.
//

import Foundation
import Supabase

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            await MainActor.run {
                isAuthenticated = false
                isLoading = false
            }
        }
    }
    
    func fetchCurrentUser() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString.lowercased()
            
            let response: [User] = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let user = response.first {
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                }
            } else {
                await MainActor.run {
                    isAuthenticated = false
                }
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                await MainActor.run {
                    currentUser = nil
                    isAuthenticated = false
                }
            } catch {
                // エラー処理
            }
        }
    }
}


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
                isLoading = true
            }
            
            // セッションをチェック
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                
                // セッションが存在する場合、ユーザー情報を取得
                if session.user.id != nil {
                    await fetchCurrentUser()
                } else {
                    await MainActor.run {
                        isAuthenticated = false
                        isLoading = false
                    }
                }
            } catch {
                // セッションが存在しない、または無効な場合
                await MainActor.run {
                    isAuthenticated = false
                    isLoading = false
                }
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
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    currentUser = nil
                    isAuthenticated = false
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                currentUser = nil
                isAuthenticated = false
                isLoading = false
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


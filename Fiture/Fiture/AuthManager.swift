//
//  AuthManager.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/30.
//

import Foundation

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
            await fetchCurrentUser()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func fetchCurrentUser() async {
        let user = LocalDataStore.shared.currentUser() ?? LocalDataStore.shared.ensureGuestSession()
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    func signOut() {
        LocalDataStore.shared.signOut()
        Task { @MainActor in
            let guest = LocalDataStore.shared.ensureGuestSession()
            currentUser = guest
            isAuthenticated = true
        }
    }
}


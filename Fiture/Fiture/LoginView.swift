//
//  LoginView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/30.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ロゴ・タイトルエリア
                    VStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                        
                        Text("おかえりなさい")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 60)
                    
                    // 入力フォーム
                    VStack(spacing: 20) {
                        // メールアドレス
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TextField("example@email.com", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // パスワード
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            SecureField("パスワード", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.password)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // エラーメッセージ
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                    }
                    
                    // ログインボタン
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("ログイン")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(isFormValid ? Color.red : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    .disabled(!isFormValid || isLoading)
                    
                    // 登録リンク
                    HStack {
                        Text("アカウントをお持ちでないですか？")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("新規登録") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    }
                    .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() {
        isLoading = true
        showError = false
        
        Task {
            do {
                let authResponse = try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                let userId = authResponse.user.id.uuidString.lowercased()
                let response: [User] = try await SupabaseManager.shared.client
                    .from("users")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                if let user = response.first {
                    await MainActor.run {
                        authManager.currentUser = user
                        authManager.isAuthenticated = true
                        isLoading = false
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        showError = true
                        errorMessage = "ユーザー情報が見つかりません"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}


//
//  SignUpView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/30.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showLoginView: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ロゴ・タイトルエリア
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Fiture")
                            .font(.title)
                            .fontWeight(.bold)
                        
                    }
                    .padding(.top, 20)
                    
                    // 入力フォーム
                    VStack(spacing: 15) {
                        // 名前
                        VStack(alignment: .leading, spacing: 8) {
                            Text("名前")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TextField("山田太郎", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.name)
                        }
                        
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
                            
                            SecureField("8文字以上", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        // パスワード確認
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード（確認）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            SecureField("もう一度入力", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
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
                    
                    // 登録ボタン
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("登録する")
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
                    
                    // ログインリンク
                    HStack {
                        Text("すでにアカウントをお持ちですか？")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("ログイン") {
                            showLoginView = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    }
                    .padding(.top, 5)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
                .environmentObject(authManager)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                // Supabaseで認証登録
                let authResponse = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password
                )
                
                // usersテーブルにユーザー情報を保存（認証ユーザーのIDを使用）
                struct UserInsert: Encodable {
                    let id: String
                    let name: String
                    let email: String
                }
                
                let userData = UserInsert(
                    id: authResponse.user.id.uuidString.lowercased(),
                    name: name,
                    email: email
                )
                
                try await SupabaseManager.shared.client
                    .from("users")
                    .insert(userData)
                    .execute()
                
                // 登録直後は手動でユーザー情報を設定（sessionMissingエラー回避）
                let newUser = User(
                    id: authResponse.user.id,
                    name: name,
                    email: email,
                    profileImageUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                await MainActor.run {
                    authManager.currentUser = newUser
                    authManager.isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "登録に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

// カスタムテキストフィールドスタイル
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

#Preview {
    SignUpView()
}


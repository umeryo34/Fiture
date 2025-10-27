//
//  UserView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI

struct UserView: View {
    @State private var userName = "ユーザー"
    @State private var userEmail = "user@example.com"
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.purple)
                        
                        Text(userName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 0) {
                        SettingRow(icon: "person.circle", title: "プロフィール編集", color: .blue) {
                            showingEditProfile = true
                        }
                        
                        SettingRow(icon: "bell.fill", title: "通知設定", color: .orange) {
                        }
                        
                        SettingRow(icon: "lock.fill", title: "プライバシー", color: .green) {
                        }
                        
                        SettingRow(icon: "paintbrush.fill", title: "テーマ", color: .purple) {
                        }
                        
                        SettingRow(icon: "info.circle", title: "アプリ情報", color: .gray) {
                        }
                        
                        SettingRow(icon: "questionmark.circle", title: "ヘルプ", color: .cyan) {
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userName: $userName, userEmail: $userEmail)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .buttonStyle(PlainButtonStyle())
        
        if title != "ヘルプ" {
            Divider()
                .padding(.leading, 65)
        }
    }
}

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Button("写真を変更") {
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("名前")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("名前を入力", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("メールアドレスを入力", text: $userEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserView()
}

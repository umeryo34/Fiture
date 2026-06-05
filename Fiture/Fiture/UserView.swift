//
//  UserView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingFitnessProfile = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    settingsList
                        .frame(minHeight: geometry.size.height, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingFitnessProfile) {
            FitnessProfileGoalSettingView()
                .environmentObject(authManager)
        }
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            SettingRow(icon: "target", title: "目標を変更", color: .red) {
                showingFitnessProfile = true
            }

            SettingRow(icon: "bell.fill", title: "通知設定", color: .orange) {
            }

            SettingRow(icon: "lock.fill", title: "プライバシー", color: .green) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())

        if title != "ヘルプ" {
            Divider()
                .padding(.leading, 65)
        }
    }
}

#Preview {
    UserView()
        .environmentObject(AuthManager.shared)
}

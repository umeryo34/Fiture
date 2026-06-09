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
    @State private var showingNotificationComingSoon = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAppInfo = false
    @State private var showingHelp = false
    @State private var showingHealthSources = false

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
        .sheet(isPresented: $showingNotificationComingSoon) {
            ComingSoonView(title: "通知設定", systemImage: "bell.fill")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAppInfo) {
            AppInfoView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingHealthSources) {
            HealthInformationSourcesView()
        }
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            SettingRow(icon: "target", title: "目標を変更", color: .red) {
                showingFitnessProfile = true
            }

            SettingRow(
                icon: "bell.fill",
                title: "通知設定",
                color: .orange,
                badge: "Coming Soon"
            ) {
                showingNotificationComingSoon = true
            }

            SettingRow(icon: "lock.fill", title: "プライバシー", color: .green) {
                showingPrivacyPolicy = true
            }

            SettingRow(icon: "info.circle", title: "アプリ情報", color: .gray) {
                showingAppInfo = true
            }

            SettingRow(icon: "book.closed", title: "健康情報の出典", color: .blue) {
                showingHealthSources = true
            }

            SettingRow(icon: "questionmark.circle", title: "ヘルプ", color: .cyan) {
                showingHelp = true
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
    var badge: String? = nil
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

                if let badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }

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

//
//  AppInfoView.swift
//  Fiture
//

import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingHealthSources = false

    private let supportEmail = "fiture.support@gmail.com"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.red)

                        Text("Fiture")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Text("食事・体重・運動を記録し、1日のカロリー収支を確認できる健康管理アプリです。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("アプリについて")
                }

                Section {
                    LabeledContent("バージョン", value: appVersion)
                    LabeledContent("ビルド", value: buildNumber)
                    LabeledContent("最終更新", value: "2026年6月")
                }

                Section {
                    Link(destination: URL(string: "mailto:\(supportEmail)")!) {
                        LabeledContent("お問い合わせ", value: supportEmail)
                    }
                } header: {
                    Text("サポート")
                }

                Section {
                    Button {
                        showingHealthSources = true
                    } label: {
                        HStack {
                            Text("健康情報の出典")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        HStack {
                            Text("プライバシーポリシー")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showingTermsOfService = true
                    } label: {
                        HStack {
                            Text("利用規約")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("法的情報")
                }
            }
            .navigationTitle("アプリ情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingHealthSources) {
                HealthInformationSourcesView()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

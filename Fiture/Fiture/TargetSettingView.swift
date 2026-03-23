//
//  TargetSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/21.
//

import SwiftUI

// MARK: - モデル（端末内保存）

enum FitnessGender: String, CaseIterable, Codable {
    case male = "男性"
    case female = "女性"
    case other = "その他"
    case preferNot = "答えたくない"
}

enum FitnessBodyGoal: String, CaseIterable, Codable {
    case lose = "減量"
    case maintain = "現状維持"
    case gain = "増量"
}

enum FitnessActivityLevel: String, CaseIterable, Codable {
    case sedentary = "ほとんど運動しない"
    case light = "軽い運動（週1〜2回）"
    case moderate = "中程度（週3〜4回）"
    case active = "活発（ほぼ毎日）"
}

struct FitnessTargetProfile: Codable, Equatable {
    var ageYears: Int?
    var gender: FitnessGender?
    var bodyGoal: FitnessBodyGoal?
    var activityLevel: FitnessActivityLevel?
}

private enum FitnessProfileStorage {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    private static func storageKey(userId: UUID?) -> String {
        guard let userId else { return "fiture_fitness_profile_guest" }
        return "fiture_fitness_profile_\(userId.uuidString.lowercased())"
    }
    
    static func load(userId: UUID?) -> FitnessTargetProfile {
        let key = storageKey(userId: userId)
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? decoder.decode(FitnessTargetProfile.self, from: data) else {
            return FitnessTargetProfile()
        }
        return profile
    }
    
    static func save(_ profile: FitnessTargetProfile, userId: UUID?) {
        let key = storageKey(userId: userId)
        guard let data = try? encoder.encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - View

struct TargetSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var ageYears: Int = 0
    @State private var gender: FitnessGender?
    @State private var bodyGoal: FitnessBodyGoal?
    @State private var activityLevel: FitnessActivityLevel?
    @State private var didLoad = false
    @State private var viewportHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let contentWidth = min(max(geometry.size.width - 32, 280), 560)
                let sidePadding = max((geometry.size.width - contentWidth) / 2, 16)
                let availableHeight = max(viewportHeight > 0 ? viewportHeight : geometry.size.height, 1)
                let sectionMinHeight = max(88, availableHeight * 0.16)
                let saveButtonMinHeight = max(56, availableHeight * 0.09)
                let verticalSpacing = max(12, availableHeight * 0.02)
                let headerTopSpacing = max(16, availableHeight * 0.05)
                
                ScrollView {
                    VStack(spacing: verticalSpacing) {
                        VStack(alignment: .leading, spacing: verticalSpacing) {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("年齢")
                                Menu {
                                    Button("未設定") { ageYears = 0 }
                                    ForEach(1...100, id: \.self) { y in
                                        Button("\(y)歳") { ageYears = y }
                                    }
                                } label: {
                                    selectionMenuLabel(ageYears == 0 ? "選択してください" : "\(ageYears)歳")
                                }
                            }
                            .frame(minHeight: sectionMinHeight, alignment: .topLeading)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("性別")
                                Menu {
                                    Button("未設定") { gender = nil }
                                    ForEach(FitnessGender.allCases, id: \.self) { g in
                                        Button(g.rawValue) { gender = g }
                                    }
                                } label: {
                                    selectionMenuLabel(gender?.rawValue ?? "選択してください")
                                }
                            }
                            .frame(minHeight: sectionMinHeight, alignment: .topLeading)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("目標")
                                Menu {
                                    Button("未設定") { bodyGoal = nil }
                                    ForEach(FitnessBodyGoal.allCases, id: \.self) { goal in
                                        Button(goal.rawValue) { bodyGoal = goal }
                                    }
                                } label: {
                                    selectionMenuLabel(bodyGoal?.rawValue ?? "選択してください")
                                }
                            }
                            .frame(minHeight: sectionMinHeight, alignment: .topLeading)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("現在の運動状況")
                                Menu {
                                    Button("未設定") { activityLevel = nil }
                                    ForEach(FitnessActivityLevel.allCases, id: \.self) { level in
                                        Button(level.rawValue) { activityLevel = level }
                                    }
                                } label: {
                                    selectionMenuLabel(activityLevel?.rawValue ?? "選択してください")
                                }
                            }
                            .frame(minHeight: sectionMinHeight, alignment: .topLeading)
                        }
                        .padding(.top, headerTopSpacing)
                        .padding(.horizontal, sidePadding)
                        
                        Button {
                            saveProfile()
                            dismiss()
                        } label: {
                            Text("保存")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .frame(minHeight: saveButtonMinHeight)
                        .padding(.horizontal, sidePadding)
                        .padding(.bottom, 36)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollViewportHeightPreferenceKey.self,
                            value: proxy.size.height
                        )
                    }
                )
                .onPreferenceChange(ScrollViewportHeightPreferenceKey.self) { newHeight in
                    viewportHeight = newHeight
                }
                .navigationTitle("目標・プロフィール")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    guard !didLoad else { return }
                    didLoad = true
                    let p = FitnessProfileStorage.load(userId: authManager.currentUser?.id)
                    ageYears = p.ageYears ?? 0
                    gender = p.gender
                    bodyGoal = p.bodyGoal
                    activityLevel = p.activityLevel
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private func selectionMenuLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Spacer(minLength: 8)
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }
    
    private func saveProfile() {
        let profile = FitnessTargetProfile(
            ageYears: ageYears == 0 ? nil : ageYears,
            gender: gender,
            bodyGoal: bodyGoal,
            activityLevel: activityLevel
        )
        FitnessProfileStorage.save(profile, userId: authManager.currentUser?.id)
    }
}

private struct ScrollViewportHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    TargetSettingView()
        .environmentObject(AuthManager.shared)
}

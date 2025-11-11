//
//  SettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/23.
//

import SwiftUI

// 目標データモデル
struct Goal: Identifiable, Codable {
    let id = UUID()
    let type: GoalType
    let value: Double
    let unit: String
    let dateCreated: Date
    var currentProgress: Double = 0.0
    
    init(type: GoalType, value: Double, unit: String) {
        self.type = type
        self.value = value
        self.unit = unit
        self.dateCreated = Date()
        self.currentProgress = 0.0
    }
    
    var progressPercentage: Double {
        guard value > 0 else { return 0 }
        return min(currentProgress / value * 100, 100)
    }
}

// 目標データを管理するクラス
class GoalManager: ObservableObject {
    @Published var goals: [Goal] = []
    
    func addGoal(_ goal: Goal) {
        // 同じタイプの目標がある場合は更新
        if let index = goals.firstIndex(where: { $0.type == goal.type }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
    }
    
    func getGoal(for type: GoalType) -> Goal? {
        return goals.first { $0.type == type }
    }
    
    func updateProgress(for type: GoalType, progress: Double) {
        if let index = goals.firstIndex(where: { $0.type == type }) {
            goals[index].currentProgress = progress
        }
    }
}

struct SettingView: View {
    @EnvironmentObject var goalManager: GoalManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var runTargetManager = RunTargetManager()
    @State private var showingGoalSetting = false
    @State private var showingRunSetting = false
    @State private var selectedItem: SettingItem?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let settingItems = [
        SettingItem(imageName: "run", text: "run", color: .blue, type: .run),
        SettingItem(imageName: "training", text: "training", color: .red, type: .training),
        SettingItem(imageName: "calories", text: "calories", color: .green, type: .calories),
        SettingItem(imageName: "weight", text: "weight", color: .purple, type: .weight),
        SettingItem(imageName: "water", text: "water", color: .cyan, type: .water),
        SettingItem(imageName: "others", text: "others", color: .orange, type: .others)
    ]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(settingItems) { item in
                    SettingCard(item: item) {
                        selectedItem = item
                        if item.type == .run {
                            showingRunSetting = true
                        } else {
                            showingGoalSetting = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .sheet(isPresented: $showingGoalSetting) {
            if let item = selectedItem {
                GoalSettingView(item: item, goalManager: goalManager)
            }
        }
        .sheet(isPresented: $showingRunSetting) {
            RunSettingView()
                .environmentObject(authManager)
                .environmentObject(runTargetManager)
        }
        .task {
            if let userId = authManager.currentUser?.id {
                try? await runTargetManager.fetchRunTarget(userId: userId)
            }
        }
    }
}

enum GoalType: String, CaseIterable, Codable {
    case run = "run"
    case training = "training"
    case calories = "calories"
    case weight = "weight"
    case water = "water"
    case others = "others"
}

struct SettingItem: Identifiable {
    let id = UUID()
    let imageName: String
    let text: String
    let color: Color
    let type: GoalType
}

struct SettingCard: View {
    let item: SettingItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景画像
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                
                // 半透明のオーバーレイ
                RoundedRectangle(cornerRadius: 15)
                    .fill(item.color.opacity(0.6))
                
                // 中央のテキスト
                Text(item.text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// 目標設定画面
struct GoalSettingView: View {
    let item: SettingItem
    let goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    @State private var goalValue: String = ""
    @State private var selectedUnit: String = ""
    
    private var units: [String] {
        switch item.type {
        case .run:
            return ["km", "分", "回"]
        case .training:
            return ["分", "回", "セット"]
        case .calories:
            return ["kcal", "g"]
        case .weight:
            return ["kg", "g"]
        case .water:
            return ["ml", "L", "杯"]
        case .others:
            return ["回", "分", "個"]
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text(item.text.capitalized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(item.color)
                }
                .padding(.top, 20)
                
                // 目標設定フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("目標数値")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $goalValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("単位")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("単位", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 保存ボタン
                Button(action: {
                    // 目標を保存
                    saveGoal()
                    dismiss()
                }) {
                    Text("目標を設定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(item.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(goalValue.isEmpty || selectedUnit.isEmpty)
            }
            .navigationTitle("目標設定")
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
        .onAppear {
            if selectedUnit.isEmpty && !units.isEmpty {
                selectedUnit = units[0]
            }
        }
    }
    
    private func saveGoal() {
        guard let value = Double(goalValue) else { return }
        let goal = Goal(type: item.type, value: value, unit: selectedUnit)
        goalManager.addGoal(goal)
        print("\(item.text): \(goalValue) \(selectedUnit)")
    }
}

#Preview {
    SettingView()
}

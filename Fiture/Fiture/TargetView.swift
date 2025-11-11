//
//  TargetTabView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/17.
//

import SwiftUI

struct TargetView: View {
    @EnvironmentObject var goalManager: GoalManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Training")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 30)
            
            // カスタムタブバー
            HStack(spacing: 0) {
                TabButton(
                    icon: "long.text.page.and.pencil",
                    title: "登録",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "進捗",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabButton(
                    icon: "medal",
                    title: "達成済み",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // コンテンツエリア
            TabView(selection: $selectedTab) {
                SettingView()
                    .environmentObject(goalManager)
                    .environmentObject(authManager)
                    .tag(0)
                
                GoalProgressView()
                    .environmentObject(goalManager)
                    .environmentObject(authManager)
                    .tag(1)
                
                GoalAchievementView()
                    .environmentObject(goalManager)
                    .environmentObject(authManager)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// カスタムタブボタン
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
}

// 進捗表示画面
struct GoalProgressView: View {
    @EnvironmentObject var goalManager: GoalManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var runTargetManager = RunTargetManager()
    @StateObject private var trainingTargetManager = TrainingTargetManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトル
            Text("進捗")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            // 日付選択バー
            DateSelectorBar(selectedDate: $runTargetManager.selectedDate) { newDate in
                if let userId = authManager.currentUser?.id {
                    Task {
                        try? await runTargetManager.fetchRunTarget(userId: userId, date: newDate)
                        try? await trainingTargetManager.fetchTrainingTargets(userId: userId, date: newDate)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            if runTargetManager.runTarget == nil && trainingTargetManager.trainingTargets.isEmpty && goalManager.goals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("目標が設定されていません")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("「登録」タブで目標を設定してください")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        // Run目標（Supabase）
                        if let runTarget = runTargetManager.runTarget {
                            RunProgressCard(runTarget: runTarget, runTargetManager: runTargetManager, userId: authManager.currentUser?.id ?? UUID())
                        }
                        
                        // 筋トレ目標（Supabase）
                        ForEach(trainingTargetManager.trainingTargets) { trainingTarget in
                            TrainingProgressCard(trainingTarget: trainingTarget, trainingTargetManager: trainingTargetManager, userId: authManager.currentUser?.id ?? UUID())
                        }
                        
                        // その他の目標（ローカル）
                        ForEach(goalManager.goals) { goal in
                            GoalProgressCard(goal: goal)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .task {
            if let userId = authManager.currentUser?.id {
                try? await runTargetManager.fetchRunTarget(userId: userId)
                try? await trainingTargetManager.fetchTrainingTargets(userId: userId)
            }
        }
    }
}

// Run進捗カード（Supabase連携）
struct RunProgressCard: View {
    let runTarget: RunTarget
    let runTargetManager: RunTargetManager
    let userId: UUID
    @State private var showingProgressInput = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // アイコン
                Image("run")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 目標情報
                VStack(alignment: .leading, spacing: 5) {
                    Text("Run")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("目標: \(String(format: "%.1f", runTarget.target)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("現在: \(String(format: "%.1f", runTarget.attempt)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 進捗表示
                VStack {
                    Text("\(String(format: "%.0f", runTarget.progressPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (runTarget.progressPercentage / 100.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // 進捗更新ボタン
            Button(action: {
                showingProgressInput = true
            }) {
                Text("進捗を更新")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingProgressInput) {
            RunProgressInputView(runTarget: runTarget, runTargetManager: runTargetManager, userId: userId)
        }
    }
}

// 筋トレ進捗カード（Supabase連携）
struct TrainingProgressCard: View {
    let trainingTarget: TrainingTarget
    let trainingTargetManager: TrainingTargetManager
    let userId: UUID
    @State private var showingProgressInput = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // アイコン
                Image("training")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 目標情報
                VStack(alignment: .leading, spacing: 5) {
                    Text(trainingTarget.exerciseType)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("目標: \(String(format: "%.0f", trainingTarget.target)) セット")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("現在: \(String(format: "%.0f", trainingTarget.attempt)) セット")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 進捗表示
                VStack {
                    Text("\(String(format: "%.0f", trainingTarget.progressPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * (trainingTarget.progressPercentage / 100.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // 進捗更新ボタン
            Button(action: {
                showingProgressInput = true
            }) {
                Text("進捗を更新")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingProgressInput) {
            TrainingProgressInputView(trainingTarget: trainingTarget, trainingTargetManager: trainingTargetManager, userId: userId)
        }
    }
}

// 目標進捗カード
struct GoalProgressCard: View {
    let goal: Goal
    @EnvironmentObject var goalManager: GoalManager
    @State private var showingProgressInput = false
    @State private var progressInput: String = ""
    
    private var goalTypeInfo: (imageName: String, text: String, color: Color) {
        switch goal.type {
        case .run:
            return ("run", "run", .blue)
        case .training:
            return ("training", "training", .red)
        case .calories:
            return ("calories", "calories", .green)
        case .weight:
            return ("weight", "weight", .purple)
        case .water:
            return ("water", "water", .cyan)
        case .others:
            return ("others", "others", .orange)
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // アイコン
                Image(goalTypeInfo.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 目標情報
                VStack(alignment: .leading, spacing: 5) {
                    Text(goalTypeInfo.text.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("目標: \(String(format: "%.1f", goal.value)) \(goal.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("現在: \(String(format: "%.1f", goal.currentProgress)) \(goal.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 進捗表示
                VStack {
                    Text("\(String(format: "%.0f", goal.progressPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(goalTypeInfo.color)
                    
                    Text("進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(goalTypeInfo.color)
                        .frame(width: geometry.size.width * (goal.progressPercentage / 100.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // 進捗更新ボタン
            Button(action: {
                progressInput = String(format: "%.1f", goal.currentProgress)
                showingProgressInput = true
            }) {
                Text("進捗を更新")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(goalTypeInfo.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingProgressInput) {
            ProgressInputView(goal: goal, goalManager: goalManager)
        }
    }
}

// 達成済み画面
struct GoalAchievementView: View {
    @EnvironmentObject var goalManager: GoalManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var runTargetManager = RunTargetManager()
    @StateObject private var trainingTargetManager = TrainingTargetManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトル
            Text("達成済み")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            // 日付選択バー
            DateSelectorBar(selectedDate: $runTargetManager.selectedDate) { newDate in
                if let userId = authManager.currentUser?.id {
                    Task {
                        try? await runTargetManager.fetchRunTarget(userId: userId, date: newDate)
                        try? await trainingTargetManager.fetchTrainingTargets(userId: userId, date: newDate)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            let hasAchieved = (runTargetManager.runTarget?.isAchieved ?? false) || trainingTargetManager.trainingTargets.contains(where: { $0.isAchieved })
            
            if hasAchieved {
                // 達成済みの目標を表示
                ScrollView {
                    VStack(spacing: 15) {
                        // Run目標
                        if let runTarget = runTargetManager.runTarget, runTarget.isAchieved {
                            AchievedRunCard(runTarget: runTarget)
                        }
                        
                        // 筋トレ目標
                        ForEach(trainingTargetManager.trainingTargets.filter { $0.isAchieved }) { trainingTarget in
                            AchievedTrainingCard(trainingTarget: trainingTarget)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "trophy")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("この日の目標は未達成です")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("日付を変更して他の日を確認できます")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            Spacer()
        }
        .task {
            if let userId = authManager.currentUser?.id {
                try? await runTargetManager.fetchRunTarget(userId: userId)
                try? await trainingTargetManager.fetchTrainingTargets(userId: userId)
            }
        }
    }
}

// 達成済みRunカード
struct AchievedRunCard: View {
    let runTarget: RunTarget
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // アイコン
                Image("run")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 達成情報
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Run")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    
                    Text("目標: \(String(format: "%.1f", runTarget.target)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("達成: \(String(format: "%.1f", runTarget.attempt)) km")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // トロフィー
                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow, lineWidth: 2)
        )
    }
}

// 達成済み筋トレカード
struct AchievedTrainingCard: View {
    let trainingTarget: TrainingTarget
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // アイコン
                Image("training")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 達成情報
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(trainingTarget.exerciseType)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    
                    Text("目標: \(String(format: "%.0f", trainingTarget.target)) セット")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("達成: \(String(format: "%.0f", trainingTarget.attempt)) セット")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // トロフィー
                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow, lineWidth: 2)
        )
    }
}

// 進捗入力画面
struct ProgressInputView: View {
    let goal: Goal
    let goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    @State private var progressValue: String = ""
    
    private var goalTypeInfo: (imageName: String, text: String, color: Color) {
        switch goal.type {
        case .run:
            return ("run", "run", .blue)
        case .training:
            return ("training", "training", .red)
        case .calories:
            return ("calories", "calories", .green)
        case .weight:
            return ("weight", "weight", .purple)
        case .water:
            return ("water", "water", .cyan)
        case .others:
            return ("others", "others", .orange)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image(goalTypeInfo.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text(goalTypeInfo.text.capitalized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(goalTypeInfo.color)
                }
                .padding(.top, 20)
                
                // 現在の進捗表示
                VStack(spacing: 10) {
                    Text("現在の進捗")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", goal.currentProgress)) / \(String(format: "%.1f", goal.value)) \(goal.unit)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(goalTypeInfo.color)
                    
                    Text("\(String(format: "%.0f", goal.progressPercentage))% 達成")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 進捗入力フォーム
                VStack(alignment: .leading, spacing: 8) {
                    Text("新しい進捗値")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("数値を入力", text: $progressValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    Text("単位: \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 更新ボタン
                Button(action: {
                    updateProgress()
                    dismiss()
                }) {
                    Text("進捗を更新")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(goalTypeInfo.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(progressValue.isEmpty)
            }
            .navigationTitle("進捗更新")
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
            progressValue = String(format: "%.1f", goal.currentProgress)
        }
    }
    
    private func updateProgress() {
        guard let value = Double(progressValue) else { return }
        goalManager.updateProgress(for: goal.type, progress: value)
    }
}

#Preview {
    TargetView()
}

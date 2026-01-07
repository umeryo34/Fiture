//
//  HomeView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var caloriesTargetManager = CaloriesTargetManager()
    @State private var showingTargetSetting = false
    @State private var showingCaloriesInput = false
    @State private var showingDatePicker = false
    @State private var showingSearch = false
    @State private var selectedDate: Date = Date()
    
    private var userName: String {
        authManager.currentUser?.name ?? "ユーザー"
    }
    
    // 目標カロリー値
    private var targetCalories: Double? {
        caloriesTargetManager.caloriesTarget?.target
    }
    
    // 合計カロリーの色を決定（目標超過時は赤色）
    private var totalCaloriesColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        return caloriesTargetManager.totalCalories > target ? .red : .green
    }
    
    // 合計カロリーの背景色を決定
    private var totalCaloriesBackgroundColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.1)
        }
        return caloriesTargetManager.totalCalories > target ? Color.red.opacity(0.1) : Color.green.opacity(0.1)
    }
    
    // 合計カロリーのボーダー色を決定
    private var totalCaloriesBorderColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.3)
        }
        return caloriesTargetManager.totalCalories > target ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    showingDatePicker = true
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                    Text("こんにちは \(userName)さん")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                
                Button(action: {
                    showingSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        .padding(.trailing, 15)
                }
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Spacer()
                .frame(height: 20)
            
            // カロリー情報と進捗バー
            if let target = targetCalories, target > 0 {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) / \(String(format: "%.0f", target)) kcal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // 進捗バー
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(progressColor)
                                    .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(min(caloriesTargetManager.totalCalories / target, 1.0))), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // ボタン群
                    HStack(spacing: 12) {
                        // 食事追加ボタン
                        Button(action: {
                            showingCaloriesInput = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text("食事を追加")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 目標設定ボタン
                        Button(action: {
                            showingTargetSetting = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                Text("目標を変更")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.bottom, 10)
            } else {
                // 目標が設定されていない場合
                VStack(spacing: 16) {
                    Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) kcal")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        // 食事追加ボタン
                        Button(action: {
                            showingCaloriesInput = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("食事を追加")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // カロリー目標設定ボタン
                        Button(action: {
                            showingTargetSetting = true
                        }) {
                            HStack {
                                Image(systemName: "target")
                                    .font(.system(size: 16))
                                Text("カロリー目標を設定")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 10)
            }
            
            Spacer()

            // 今日の食事（下部）
            VStack(alignment: .leading, spacing: 12) {
                Text("今日の食事")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                if caloriesTargetManager.caloriesEntries.isEmpty {
                    // 食事がない場合（中央配置）
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 4) {
                            Text("まだ食事を記録していません")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("カロリー目標を設定して記録しよう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    // 食事リスト
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(caloriesTargetManager.caloriesEntries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.foodName)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Text(formatTime(entry.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.0f", entry.calories)) kcal")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 合計カロリー
                    HStack {
                        Text("合計")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", caloriesTargetManager.totalCalories)) kcal")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(totalCaloriesColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(totalCaloriesBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(totalCaloriesBorderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .sheet(isPresented: $showingTargetSetting) {
            CaloriesTargetSettingView(
                caloriesTargetManager: caloriesTargetManager,
                initialTarget: targetCalories
            )
            .environmentObject(authManager)
        }
        .sheet(isPresented: $showingCaloriesInput) {
            if let userId = authManager.currentUser?.id {
                CaloriesProgressInputView(
                    caloriesTargetManager: caloriesTargetManager,
                    userId: userId,
                    date: selectedDate
                )
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate) { newDate in
                selectedDate = newDate
                Task {
                    await fetchCaloriesDataForDate(newDate)
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            CaloriesSearchView()
                .environmentObject(authManager)
                .environmentObject(caloriesTargetManager)
        }
        .task {
            // 初回表示時にデータを取得
            selectedDate = Date()
            await fetchCaloriesData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
            // カロリーデータが更新された時に再取得（選択された日付のデータ）
            print("HomeView: カロリーデータ更新通知を受信")
            Task {
                await fetchCaloriesDataForDate(selectedDate)
            }
        }
    }
    
    // 時間をフォーマットする関数
    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    // 選択された日付をフォーマットする関数
    private func formatSelectedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M月d日 (E)"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    // 進捗バーの色を決定（滑らかに変化）
    private var progressColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        
        let percentage = (caloriesTargetManager.totalCalories / target) * 100
        
        // 100%以上は赤固定
        if percentage >= 100 {
            return .red
        }
        
        // 0〜80%：緑 → 黄（滑らかに）
        if percentage <= 80 {
            let progress = percentage / 80.0 // 0.0 〜 1.0
            // 緑(0, 255, 0) → 黄(255, 255, 0)
            let red = progress * 255
            let green: Double = 255
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        }
        
        // 80〜100%：黄 → オレンジ → 赤（滑らかに）
        // 80% = 黄(255, 255, 0)
        // 90% = オレンジ(255, 165, 0)
        // 100% = 赤(255, 0, 0)
        let progress = (percentage - 80) / 20.0 // 0.0 〜 1.0
        
        if progress <= 0.5 {
            // 80〜90%：黄 → オレンジ
            let localProgress = progress * 2.0 // 0.0 〜 1.0
            let red: Double = 255
            let green = 255 - (255 - 165) * localProgress // 255 → 165
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        } else {
            // 90〜100%：オレンジ → 赤
            let localProgress = (progress - 0.5) * 2.0 // 0.0 〜 1.0
            let red: Double = 255
            let green = 165 - 165 * localProgress // 165 → 0
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        }
    }
    
    // カロリーデータを取得する関数
    private func fetchCaloriesData() async {
        await fetchCaloriesDataForDate(selectedDate)
    }
    
    // 指定日付のカロリーデータを取得する関数
    private func fetchCaloriesDataForDate(_ date: Date) async {
        if let userId = authManager.currentUser?.id {
            async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId, date: date)
            async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId, date: date)
            try? await fetchEntries
            try? await fetchTarget
            print("HomeView: カロリーデータ再取得完了 - totalCalories: \(caloriesTargetManager.totalCalories), target: \(caloriesTargetManager.caloriesTarget?.target ?? 0), date: \(date)")
        }
    }
}

// カロリー目標設定ビュー
struct CaloriesTargetSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var caloriesTargetManager: CaloriesTargetManager
    let initialTarget: Double?
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetValue: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("calories")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("カロリー目標設定")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
                
                // 目標設定フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1日の目標カロリー (kcal)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("カロリーを入力", text: $targetValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                .padding(.horizontal, 20)
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 保存ボタン
                Button(action: saveCaloriesTarget) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text(caloriesTargetManager.caloriesTarget == nil ? "目標を作成" : "目標を更新")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Color.green : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let initial = initialTarget {
                targetValue = String(format: "%.0f", initial)
            }
        }
    }
    
    private var isFormValid: Bool {
        !targetValue.isEmpty && Double(targetValue) != nil
    }
    
    private func saveCaloriesTarget() {
        guard let target = Double(targetValue),
              let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                let currentDate = caloriesTargetManager.selectedDate
                
                // UPSERT: 既存レコードがあれば更新、なければ作成
                try await caloriesTargetManager.createOrUpdateCaloriesTarget(userId: userId, target: target, date: currentDate)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}



#Preview {
    HomeView()
}

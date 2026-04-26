//
//  FoodView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/27.
//

import SwiftUI
import Combine

struct FoodView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        FoodViewContent(viewModel: viewModel)
            .environmentObject(authManager)
            .onAppear {
                viewModel.setAuthManager(authManager)
            }
    }
}

private struct FoodViewContent: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                NavigationLink {
                    CalendarView(selectedDate: $viewModel.selectedDate) { newDate in
                        viewModel.selectedDate = newDate
                        Task {
                            await viewModel.fetchCaloriesDataForDate(newDate)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                        Text("カレンダーに移動")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            Spacer()
                .frame(height: 20)
            
            // カロリー情報と進捗バー
            if let target = viewModel.targetCalories, target > 0 {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("\(String(format: "%.0f", viewModel.totalCalories)) / \(String(format: "%.0f", target)) kcal")
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
                                    .fill(viewModel.progressColor)
                                    .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(min(viewModel.totalCalories / target, 1.0))), height: 8)
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
                            viewModel.showingCaloriesInput = true
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
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 詳細ボタン
                        NavigationLink {
                            FoodDayDetailView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 14))
                                Text("詳細")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 10)
            } else {
                // 目標が設定されていない場合
                VStack(spacing: 16) {
                    Text("\(String(format: "%.0f", viewModel.totalCalories)) kcal")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        // 食事追加ボタン
                        Button(action: {
                            viewModel.showingCaloriesInput = true
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
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // 詳細ボタン
                        NavigationLink {
                            FoodDayDetailView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 16))
                                Text("詳細")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 10)
            }

            CalorieBalanceCard(viewModel: viewModel)
                .padding(.top, 12)

            Spacer()
            }
        }
        .sheet(isPresented: $viewModel.showingCaloriesInput) {
            if let userId = authManager.currentUser?.id {
                CaloriesProgressInputView(
                    caloriesTargetManager: viewModel.getCaloriesTargetManager(),
                    userId: userId,
                    date: viewModel.selectedDate
                )
            }
        }
        .sheet(isPresented: $viewModel.showingSearch) {
            CaloriesSearchView()
                .environmentObject(authManager)
                .environmentObject(viewModel.getCaloriesTargetManager())
        }
        .task {
            // 初回表示時にデータを取得
            viewModel.selectedDate = Date()
            await viewModel.fetchCaloriesData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
            // カロリーデータが更新された時に再取得（選択された日付のデータ）
            Task {
                await viewModel.fetchCaloriesDataForDate(viewModel.selectedDate)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RunRecordDidSave"))) { _ in
            Task {
                await viewModel.fetchCaloriesDataForDate(viewModel.selectedDate)
            }
        }
    }
}

/// 食事メニュー表と食事合計（メイン画面から遷移）
private struct FoodDayDetailView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.caloriesEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        VStack(spacing: 4) {
                            Text("まだ食事を記録していません")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("「食事を追加」から記録できます")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.caloriesEntries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.foodName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(viewModel.formatTime(entry.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(String(format: "%.0f", entry.calories)) kcal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }

                HStack {
                    Text("食事の合計")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(String(format: "%.0f", viewModel.totalCalories)) kcal")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.totalCaloriesColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.totalCaloriesBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.totalCaloriesBorderColor, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(detailDateTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailDateTitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "M月d日(E)"
        return df.string(from: viewModel.selectedDate)
    }
}

/// 食事摂取と Run 消費カロリーの差・目標との関係
private struct CalorieBalanceCard: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カロリー収支")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            balanceRow(title: "食事の摂取", kcal: viewModel.totalCalories, accent: .primary)
            balanceRow(title: "運動の消費（Run）", kcal: viewModel.runBurnedCaloriesKcal, accent: .orange)

            Divider()

            balanceRow(title: "ネット（摂取 − 運動）", kcal: viewModel.netCaloriesAfterRun, accent: .blue)

            if let target = viewModel.targetCalories, target > 0 {
                let margin = target - viewModel.netCaloriesAfterRun
                HStack(alignment: .firstTextBaseline) {
                    Text(margin >= 0 ? "1日の目標までの余白" : "1日の目標の超過")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.0f", abs(margin))) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(margin >= 0 ? .green : .red)
                }
            }

            Text("運動の消費は、プロフィールに体重があり Run 保存時に kcal が入っている記録だけを合算しています。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }

    private func balanceRow(title: String, kcal: Double, accent: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(String(format: "%.0f", kcal)) kcal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(accent)
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
    FoodView()
}

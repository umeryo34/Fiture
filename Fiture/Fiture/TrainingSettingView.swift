//
//  TrainingSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct TrainingSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingTargetManager: TrainingTargetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var exerciseType: String = ""
    @State private var targetValue: String = ""
    @State private var selectedUnit: String = "セット"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showingTagManagement: Bool = false
    @State private var saveAsTag: Bool = false
    
    private let units = ["セット", "kg", "分"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("training")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("筋トレ目標設定")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                
                // 目標設定フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("種目名")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                showingTagManagement = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.caption)
                                    Text("タグ管理")
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        // タグ選択セクション
                        if !trainingTargetManager.trainingTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(trainingTargetManager.trainingTags) { tag in
                                        Button(action: {
                                            exerciseType = tag.tagName
                                        }) {
                                            Text(tag.tagName)
                                                .font(.subheadline)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(exerciseType == tag.tagName ? Color.red.opacity(0.2) : Color(.systemGray5))
                                                .foregroundColor(exerciseType == tag.tagName ? .red : .primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        TextField("例: ベンチプレス", text: $exerciseType)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("目標数値")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $targetValue)
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
                    
                    // タグとして保存するオプション
                    Toggle(isOn: $saveAsTag) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.red)
                            Text("この種目をタグとして保存")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // 保存ボタン
                Button(action: {
                    saveTrainingTarget()
                }) {
                    Text("目標を作成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.red : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("筋トレ目標")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTagManagement) {
                TrainingTagManagementView()
                    .environmentObject(authManager)
                    .environmentObject(trainingTargetManager)
            }
            .task {
                if let userId = authManager.currentUser?.id {
                    try? await trainingTargetManager.fetchTrainingTags(userId: userId)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !exerciseType.isEmpty && !targetValue.isEmpty
    }
    
    private func saveTrainingTarget() {
        guard let target = Double(targetValue),
              let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                let currentDate = trainingTargetManager.selectedDate
                
                // 新規作成
                try await trainingTargetManager.createOrUpdateTrainingTarget(
                    userId: userId,
                    exerciseType: exerciseType,
                    target: target,
                    date: currentDate
                )
                
                // タグとして保存する場合
                if saveAsTag {
                    // 既に同じ名前のタグが存在するかチェック
                    let existingTag = trainingTargetManager.trainingTags.first { $0.tagName == exerciseType }
                    if existingTag == nil {
                        try await trainingTargetManager.createTrainingTag(userId: userId, tagName: exerciseType)
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "目標の保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}


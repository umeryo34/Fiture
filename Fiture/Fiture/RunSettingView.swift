//
//  RunSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/10.
//

import SwiftUI

struct RunSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var runTargetManager: RunTargetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetValue: String = ""
    @State private var selectedUnit: String = "km"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    private let units = ["km", "分", "回"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("run")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("Run")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                // 現在の目標表示
                if let runTarget = runTargetManager.runTarget {
                    VStack(spacing: 10) {
                        Text("現在の目標")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.1f", runTarget.attempt)) / \(String(format: "%.1f", runTarget.target)) \(selectedUnit)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("\(String(format: "%.0f", runTarget.progressPercentage))% 達成")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
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
                    }
                    .padding(.horizontal, 20)
                }
                
                // 目標設定フォーム
                VStack(spacing: 20) {
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
                Button(action: saveRunTarget) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text(runTargetManager.runTarget == nil ? "目標を作成" : "目標を更新")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("Run目標設定")
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
            // 既存の目標があれば値をセット
            if let runTarget = runTargetManager.runTarget {
                targetValue = String(format: "%.1f", runTarget.target)
            }
        }
    }
    
    private var isFormValid: Bool {
        !targetValue.isEmpty
    }
    
    private func saveRunTarget() {
        guard let target = Double(targetValue),
              let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                let currentDate = runTargetManager.selectedDate
                
                // UPSERT: 既存レコードがあれば更新、なければ作成
                try await runTargetManager.createOrUpdateRunTarget(userId: userId, target: target, date: currentDate)
                
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
    RunSettingView()
        .environmentObject(AuthManager.shared)
        .environmentObject(RunTargetManager())
}


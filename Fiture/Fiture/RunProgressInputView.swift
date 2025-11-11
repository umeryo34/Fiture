//
//  RunProgressInputView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/10.
//

import SwiftUI

struct RunProgressInputView: View {
    let runTarget: RunTarget
    let runTargetManager: RunTargetManager
    let userId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var progressValue: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
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
                
                // 現在の進捗表示
                VStack(spacing: 10) {
                    Text("現在の進捗")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", runTarget.attempt)) / \(String(format: "%.1f", runTarget.target)) km")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("\(String(format: "%.0f", runTarget.progressPercentage))% 達成")
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
                    
                    Text("単位: km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // 更新ボタン
                Button(action: updateProgress) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("進捗を更新")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(progressValue.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(progressValue.isEmpty || isLoading)
            }
            .navigationTitle("進捗更新")
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
            progressValue = String(format: "%.1f", runTarget.attempt)
        }
    }
    
    private func updateProgress() {
        guard let value = Double(progressValue) else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await runTargetManager.updateRunTarget(userId: userId, attempt: value, date: runTarget.date)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "更新に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    let sampleTarget = RunTarget(userId: UUID(), date: Date(), target: 10.0, attempt: 5.0, isAchieved: false, createdAt: Date(), updatedAt: Date())
    RunProgressInputView(runTarget: sampleTarget, runTargetManager: RunTargetManager(), userId: UUID())
}


//
//  TrainingProgressInputView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct TrainingProgressInputView: View {
    let trainingTarget: TrainingTarget
    let trainingTargetManager: TrainingTargetManager
    let userId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var progressValue: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
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
                    
                    Text("\(trainingTarget.exerciseType)進捗更新")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                
                // 現在の進捗表示
                VStack(spacing: 10) {
                    Text("現在の進捗")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.0f", trainingTarget.attempt)) / \(String(format: "%.0f", trainingTarget.target)) セット")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("\(String(format: "%.0f", trainingTarget.progressPercentage))% 達成")
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
                    
                    Text("単位: セット")
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
                Button(action: {
                    updateProgress()
                }) {
                    Text("進捗を更新")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!progressValue.isEmpty ? Color.red : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(progressValue.isEmpty || isLoading)
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
            progressValue = String(format: "%.0f", trainingTarget.attempt)
        }
    }
    
    private func updateProgress() {
        guard let value = Double(progressValue) else {
            errorMessage = "有効な数値を入力してください"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await trainingTargetManager.updateTrainingTarget(
                    userId: userId,
                    exerciseType: trainingTarget.exerciseType,
                    attempt: value,
                    date: trainingTarget.date
                )
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "進捗の更新に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    let sampleTarget = TrainingTarget(userId: UUID(), date: Date(), exerciseType: "ベンチプレス", target: 10.0, attempt: 5.0, isAchieved: false, createdAt: Date(), updatedAt: Date())
    TrainingProgressInputView(trainingTarget: sampleTarget, trainingTargetManager: TrainingTargetManager(), userId: UUID())
}


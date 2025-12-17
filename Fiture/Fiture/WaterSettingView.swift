//
//  WaterSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct WaterSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var waterEntryManager: WaterEntryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var mlValue: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("water")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("水")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                .padding(.top, 20)
                
                // 今日の合計水量表示
                if let waterEntry = waterEntryManager.waterEntries.first {
                    VStack(spacing: 10) {
                        Text("今日の合計水量")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.0f", waterEntry.ml)) ml")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                        
                        Text("\(String(format: "%.1f", waterEntry.ml / 1000.0)) L")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
                
                // 水入力フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今回飲んだ量")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("数値を入力", text: $mlValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("単位: ml")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                // 既存の記録がある場合、削除ボタンを表示
                if let waterEntry = waterEntryManager.waterEntries.first {
                    VStack(spacing: 10) {
                        Text("記録日時")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(formatDate(waterEntry.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(waterEntry.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
                
                // エラーメッセージ
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 保存ボタン
                Button(action: saveWater) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("水を追加")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(isFormValid ? Color.cyan : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .disabled(!isFormValid || isLoading)
                
                // 削除ボタン（既存の記録がある場合のみ表示）
                if !waterEntryManager.waterEntries.isEmpty {
                    Button(action: deleteWater) {
                        Text("記録を削除")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("水の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            // 既存の水の記録を取得
            if let userId = authManager.currentUser?.id {
                try? await waterEntryManager.fetchWaterEntries(userId: userId)
                // 入力フィールドは常に空にする（加算方式のため）
                mlValue = ""
            }
        }
    }
    
    private var isFormValid: Bool {
        !mlValue.isEmpty && Double(mlValue) != nil
    }
    
    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    private func saveWater() {
        guard let ml = Double(mlValue),
              let userId = authManager.currentUser?.id else {
            errorMessage = "有効な数値を入力してください"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                // 既存の記録があれば加算、なければ新規作成
                let existingMl = waterEntryManager.waterEntries.first?.ml ?? 0
                let newTotalMl = existingMl + ml
                
                try await waterEntryManager.createOrUpdateWaterEntry(
                    userId: userId,
                    ml: newTotalMl,
                    date: waterEntryManager.selectedDate
                )
                
                await MainActor.run {
                    isLoading = false
                    // 入力フィールドをクリア（加算方式のため）
                    mlValue = ""
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
    
    private func deleteWater() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await waterEntryManager.deleteWaterEntry(
                    userId: userId,
                    date: waterEntryManager.selectedDate
                )
                
                await MainActor.run {
                    isLoading = false
                    mlValue = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    WaterSettingView()
        .environmentObject(AuthManager.shared)
        .environmentObject(WaterEntryManager())
}


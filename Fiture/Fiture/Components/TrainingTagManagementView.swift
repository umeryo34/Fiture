//
//  TrainingTagManagementView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct TrainingTagManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingTargetManager: TrainingTargetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTagName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("タグ管理")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // 新しいタグ追加
                VStack(alignment: .leading, spacing: 8) {
                    Text("新しいタグを追加")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 10) {
                        TextField("例: ベンチプレス", text: $newTagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            addTag()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
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
                
                // タグ一覧
                if trainingTargetManager.trainingTags.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tag")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("タグがありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(trainingTargetManager.trainingTags) { tag in
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.red)
                                Text(tag.tagName)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            deleteTags(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("タグ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if let userId = authManager.currentUser?.id {
                try? await trainingTargetManager.fetchTrainingTags(userId: userId)
            }
        }
    }
    
    private func addTag() {
        guard !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userId = authManager.currentUser?.id else { return }
        
        // 既に同じ名前のタグが存在するかチェック
        if trainingTargetManager.trainingTags.contains(where: { $0.tagName.lowercased() == newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }) {
            errorMessage = "このタグは既に存在します"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await trainingTargetManager.createTrainingTag(
                    userId: userId,
                    tagName: newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    newTagName = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "タグの追加に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            for index in offsets {
                let tag = trainingTargetManager.trainingTags[index]
                do {
                    try await trainingTargetManager.deleteTrainingTag(userId: userId, tagId: tag.id)
                } catch {
                    await MainActor.run {
                        errorMessage = "タグの削除に失敗しました: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        }
    }
}

#Preview {
    TrainingTagManagementView()
        .environmentObject(AuthManager.shared)
        .environmentObject(TrainingTargetManager())
}


//
//  CaloriesDayDetailView.swift
//  Fiture
//

import SwiftUI

/// 当日の食事一覧と誤入力の削除
struct CaloriesDayDetailView: View {
    let caloriesTargetManager: CaloriesTargetManager
    let userId: UUID
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    private var entries: [CaloriesEntry] {
        caloriesTargetManager.caloriesEntries.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("今日の食事記録はありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(entries) { entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.foodName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("\(String(format: "%.0f", entry.calories)) kcal")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatTime(entry.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                Spacer()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("今日の食事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                try? await caloriesTargetManager.fetchCaloriesEntries(userId: userId, date: date)
            }
            .safeAreaInset(edge: .bottom) {
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func deleteEntry(_ entry: CaloriesEntry) {
        Task {
            do {
                try await caloriesTargetManager.deleteCaloriesEntry(
                    entryId: entry.id,
                    userId: userId,
                    date: date
                )
                await MainActor.run {
                    showError = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

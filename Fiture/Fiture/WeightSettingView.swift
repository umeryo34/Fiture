//
//  WeightSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct WeightSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var weightTargetManager: WeightTargetManager
    @Environment(\.dismiss) private var dismiss

    @State private var weightTenthKg = 600
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

    private static let weightMinTenth = 300
    private static let weightMaxTenth = 2000

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("体重")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 20)

                if let weightEntry = weightTargetManager.weightEntry {
                    VStack(spacing: 10) {
                        Text("現在の体重")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(String(format: "%.1f", weightEntry.weight)) kg")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)

                        Text(formatDate(weightEntry.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }

                WeightChartView(weightEntries: weightTargetManager.weightEntries)
                    .padding(.vertical, 10)

                RulerScrollValuePicker(
                    title: "体重",
                    unit: "kg",
                    minTenth: Self.weightMinTenth,
                    maxTenth: Self.weightMaxTenth,
                    selectionTenth: $weightTenthKg
                )
                .padding(.horizontal, 20)

                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Spacer()

                Button(action: saveWeight) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text(weightTargetManager.weightEntry == nil ? "体重を記録" : "体重を更新")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(Color.red)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(isLoading)
            }
            .navigationTitle("体重記録")
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
            if let userId = authManager.currentUser?.id {
                async let fetchEntry = weightTargetManager.fetchWeightEntry(userId: userId, date: weightTargetManager.selectedDate)
                async let fetchEntries = weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
                try? await fetchEntry
                try? await fetchEntries

                if let weightEntry = weightTargetManager.weightEntry {
                    let tenth = Int((weightEntry.weight * 10).rounded())
                    weightTenthKg = min(Self.weightMaxTenth, max(Self.weightMinTenth, tenth))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }

    private func saveWeight() {
        guard let userId = authManager.currentUser?.id else { return }

        let weight = Double(weightTenthKg) / 10
        isLoading = true
        showError = false

        Task {
            do {
                let currentDate = weightTargetManager.selectedDate

                try await weightTargetManager.createOrUpdateWeightEntry(userId: userId, weight: weight, date: currentDate)
                try await weightTargetManager.fetchWeightEntries(userId: userId, days: 30)

                NotificationCenter.default.post(name: .weightDataDidUpdate, object: nil)

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
    WeightSettingView()
        .environmentObject(AuthManager.shared)
        .environmentObject(WeightTargetManager())
}

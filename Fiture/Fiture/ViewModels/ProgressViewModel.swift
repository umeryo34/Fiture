//
//  ProgressViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var caloriesHistory: [(date: Date, totalCalories: Double)] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var isLoading = false
    
    private let weightTargetManager = WeightTargetManager()
    private let caloriesTargetManager = CaloriesTargetManager()
    weak var authManager: AuthManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Methods
    
    func fetchAllData() async {
        guard let userId = authManager?.currentUser?.id else {
            print("ユーザーIDが取得できません")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        async let fetchWeight = weightTargetManager.fetchWeightEntries(userId: userId, days: 30)
        async let fetchCalories = caloriesTargetManager.fetchCaloriesHistory(userId: userId, days: 30)
        
        do {
            try await fetchWeight
            weightEntries = weightTargetManager.weightEntries
            print("体重データ取得完了: \(weightEntries.count)件")
        } catch {
            print("体重データ取得エラー: \(error)")
        }
        
        do {
            caloriesHistory = try await fetchCalories
            print("カロリーデータ取得完了: \(caloriesHistory.count)件")
        } catch {
            print("カロリーデータ取得エラー: \(error)")
        }
    }
}

//
//  HomeViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showingTargetSetting = false
    @Published var showingCaloriesInput = false
    @Published var showingDatePicker = false
    @Published var showingSearch = false
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    /// 選択日のヘルスケア・アクティブエネルギー合計（kcal）
    @Published var burnedCaloriesKcal: Double = 0
    @Published var healthKitErrorMessage: String?
    
    private let caloriesTargetManager = CaloriesTargetManager()
    weak var authManager: AuthManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Computed Properties
    
    var userName: String {
        authManager?.currentUser?.name ?? "ユーザー"
    }
    
    var targetCalories: Double? {
        caloriesTargetManager.caloriesTarget?.target
    }
    
    var totalCalories: Double {
        caloriesTargetManager.totalCalories
    }

    /// 食事摂取 − 消費カロリー（運動後の「正味」摂取イメージ）
    var netCaloriesAfterBurn: Double {
        totalCalories - burnedCaloriesKcal
    }
    
    var caloriesEntries: [CaloriesEntry] {
        caloriesTargetManager.caloriesEntries
    }
    
    var totalCaloriesColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .black
        }
        return totalCalories > target ? .red : .black
    }
    
    var totalCaloriesBackgroundColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.black.opacity(0.05)
        }
        return totalCalories > target ? Color.red.opacity(0.08) : Color.black.opacity(0.05)
    }
    
    var totalCaloriesBorderColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.black.opacity(0.15)
        }
        return totalCalories > target ? Color.red.opacity(0.3) : Color.black.opacity(0.15)
    }
    
    var progressColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .black
        }
        return totalCalories >= target ? .red : .black
    }
    
    // MARK: - Methods
    
    func fetchCaloriesData() async {
        await fetchCaloriesDataForDate(selectedDate)
    }
    
    func fetchCaloriesDataForDate(_ date: Date) async {
        guard let userId = authManager?.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId, date: date)
        async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId, date: date)
        
        try? await fetchEntries
        try? await fetchTarget
        await fetchBurnedCaloriesFromHealth(for: date)
    }

    func fetchBurnedCaloriesFromHealth(for date: Date) async {
        healthKitErrorMessage = nil
        guard HealthKitCalorieService.shared.isAvailable else {
            burnedCaloriesKcal = 0
            healthKitErrorMessage = "この端末ではヘルスケアを利用できません。"
            return
        }

        do {
            try await HealthKitCalorieService.shared.requestAuthorization()
            burnedCaloriesKcal = try await HealthKitCalorieService.shared.activeEnergyBurnedKcal(on: date)
        } catch {
            burnedCaloriesKcal = 0
            healthKitErrorMessage = error.localizedDescription
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    func getCaloriesTargetManager() -> CaloriesTargetManager {
        return caloriesTargetManager
    }
}

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
    
    var caloriesEntries: [CaloriesEntry] {
        caloriesTargetManager.caloriesEntries
    }
    
    var totalCaloriesColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        return totalCalories > target ? .red : .green
    }
    
    var totalCaloriesBackgroundColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.1)
        }
        return totalCalories > target ? Color.red.opacity(0.1) : Color.green.opacity(0.1)
    }
    
    var totalCaloriesBorderColor: Color {
        guard let target = targetCalories, target > 0 else {
            return Color.green.opacity(0.3)
        }
        return totalCalories > target ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
    }
    
    var progressColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        
        let percentage = (totalCalories / target) * 100
        
        // 100%以上は赤固定
        if percentage >= 100 {
            return .red
        }
        
        // 0〜80%：緑 → 黄（滑らかに）
        if percentage <= 80 {
            let progress = percentage / 80.0
            let red = progress * 255
            let green: Double = 255
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        }
        
        // 80〜100%：黄 → オレンジ → 赤（滑らかに）
        let progress = (percentage - 80) / 20.0
        
        if progress <= 0.5 {
            // 80〜90%：黄 → オレンジ
            let localProgress = progress * 2.0
            let red: Double = 255
            let green = 255 - (255 - 165) * localProgress
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        } else {
            // 90〜100%：オレンジ → 赤
            let localProgress = (progress - 0.5) * 2.0
            let red: Double = 255
            let green = 165 - 165 * localProgress
            let blue: Double = 0
            return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0)
        }
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

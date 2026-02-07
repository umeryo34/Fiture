//
//  TargetViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class TargetViewModel: ObservableObject {
    @Published var runTarget: RunTarget?
    @Published var goals: [Goal] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    
    private let runTargetManager = RunTargetManager()
    weak var goalManager: GoalManager?
    weak var authManager: AuthManager?
    
    func setManagers(goalManager: GoalManager, authManager: AuthManager) {
        self.goalManager = goalManager
        self.authManager = authManager
    }
    
    // MARK: - Methods
    
    func fetchRunTarget() async {
        guard let userId = authManager?.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await runTargetManager.fetchRunTarget(userId: userId, date: selectedDate)
            runTarget = runTargetManager.runTarget
        } catch {
            print("Run目標の取得に失敗: \(error)")
        }
    }
    
    func fetchRunTargetForDate(_ date: Date) async {
        guard let userId = authManager?.currentUser?.id else { return }
        
        selectedDate = date
        
        do {
            try await runTargetManager.fetchRunTarget(userId: userId, date: date)
            runTarget = runTargetManager.runTarget
        } catch {
            print("Run目標の取得に失敗: \(error)")
        }
    }
    
    func getRunTargetManager() -> RunTargetManager {
        return runTargetManager
    }
    
    func getGoalManager() -> GoalManager? {
        return goalManager
    }
}

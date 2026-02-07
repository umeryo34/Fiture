//
//  TrainingBodyViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class TrainingBodyViewModel: ObservableObject {
    @Published var showingMuscleRecord = false
    @Published var selectedMuscleType: InteractiveBodyModelView.MuscleType?
    @Published var trainingTargets: [TrainingTarget] = []
    @Published var isLoading = false
    
    private let trainingTargetManager = TrainingTargetManager()
    weak var authManager: AuthManager?
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Methods
    
    func fetchTrainingTargets() async {
        guard let userId = authManager?.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await trainingTargetManager.fetchTrainingTargets(userId: userId)
            trainingTargets = trainingTargetManager.trainingTargets
        } catch {
            print("筋トレ目標の取得に失敗: \(error)")
        }
    }
    
    func selectMuscle(_ muscleType: InteractiveBodyModelView.MuscleType) {
        selectedMuscleType = muscleType
        showingMuscleRecord = true
    }
    
    func getTrainingTargetManager() -> TrainingTargetManager {
        return trainingTargetManager
    }
}

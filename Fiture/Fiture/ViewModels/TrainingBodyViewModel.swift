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
    @Published var muscleVisualStates: [InteractiveBodyModelView.MuscleType: MuscleVisualState] = [:]
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

    /// 今日・昨日の記録から部位の色状態を更新（USDZ ノード名と種目の対応は MuscleExerciseCatalog / MuscleSceneAppearance）
    func refreshMuscleHighlightStates() async {
        guard let userId = authManager?.currentUser?.id else {
            muscleVisualStates = [:]
            return
        }
        let cal = Calendar.current
        let today = Date()
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: today)) else {
            return
        }

        let todayRecords = LocalDataStore.shared.trainingRecords(onDate: today, userId: userId)
        let yesterdayRecords = LocalDataStore.shared.trainingRecords(onDate: yesterday, userId: userId)

        var musclesToday = Set<InteractiveBodyModelView.MuscleType>()
        for r in todayRecords {
            if let m = MuscleExerciseCatalog.muscleType(forExerciseType: r.exerciseType) {
                musclesToday.insert(m)
            }
        }
        var musclesYesterday = Set<InteractiveBodyModelView.MuscleType>()
        for r in yesterdayRecords {
            if let m = MuscleExerciseCatalog.muscleType(forExerciseType: r.exerciseType) {
                musclesYesterday.insert(m)
            }
        }

        var next: [InteractiveBodyModelView.MuscleType: MuscleVisualState] = [:]
        for muscle in InteractiveBodyModelView.MuscleType.allCases {
            if musclesToday.contains(muscle) {
                next[muscle] = .trainedToday
            } else if musclesYesterday.contains(muscle) {
                next[muscle] = .fatigued
            } else {
                next[muscle] = .unused
            }
        }
        muscleVisualStates = next
    }
}

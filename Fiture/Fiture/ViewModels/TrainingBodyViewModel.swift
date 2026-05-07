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

    /// 同一日内は **種目の種類数**（部位へのマッピング後のユニーク種目名）で赤=3以上・黄=1〜2。
    /// 今日が未記録のとき、昨日が赤相当なら黄、昨日が黄相当なら灰へ。
    private static func distinctExerciseCountByMuscle(records: [TrainingRecord]) -> [InteractiveBodyModelView.MuscleType: Int] {
        var namesByMuscle: [InteractiveBodyModelView.MuscleType: Set<String>] = [:]
        for record in records {
            guard let muscle = MuscleExerciseCatalog.muscleType(forExerciseType: record.exerciseType) else { continue }
            namesByMuscle[muscle, default: []].insert(record.exerciseType)
        }
        return namesByMuscle.mapValues { $0.count }
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

        let todayDistinctCount = Self.distinctExerciseCountByMuscle(records: todayRecords)
        let yesterdayDistinctCount = Self.distinctExerciseCountByMuscle(records: yesterdayRecords)

        var next: [InteractiveBodyModelView.MuscleType: MuscleVisualState] = [:]
        for muscle in InteractiveBodyModelView.MuscleType.allCases {
            let todayN = todayDistinctCount[muscle] ?? 0
            let yesterdayN = yesterdayDistinctCount[muscle] ?? 0

            if todayN >= 3 {
                next[muscle] = .trainedToday
            } else if todayN >= 1 {
                next[muscle] = .fatigued
            } else {
                /// 今日は未記録：昨日が赤相当（3種目以上）→黄、昨日が黄相当（1〜2）→灰、それ以外も灰
                if yesterdayN >= 3 {
                    next[muscle] = .fatigued
                } else {
                    next[muscle] = .unused
                }
            }
        }
        muscleVisualStates = next
    }
}

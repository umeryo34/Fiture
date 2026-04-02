//
//  MuscleRecordViewModel.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation
import SwiftUI

@MainActor
class MuscleRecordViewModel: ObservableObject {
    @Published var exerciseType: String = ""
    @Published var sets: [TrainingSet] = [TrainingSet()]
    @Published var savedRecords: [TrainingRecord] = []
    @Published var isEditingExistingRecord: Bool = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    let muscleType: InteractiveBodyModelView.MuscleType
    private let trainingTargetManager: TrainingTargetManager
    weak var authManager: AuthManager?
    
    // 部位ごとの種目リスト
    var availableExercises: [String] {
        switch muscleType {
        case .chest:
            return ["ベンチプレス", "インクラインベンチプレス", "ダンベルベンチプレス", "ディップス", "荷重ディップス", "ダンベルフライ", "インクラインダンベルフライ", "腕立て伏せ", "ナロープッシュアップ", "チェストプレスマシン", "ペックデッキフライ"]
        case .back:
            return ["グッドモーニング", "デッドリフト", "プルアップ", "ベントオーバーロー", "ラットプルダウン", "シーテッドロウマシン", "シーテッドケーブルロウ", "ダンベルロウ", "ワンハンドダンベルロウ"]
        case .abs:
            return ["腹筋(クランチ)", "Vアップ", "プランク", "レッグレイズ", "レッグレイズマシン"]
        case .arms:
            return ["バーベルカール", "ダンベルカール", "ダンベルリストカール", "プリーチャーカールマシン", "ケーブルカール"]
        case .triceps:
            return ["ダンベルフレンチプレス", "バーベルフレンチプレス", "クローズグリップベンチプレス", "ケーブルトライセプスエクステンション"]
        case .legs:
            return ["スクワット", "ハーフスクワット", "レッグプレス", "レッグカール", "レッグエクステンション", "シーテッドカーフレイズ", "ブルガリアンスクワット"]
        case .glutes:
            return []
        }
    }
    
    // 腹筋は重量なし
    var showWeightInput: Bool {
        muscleType != .abs
    }
    
    var isFormValid: Bool {
        guard !exerciseType.isEmpty else { return false }
        
        // 腹の場合は回数のみ、それ以外は重量と回数が必要
        if muscleType == .abs {
            return sets.contains { !$0.reps.isEmpty }
        } else {
            return sets.contains { !$0.weight.isEmpty && !$0.reps.isEmpty }
        }
    }
    
    init(muscleType: InteractiveBodyModelView.MuscleType, trainingTargetManager: TrainingTargetManager) {
        self.muscleType = muscleType
        self.trainingTargetManager = trainingTargetManager
    }
    
    func setAuthManager(_ authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Methods
    
    func addSet() {
        sets.append(TrainingSet())
    }
    
    func removeSet(at index: Int) {
        if sets.count > 1 {
            sets.remove(at: index)
        }
    }

    /// 保存済みのセット（重量/回数）を読み込んでフォームに反映する
    /// - 注意: 呼び出し側で `exerciseType` が確定している場合（タグ/定番ボタン押下など）に呼ぶ前提。
    func loadSavedSets(exerciseType: String) async {
        guard let userId = authManager?.currentUser?.id else { return }

        let currentDate = trainingTargetManager.selectedDate

        do {
            if let record = try await trainingTargetManager.fetchTrainingRecord(
                userId: userId,
                date: currentDate,
                exerciseType: exerciseType
            ) {
                let loadedSets = record.sets.map { TrainingSet(weight: $0.weight, reps: $0.reps) }
                self.sets = loadedSets.isEmpty ? [TrainingSet()] : loadedSets
                self.isEditingExistingRecord = true
            } else {
                self.sets = [TrainingSet()]
                self.isEditingExistingRecord = false
            }
        } catch {
            // 読み込み失敗時はフォームをそのままにする（UIは壊さない）
        }
    }

    /// 選択した種目の過去レコード一覧を取得する（一覧表示用）
    func loadSavedRecords(exerciseType: String) async {
        guard let userId = authManager?.currentUser?.id else { return }

        do {
            self.savedRecords = try await trainingTargetManager.fetchTrainingRecords(
                userId: userId,
                exerciseType: exerciseType
            )
        } catch {
            self.savedRecords = []
        }
    }

    /// 既存レコードを読み込んで「変更」モードに切り替える
    func applyRecord(_ record: TrainingRecord) {
        // 編集対象の日付/種目を揃える
        trainingTargetManager.selectedDate = record.date
        exerciseType = record.exerciseType

        sets = record.sets.map { TrainingSet(weight: $0.weight, reps: $0.reps) }
        isEditingExistingRecord = true
    }
    
    @discardableResult
    func saveRecord() async -> Bool {
        guard let userId = authManager?.currentUser?.id else {
            errorMessage = "ユーザー情報が取得できません"
            showError = true
            return false
        }
        
        // 有効なセットをフィルタリング（腹の場合は回数のみ、それ以外は重量と回数）
        let validSets: [TrainingSet]
        if muscleType == .abs {
            validSets = sets.filter { !$0.reps.isEmpty }
        } else {
            validSets = sets.filter { !$0.weight.isEmpty && !$0.reps.isEmpty }
        }
        
        guard !validSets.isEmpty else {
            errorMessage = "少なくとも1セットの記録が必要です"
            showError = true
            return false
        }
        
        isLoading = true
        showError = false
        
        do {
            let currentDate = trainingTargetManager.selectedDate
            
            // セット数を目標として保存
            let targetSets = Double(validSets.count)
            
            // 既存の目標があるか確認
            let existing = try await trainingTargetManager.fetchTrainingTarget(
                userId: userId,
                date: currentDate,
                exerciseType: exerciseType
            )
            
            if let existing = existing {
                // 既存の目標を更新（セット数を更新）
                try await trainingTargetManager.updateTrainingTarget(
                    userId: userId,
                    exerciseType: exerciseType,
                    target: targetSets,
                    attempt: targetSets,
                    date: currentDate
                )
            } else {
                // 新規作成
                try await trainingTargetManager.createOrUpdateTrainingTarget(
                    userId: userId,
                    exerciseType: exerciseType,
                    target: targetSets,
                    date: currentDate
                )
                // 進捗も更新
                try await trainingTargetManager.updateTrainingTarget(
                    userId: userId,
                    exerciseType: exerciseType,
                    attempt: targetSets,
                    date: currentDate
                )
            }

            // セット単位（重量/回数）もローカルに保存
            let setEntries = validSets.map { TrainingSetEntry(weight: $0.weight, reps: $0.reps) }
            try await trainingTargetManager.upsertTrainingRecord(
                userId: userId,
                date: currentDate,
                exerciseType: exerciseType,
                sets: setEntries
            )

            // 画面遷移（dismiss）前提だが、次に開いたときに一覧がズレないよう最新化
            await loadSavedRecords(exerciseType: exerciseType)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            showError = true
            errorMessage = "記録の保存に失敗しました: \(error.localizedDescription)"
            return false
        }
    }
}

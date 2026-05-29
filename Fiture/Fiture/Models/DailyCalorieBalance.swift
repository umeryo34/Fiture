//
//  DailyCalorieBalance.swift
//  Fiture
//

import Foundation

/// 1日分の食事・消費・目標から収支と超過運動見積もりを算出する
struct DailyCalorieBalance {
    let foodIntakeKcal: Double
    let activeEnergyBurnedKcal: Double
    let targetKcal: Double?
    let weightKg: Double?

    var netKcal: Double {
        foodIntakeKcal - activeEnergyBurnedKcal
    }

    /// 目標を超えている kcal（超過時のみ正）
    var excessOverTargetKcal: Double? {
        guard let target = targetKcal, target > 0 else { return nil }
        let excess = netKcal - target
        return excess > 0 ? excess : nil
    }

    func exercisePlan(
        gymWalkingSpeedKmh: Double = ExcessBurnExercisePlanner.defaultGymWalkingSpeedKmh,
        gymWalkingInclinePercent: Double = ExcessBurnExercisePlanner.defaultGymWalkingInclinePercent
    ) -> ExcessBurnExercisePlan? {
        guard let excess = excessOverTargetKcal,
              let weight = weightKg,
              weight > 0 else {
            return nil
        }
        return ExcessBurnExercisePlanner.plan(
            excessKcal: excess,
            weightKg: weight,
            gymWalkingSpeedKmh: gymWalkingSpeedKmh,
            gymWalkingInclinePercent: gymWalkingInclinePercent
        )
    }
}

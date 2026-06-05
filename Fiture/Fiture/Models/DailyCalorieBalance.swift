//
//  DailyCalorieBalance.swift
//  Fiture
//

import Foundation

struct DailyCalorieBalance {
    let foodIntakeKcal: Double
    let activeEnergyBurnedKcal: Double
    let targetKcal: Double?
    let weightKg: Double?

    var netKcal: Double {
        foodIntakeKcal - activeEnergyBurnedKcal
    }

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

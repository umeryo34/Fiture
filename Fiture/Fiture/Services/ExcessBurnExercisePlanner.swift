//
//  ExcessBurnExercisePlanner.swift
//  Fiture
//
//  目標超過分を消費するために必要な運動時間の見積もり。
//

import Foundation

struct ExerciseTimeEstimate: Equatable {
    let title: String
    let speedKmh: Double
    /// トレッドミル勾配率（%）
    let inclinePercent: Double
    let durationSeconds: TimeInterval

    var formattedDuration: String {
        ExcessBurnExercisePlanner.formatDuration(durationSeconds)
    }
}

struct ExcessBurnExercisePlan: Equatable {
    let excessKcal: Double
    let gymWalking: ExerciseTimeEstimate
    let outdoorRunning: ExerciseTimeEstimate
}

enum ExcessBurnExercisePlanner {
    /// ジム・ウォーキング（勾配 %）
    static let defaultGymWalkingSpeedKmh = 5.0
    static let defaultGymWalkingInclinePercent = 5.0

    /// 屋外ランニング（平坦）
    static let outdoorRunningSpeedKmh = 8.0
    static let outdoorRunningInclinePercent = 0.0

    static func plan(
        excessKcal: Double,
        weightKg: Double,
        gymWalkingSpeedKmh: Double = defaultGymWalkingSpeedKmh,
        gymWalkingInclinePercent: Double = defaultGymWalkingInclinePercent
    ) -> ExcessBurnExercisePlan? {
        guard excessKcal > 0, weightKg > 0 else { return nil }

        guard let walkSeconds = ACSMRunCalorieCalculator.durationSeconds(
            toBurnKcal: excessKcal,
            weightKg: weightKg,
            speedKmh: gymWalkingSpeedKmh,
            inclinePercent: gymWalkingInclinePercent,
            kind: .walk
        ),
        let runSeconds = ACSMRunCalorieCalculator.durationSeconds(
            toBurnKcal: excessKcal,
            weightKg: weightKg,
            speedKmh: outdoorRunningSpeedKmh,
            inclinePercent: outdoorRunningInclinePercent,
            kind: .run
        ) else {
            return nil
        }

        return ExcessBurnExercisePlan(
            excessKcal: excessKcal,
            gymWalking: ExerciseTimeEstimate(
                title: "ジム・ウォーキング",
                speedKmh: gymWalkingSpeedKmh,
                inclinePercent: gymWalkingInclinePercent,
                durationSeconds: walkSeconds
            ),
            outdoorRunning: ExerciseTimeEstimate(
                title: "ランニング（屋外・平坦）",
                speedKmh: outdoorRunningSpeedKmh,
                inclinePercent: outdoorRunningInclinePercent,
                durationSeconds: runSeconds
            )
        )
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)時間\(minutes)分"
            }
            return "\(hours)時間"
        }
        if minutes > 0 {
            return secs > 0 ? "\(minutes)分\(secs)秒" : "\(minutes)分"
        }
        return "\(max(secs, 1))秒"
    }
}

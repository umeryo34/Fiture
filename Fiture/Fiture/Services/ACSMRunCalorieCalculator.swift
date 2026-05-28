//
//  ACSMRunCalorieCalculator.swift
//  Fiture
//
//  ACSM（トレッドミル）式による VO2 → 消費カロリー推定。
//  ジムの傾斜は勾配率（%）。例: 15% → G = 0.15（100m進んで高さ15m）。
//

import Foundation

enum ACSMRunActivityKind {
    case walk
    case run
}

enum ACSMRunCalorieCalculator {
    /// 勾配率（%）→ ACSM の G（rise/run）
    static func gradeDecimal(fromInclinePercent percent: Double) -> Double {
        max(0, percent) / 100.0
    }

    /// VO2（ml/kg/min）
    static func vo2MlPerKgMin(speedKmh: Double, gradeDecimal G: Double, kind: ACSMRunActivityKind) -> Double {
        let v = speedKmh * 1000.0 / 60.0
        switch kind {
        case .walk:
            return 0.1 * v + 1.8 * v * G + 3.5
        case .run:
            return 0.2 * v + 0.9 * v * G + 3.5
        }
    }

    /// 1分あたりの消費カロリー（kcal）
    static func kcalPerMinute(
        weightKg: Double,
        speedKmh: Double,
        inclinePercent: Double,
        kind: ACSMRunActivityKind
    ) -> Double {
        guard weightKg > 0, speedKmh > 0 else { return 0 }
        let G = gradeDecimal(fromInclinePercent: inclinePercent)
        let vo2 = vo2MlPerKgMin(speedKmh: speedKmh, gradeDecimal: G, kind: kind)
        return (vo2 * weightKg / 1000.0) * 5.0
    }

    /// 指定 kcal を消費するのに必要な時間（秒）。切り上げ。
    static func durationSeconds(
        toBurnKcal kcal: Double,
        weightKg: Double,
        speedKmh: Double,
        inclinePercent: Double,
        kind: ACSMRunActivityKind
    ) -> TimeInterval? {
        let rate = kcalPerMinute(
            weightKg: weightKg,
            speedKmh: speedKmh,
            inclinePercent: inclinePercent,
            kind: kind
        )
        guard rate > 0, kcal > 0 else { return nil }
        let minutes = kcal / rate
        return ceil(minutes * 60.0)
    }
}

enum RunCalorieProfile {
    static func weightKg(userId: UUID?) -> Double? {
        FitnessProfileStorage.load(userId: userId).weightKg
    }
}

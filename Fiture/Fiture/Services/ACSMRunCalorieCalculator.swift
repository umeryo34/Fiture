//
//  ACSMRunCalorieCalculator.swift
//  Fiture
//
//  ACSM（トレッドミル）式による VO2 → 消費カロリー推定。
//  - 速度 v: m/min（km/h × 1000 / 60）
//  - 傾斜 G: 小数（12% → 0.12）。UIが「度」の場合は gradeDecimal(fromDegrees:) を使用。
//

import Foundation

enum ACSMRunActivityKind {
    case walk
    case run
}

enum ACSMRunCalorieCalculator {
    /// 傾斜をパーセントで持つ場合（ジム表示が % のとき）
    static func gradeDecimal(fromInclinePercent percent: Double) -> Double {
        max(0, percent) / 100.0
    }

    /// 傾斜を度で持つ場合 → 勾配 G = tan(θ)（rise/run）
    static func gradeDecimal(fromDegrees degrees: Double) -> Double {
        let rad = degrees * .pi / 180.0
        return max(0, tan(rad))
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

    static func kcalPerMinute(vo2: Double, weightKg: Double) -> Double {
        (vo2 * weightKg / 1000.0) * 5.0
    }

    /// METs（表示用、VO2 / 3.5）
    static func mets(vo2: Double) -> Double {
        vo2 / 3.5
    }

    /// セッション合計 kcal
    static func totalCalories(
        weightKg: Double,
        speedKmh: Double,
        gradeDecimal G: Double,
        durationSeconds: TimeInterval,
        kind: ACSMRunActivityKind
    ) -> Double {
        guard weightKg > 0, speedKmh > 0, durationSeconds > 0 else { return 0 }
        let vo2 = vo2MlPerKgMin(speedKmh: speedKmh, gradeDecimal: G, kind: kind)
        let kcalMin = kcalPerMinute(vo2: vo2, weightKg: weightKg)
        return kcalMin * (durationSeconds / 60.0)
    }

    /// 屋外（傾斜0）: 平均速度から walk / run を切り替え（6 km/h 以上を run）
    static func mapActivityKind(averageSpeedKmh: Double) -> ACSMRunActivityKind {
        averageSpeedKmh >= 6.0 ? .run : .walk
    }
}

enum RunCalorieProfile {
    /// フィットネスプロフィールの体重（未設定なら nil）
    static func weightKg() -> Double? {
        let uid = LocalDataStore.shared.currentUser()?.id
        return FitnessProfileStorage.load(userId: uid).weightKg
    }
}

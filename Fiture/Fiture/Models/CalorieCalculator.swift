//
//  CalorieCalculator.swift
//  Fiture
//
//  BMR（ミフリン・サン・ジェオール）→ TDEE → 体組成目標・体重トレンドを反映した摂取目標
//

import Foundation

/// 計算に必要な身体・活動情報（プレビュー／単体テスト用にも使える）
struct CalorieUserProfile: Equatable {
    var weightKg: Double
    var heightCm: Double
    var ageYears: Int
    var gender: FitnessGender
    var activityLevel: FitnessActivityLevel
    var bodyGoal: FitnessBodyGoal
}

/// TDEE に対する摂取バランス（正の値 = 摂取を抑える＝不足分）
struct DietGoal: Equatable {
    /// TDEE から引く kcal（例: 減量 500）
    var netDeficitFromTDEE: Double
}

struct CalorieResult: Equatable {
    let bmr: Double
    let tdee: Double
    /// 1 日の摂取目標 (kcal)
    let targetCalories: Double
    /// 目標体重・期限から算出した 1 日あたりの不足分（使っていなければ nil）
    let weightGoalDailyDeficit: Double?
    /// 直近の体重トレンドに基づく補正（kcal）
    let weeklyTrendAdjustmentKcal: Double
    /// タンパク質の目安（g / 日、体重 × 1.8）
    let suggestedProteinGramsPerDay: Double
}

enum CalorieCalculator {
    /// 安全域としての摂取下限（簡易）
    static let minimumTargetKcal: Double = 1200
    /// 目標体重から逆算した「1 日の不足」の上限（過度な制限を防ぐ）
    static let maximumDailyDeficitFromWeightGoal: Double = 900

    // MARK: - コア式

    static func bmr(weightKg: Double, heightCm: Double, ageYears: Int, gender: FitnessGender) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(ageYears)
        switch gender {
        case .male:
            return base + 5
        case .female:
            return base - 161
        case .other, .preferNot:
            return base - 78
        }
    }

    static func tdee(bmr: Double, activityLevel: FitnessActivityLevel) -> Double {
        bmr * activityLevel.coefficient
    }

    /// 体組成目標に応じた TDEE からのバランス（正 = 摂取を抑える）
    static func baseEnergyBalanceFromBodyGoal(_ bodyGoal: FitnessBodyGoal) -> Double {
        switch bodyGoal {
        case .lose:
            return 500
        case .maintain:
            return 0
        case .gain:
            return -300
        }
    }

    // MARK: - 目標体重・期限（7200 kcal / kg 脂肪の近似）

    /// 減量時: 現在体重と目標体重・期限から必要な 1 日あたりの不足分 (kcal)。無効なら nil。
    static func dailyDeficitFromWeightGoal(
        currentWeightKg: Double,
        goalWeightKg: Double,
        goalDate: Date,
        referenceDate: Date = Date()
    ) -> Double? {
        guard goalWeightKg < currentWeightKg - 0.15 else { return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: referenceDate)
        let end = cal.startOfDay(for: goalDate)
        guard end > start else { return nil }
        let days = max(cal.dateComponents([.day], from: start, to: end).day ?? 0, 1)
        guard days >= 7 else { return nil }
        let kgToLose = currentWeightKg - goalWeightKg
        guard kgToLose > 0 else { return nil }
        let perDay = kgToLose * 7200 / Double(days)
        return min(max(perDay, 0), maximumDailyDeficitFromWeightGoal)
    }

    // MARK: - 体重トレンド（直近 7 日平均 − その前 7 日平均）

    /// 目標 kcal へ足す補正（増えすぎ −100、落ちすぎ +100）
    static func weeklyWeightTrendAdjustmentKcal(userId: UUID, referenceDate: Date = Date()) -> Double {
        let entries = LocalDataStore.shared.weightEntries(userId: userId, days: 20)
        guard entries.count >= 2 else { return 0 }
        let cal = Calendar.current
        let ref = cal.startOfDay(for: referenceDate)
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: ref),
              let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: ref) else { return 0 }

        let recent = entries.filter { $0.date >= weekAgo && $0.date <= ref }
        let older = entries.filter { $0.date >= twoWeeksAgo && $0.date < weekAgo }
        guard let recentAvg = averageWeight(recent),
              let olderAvg = averageWeight(older) else { return 0 }

        let diff = recentAvg - olderAvg
        if diff > 0.3 { return -100 }
        if diff < -0.3 { return 100 }
        return 0
    }

    private static func averageWeight(_ entries: [WeightEntry]) -> Double? {
        guard !entries.isEmpty else { return nil }
        return entries.map(\.weight).reduce(0, +) / Double(entries.count)
    }

    // MARK: - 統合

    /// 保存済みプロフィールから 1 日の摂取目標などをまとめて算出
    static func calculate(
        profile: FitnessTargetProfile,
        userId: UUID?,
        referenceDate: Date = Date()
    ) -> CalorieResult? {
        guard profile.isCompleted,
              let w = profile.weightKg,
              let h = profile.heightCm,
              let age = profile.ageYears,
              let gender = profile.gender,
              let body = profile.bodyGoal,
              let act = profile.activityLevel
        else { return nil }

        let bmrV = bmr(weightKg: w, heightCm: h, ageYears: age, gender: gender)
        let tdeeV = tdee(bmr: bmrV, activityLevel: act)

        var balance = baseEnergyBalanceFromBodyGoal(body)
        var weightGoalDaily: Double?

        if body == .lose,
           let gw = profile.goalTargetWeightKg,
           let gd = profile.goalTargetDate,
           let dGoal = dailyDeficitFromWeightGoal(
               currentWeightKg: w,
               goalWeightKg: gw,
               goalDate: gd,
               referenceDate: referenceDate
           ) {
            weightGoalDaily = dGoal
            balance = max(balance, dGoal)
        }

        var target = tdeeV - balance
        let trend: Double
        if let uid = userId {
            trend = weeklyWeightTrendAdjustmentKcal(userId: uid, referenceDate: referenceDate)
        } else {
            trend = 0
        }
        target += trend
        target = max(minimumTargetKcal, target)

        let protein = w * 1.8

        return CalorieResult(
            bmr: bmrV,
            tdee: tdeeV,
            targetCalories: target,
            weightGoalDailyDeficit: weightGoalDaily,
            weeklyTrendAdjustmentKcal: trend,
            suggestedProteinGramsPerDay: protein
        )
    }

    /// 任意の不足分を指定して試算（プレビュー用）
    static func calculate(profile: CalorieUserProfile, dietGoal: DietGoal) -> CalorieResult {
        let bmrV = bmr(weightKg: profile.weightKg, heightCm: profile.heightCm, ageYears: profile.ageYears, gender: profile.gender)
        let tdeeV = tdee(bmr: bmrV, activityLevel: profile.activityLevel)
        let target = max(minimumTargetKcal, tdeeV - dietGoal.netDeficitFromTDEE)
        let protein = profile.weightKg * 1.8
        return CalorieResult(
            bmr: bmrV,
            tdee: tdeeV,
            targetCalories: target,
            weightGoalDailyDeficit: nil,
            weeklyTrendAdjustmentKcal: 0,
            suggestedProteinGramsPerDay: protein
        )
    }
}

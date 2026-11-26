//
//  NutritionGoal.swift
//  Fiture
//
//  1日のPFC（たんぱく質・脂質・炭水化物）の目安と、その日の合計
//

import Foundation

/// 1日の栄養の合計（kcal と PFC）
struct NutritionTotals: Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    init(calories: Double = 0, protein: Double = 0, fat: Double = 0, carbs: Double = 0) {
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
    }

    init(entries: [CaloriesEntry]) {
        for entry in entries {
            calories += entry.calories
            protein += entry.protein ?? 0
            fat += entry.fat ?? 0
            carbs += entry.carbs ?? 0
        }
    }

    func grams(_ macro: Macro) -> Double {
        switch macro {
        case .protein: return protein
        case .fat: return fat
        case .carbs: return carbs
        }
    }

    static func + (lhs: NutritionTotals, rhs: NutritionTotals) -> NutritionTotals {
        NutritionTotals(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            fat: lhs.fat + rhs.fat,
            carbs: lhs.carbs + rhs.carbs
        )
    }
}

/// 1日のPFCの目安（g）
struct NutritionGoal: Equatable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double

    func grams(_ macro: Macro) -> Double {
        switch macro {
        case .protein: return protein
        case .fat: return fat
        case .carbs: return carbs
        }
    }

    /// エネルギーに占める割合（%）
    struct Ratio: Equatable {
        let protein: Double
        let fat: Double
        let carbs: Double
    }

    /// 厚生労働省「日本人の食事摂取基準（2025年版）」のエネルギー産生栄養素バランス
    /// （たんぱく質13〜20%、脂質20〜30%、炭水化物50〜65%）の範囲内で、目標に合わせて配分する
    static func ratio(for bodyGoal: FitnessBodyGoal?) -> Ratio {
        switch bodyGoal {
        case .lose: return Ratio(protein: 20, fat: 25, carbs: 55)
        case .gain: return Ratio(protein: 17, fat: 25, carbs: 58)
        case .maintain, nil: return Ratio(protein: 15, fat: 25, carbs: 60)
        }
    }

    static func make(calories: Double, bodyGoal: FitnessBodyGoal?) -> NutritionGoal {
        let ratio = ratio(for: bodyGoal)
        return NutritionGoal(
            calories: calories,
            protein: calories * ratio.protein / 100 / Macro.protein.kcalPerGram,
            fat: calories * ratio.fat / 100 / Macro.fat.kcalPerGram,
            carbs: calories * ratio.carbs / 100 / Macro.carbs.kcalPerGram
        )
    }
}

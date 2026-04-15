//
//  FitnessTargetProfile.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/23.
//

import Foundation

enum FitnessGender: String, CaseIterable, Codable {
    case male = "男性"
    case female = "女性"
    case other = "その他"
    case preferNot = "答えたくない"
}

enum FitnessBodyGoal: String, CaseIterable, Codable {
    case lose = "減量"
    case maintain = "現状維持"
    case gain = "増量"
}

enum FitnessActivityLevel: String, CaseIterable, Codable {
    case low = "低い"
    case medium = "普通"
    case high = "高い"

    var coefficient: Double {
        switch self {
        case .low: return 1.2
        case .medium: return 1.55
        case .high: return 1.725
        }
    }

    var descriptionText: String {
        switch self {
        case .low: return "ほぼ運動しない（デスクワーク中心）"
        case .medium: return "中程度の運動（週3〜5回）"
        case .high: return "激しい運動（週6〜7回）"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case FitnessActivityLevel.low.rawValue, "ほとんど運動しない":
            self = .low
        case FitnessActivityLevel.medium.rawValue, "軽い運動（週1〜2回）", "中程度（週3〜4回）":
            self = .medium
        case FitnessActivityLevel.high.rawValue, "活発（ほぼ毎日）":
            self = .high
        default:
            self = .medium
        }
    }
}

struct FitnessTargetProfile: Codable, Equatable {
    var birthDate: Date?
    var heightCm: Double?
    var weightKg: Double?
    var gender: FitnessGender?
    var bodyGoal: FitnessBodyGoal?
    var activityLevel: FitnessActivityLevel?
    /// 減量プラン用（任意）。期限までにこの体重へ向かう場合の 1 日不足分の参考に使う。
    var goalTargetWeightKg: Double?
    /// `goalTargetWeightKg` とセットで使う達成予定日（ローカル日の始まりで比較される）
    var goalTargetDate: Date?

    var ageYears: Int? {
        guard let birthDate else { return nil }
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return max(years, 0)
    }

    var bmr: Double? {
        guard let weightKg, let heightCm, let ageYears, let gender else { return nil }
        return CalorieCalculator.bmr(weightKg: weightKg, heightCm: heightCm, ageYears: ageYears, gender: gender)
    }

    var tdee: Double? {
        guard let bmr, let activityLevel else { return nil }
        return CalorieCalculator.tdee(bmr: bmr, activityLevel: activityLevel)
    }

    var isCompleted: Bool {
        birthDate != nil &&
        heightCm != nil &&
        weightKg != nil &&
        gender != nil &&
        bodyGoal != nil &&
        activityLevel != nil
    }
}

enum FitnessProfileStorage {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static func storageKey(userId: UUID?) -> String {
        guard let userId else { return "fiture_fitness_profile_guest" }
        return "fiture_fitness_profile_\(userId.uuidString.lowercased())"
    }

    static func load(userId: UUID?) -> FitnessTargetProfile {
        let key = storageKey(userId: userId)
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? decoder.decode(FitnessTargetProfile.self, from: data) else {
            return FitnessTargetProfile()
        }
        return profile
    }

    static func save(_ profile: FitnessTargetProfile, userId: UUID?) {
        let key = storageKey(userId: userId)
        guard let data = try? encoder.encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

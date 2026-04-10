//
//  RunRecord.swift
//  Fiture
//
//  端末ローカルに保存する1回分のRun記録（ログイン不要）
//

import Foundation

enum RunRecordSource: String, Codable, CaseIterable {
    /// GPS（地図）で記録
    case map
    /// ジム・トレッドミル（Running）
    case gymRunning
    /// ジム・トレッドミル（Walking）
    case gymWalking
}

struct RunRecord: Codable, Identifiable, Equatable {
    let id: UUID
    /// セッション終了（保存）時刻
    let endedAt: Date
    let distanceKm: Double
    let durationSeconds: TimeInterval
    let source: RunRecordSource
    /// ACSM式による推定消費カロリー（kcal）。体重未設定などで算出できない場合は nil
    var caloriesKcal: Double?
    /// Gymモード時のみ（任意）
    var treadmillInclineDegrees: Double?
    var treadmillSpeedKmh: Double?
}

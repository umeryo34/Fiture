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
    /// 旧バージョンの推定消費カロリー（kcal）。新規記録はヘルスケア連携のため nil
    var caloriesKcal: Double?
    /// Gymモード時のみ。トレッドミル勾配率（%）
    var treadmillInclinePercent: Double?
    var treadmillSpeedKmh: Double?

    enum CodingKeys: String, CodingKey {
        case id, endedAt, distanceKm, durationSeconds, source, caloriesKcal
        case treadmillInclinePercent
        case treadmillSpeedKmh
        case treadmillInclineDegrees
    }

    init(
        id: UUID,
        endedAt: Date,
        distanceKm: Double,
        durationSeconds: TimeInterval,
        source: RunRecordSource,
        caloriesKcal: Double?,
        treadmillInclinePercent: Double?,
        treadmillSpeedKmh: Double?
    ) {
        self.id = id
        self.endedAt = endedAt
        self.distanceKm = distanceKm
        self.durationSeconds = durationSeconds
        self.source = source
        self.caloriesKcal = caloriesKcal
        self.treadmillInclinePercent = treadmillInclinePercent
        self.treadmillSpeedKmh = treadmillSpeedKmh
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        distanceKm = try container.decode(Double.self, forKey: .distanceKm)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        source = try container.decode(RunRecordSource.self, forKey: .source)
        caloriesKcal = try container.decodeIfPresent(Double.self, forKey: .caloriesKcal)
        treadmillInclinePercent = try container.decodeIfPresent(Double.self, forKey: .treadmillInclinePercent)
            ?? container.decodeIfPresent(Double.self, forKey: .treadmillInclineDegrees)
        treadmillSpeedKmh = try container.decodeIfPresent(Double.self, forKey: .treadmillSpeedKmh)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(endedAt, forKey: .endedAt)
        try container.encode(distanceKm, forKey: .distanceKm)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(caloriesKcal, forKey: .caloriesKcal)
        try container.encodeIfPresent(treadmillInclinePercent, forKey: .treadmillInclinePercent)
        try container.encodeIfPresent(treadmillSpeedKmh, forKey: .treadmillSpeedKmh)
    }
}

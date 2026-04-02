import Foundation

/// 筋トレの「1回の記録」(date + 種目) に対して、各セットの重量/回数を保存するためのドメインモデル。
struct TrainingRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let date: Date
    let exerciseType: String
    var sets: [TrainingSetEntry]
    let createdAt: Date
    var updatedAt: Date
}

/// 重量/回数はユーザー入力の都合で文字列のまま保持する（後で数値化する）。
struct TrainingSetEntry: Codable, Equatable {
    var weight: String
    var reps: String
}


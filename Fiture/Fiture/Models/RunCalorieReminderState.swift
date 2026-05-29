//
//  RunCalorieReminderState.swift
//  Fiture
//

import Foundation

/// Run タブの吹き出し表示用（目標超過時）
@MainActor
final class RunCalorieReminderState: ObservableObject {
    @Published var isExcessActive = false
    @Published var excessKcal: Double?

    func apply(excessKcal: Double?) {
        self.excessKcal = excessKcal
        isExcessActive = excessKcal != nil
    }
}

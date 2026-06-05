//
//  RunCalorieReminderState.swift
//  Fiture
//

import Foundation

@MainActor
final class RunCalorieReminderState: ObservableObject {
    @Published var isExcessActive = false
    @Published var excessKcal: Double?

    func apply(excessKcal: Double?) {
        self.excessKcal = excessKcal
        isExcessActive = excessKcal != nil
    }
}

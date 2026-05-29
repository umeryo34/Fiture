//
//  RunViewModel.swift
//  Fiture
//

import Foundation

@MainActor
final class RunViewModel: ObservableObject {
    @Published var burnedCaloriesKcal: Double = 0
    @Published var isLoading = false

    private let caloriesTargetManager = CaloriesTargetManager()
    private weak var authManager: AuthManager?
    private weak var runReminder: RunCalorieReminderState?

    func configure(authManager: AuthManager, runReminder: RunCalorieReminderState) {
        self.authManager = authManager
        self.runReminder = runReminder
    }

    var dailyBalance: DailyCalorieBalance {
        DailyCalorieBalance(
            foodIntakeKcal: caloriesTargetManager.totalCalories,
            activeEnergyBurnedKcal: burnedCaloriesKcal,
            targetKcal: caloriesTargetManager.caloriesTarget?.target,
            weightKg: FitnessProfileStorage.load(userId: authManager?.currentUser?.id).weightKg
        )
    }

    var excessOverTargetKcal: Double? {
        dailyBalance.excessOverTargetKcal
    }

    func exercisePlan(
        gymWalkingSpeedKmh: Double,
        gymWalkingInclinePercent: Double
    ) -> ExcessBurnExercisePlan? {
        dailyBalance.exercisePlan(
            gymWalkingSpeedKmh: gymWalkingSpeedKmh,
            gymWalkingInclinePercent: gymWalkingInclinePercent
        )
    }

    func refreshToday() async {
        guard let userId = authManager?.currentUser?.id else {
            runReminder?.apply(excessKcal: nil)
            return
        }

        isLoading = true
        defer { isLoading = false }

        let today = Date()
        async let fetchEntries = caloriesTargetManager.fetchCaloriesEntries(userId: userId, date: today)
        async let fetchTarget = caloriesTargetManager.fetchCaloriesTarget(userId: userId, date: today)
        try? await fetchEntries
        try? await fetchTarget
        await fetchBurnedCaloriesFromHealth(for: today)

        runReminder?.apply(excessKcal: excessOverTargetKcal)
    }

    private func fetchBurnedCaloriesFromHealth(for date: Date) async {
        guard HealthKitCalorieService.shared.isAvailable else {
            burnedCaloriesKcal = 0
            return
        }
        do {
            try await HealthKitCalorieService.shared.requestAuthorization()
            burnedCaloriesKcal = try await HealthKitCalorieService.shared.activeEnergyBurnedKcal(on: date)
        } catch {
            burnedCaloriesKcal = 0
        }
    }
}

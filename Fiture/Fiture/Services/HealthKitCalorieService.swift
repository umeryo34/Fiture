//
//  HealthKitCalorieService.swift
//  Fiture
//

import Foundation
import HealthKit

enum HealthKitCalorieError: LocalizedError {
    case notAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "この端末ではヘルスケアを利用できません。"
        case .authorizationDenied:
            return "ヘルスケアの読み取りが許可されていません。設定アプリから許可してください。"
        }
    }
}

@MainActor
final class HealthKitCalorieService {
    static let shared = HealthKitCalorieService()

    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var activeEnergyType: HKQuantityType {
        HKQuantityType(.activeEnergyBurned)
    }

    private var distanceType: HKQuantityType {
        HKQuantityType(.distanceWalkingRunning)
    }

    private var typesToRead: Set<HKObjectType> {
        [activeEnergyType, HKObjectType.workoutType()]
    }

    private var typesToShare: Set<HKSampleType> {
        [activeEnergyType, HKObjectType.workoutType(), distanceType]
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitCalorieError.notAvailable }
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    /// 指定日（ローカル暦）のアクティブエネルギー合計（kcal）
    func activeEnergyBurnedKcal(on date: Date) async throws -> Double {
        guard isAvailable else { throw HealthKitCalorieError.notAvailable }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: max(0, kcal))
            }
            healthStore.execute(query)
        }
    }

    /// Gymセッションをヘルスケアのワークアウトとして保存（屋内トレッドミル想定）
    func saveIndoorWorkout(
        activity: HKWorkoutActivityType,
        start: Date,
        end: Date,
        distanceMeters: Double
    ) async throws {
        guard isAvailable else { throw HealthKitCalorieError.notAvailable }
        guard end > start else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        try await performWorkoutBuilderAction { completion in
            builder.beginCollection(withStart: start, completion: completion)
        }

        if distanceMeters > 0 {
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distanceMeters)
            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity,
                start: start,
                end: end
            )
            try await performWorkoutBuilderAction { completion in
                builder.add([distanceSample], completion: completion)
            }
        }

        try await performWorkoutBuilderAction { completion in
            builder.endCollection(withEnd: end, completion: completion)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func performWorkoutBuilderAction(
        _ action: (@escaping (Bool, Error?) -> Void) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitCalorieError.authorizationDenied)
                }
            }
        }
    }
}

//
//  LocalDataStore.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/23.
//

import Foundation

enum LocalDataStoreError: LocalizedError {
    case emailAlreadyExists
    case invalidCredentials
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .emailAlreadyExists:
            return "このメールアドレスは既に登録されています"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .userNotFound:
            return "ユーザー情報が見つかりません"
        }
    }
}

final class LocalDataStore {
    static let shared = LocalDataStore()

    private let stateKey = "fiture_local_state_v1"
    private let sessionUserIdKey = "fiture_local_session_user_id"
    private let guestUserIdKey = "fiture_local_guest_user_id"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Public auth

    func register(name: String, email: String, password: String) throws -> User {
        var state = loadState()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if state.users.contains(where: { $0.email.lowercased() == normalizedEmail }) {
            throw LocalDataStoreError.emailAlreadyExists
        }

        let now = Date()
        let user = LocalUser(
            id: UUID(),
            name: name,
            email: normalizedEmail,
            password: password,
            profileImageUrl: nil,
            createdAt: now,
            updatedAt: now
        )
        state.users.append(user)
        saveState(state)
        UserDefaults.standard.set(user.id.uuidString, forKey: sessionUserIdKey)
        return user.toDomain()
    }

    func login(email: String, password: String) throws -> User {
        let state = loadState()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let user = state.users.first(where: { $0.email.lowercased() == normalizedEmail && $0.password == password }) else {
            throw LocalDataStoreError.invalidCredentials
        }
        UserDefaults.standard.set(user.id.uuidString, forKey: sessionUserIdKey)
        return user.toDomain()
    }

    func currentUser() -> User? {
        guard let session = UserDefaults.standard.string(forKey: sessionUserIdKey),
              let userId = UUID(uuidString: session) else {
            return nil
        }
        return loadState().users.first(where: { $0.id == userId })?.toDomain()
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: sessionUserIdKey)
    }

    func ensureGuestSession() -> User {
        var state = loadState()
        let guestId: UUID
        if let raw = UserDefaults.standard.string(forKey: guestUserIdKey),
           let parsed = UUID(uuidString: raw) {
            guestId = parsed
        } else {
            guestId = UUID()
            UserDefaults.standard.set(guestId.uuidString, forKey: guestUserIdKey)
        }

        let now = Date()
        if let index = state.users.firstIndex(where: { $0.id == guestId }) {
            state.users[index].updatedAt = now
            state.users[index].name = "ゲストユーザー"
        } else {
            state.users.append(
                LocalUser(
                    id: guestId,
                    name: "ゲストユーザー",
                    email: "guest@local",
                    password: "",
                    profileImageUrl: nil,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        saveState(state)
        UserDefaults.standard.set(guestId.uuidString, forKey: sessionUserIdKey)
        return state.users.first(where: { $0.id == guestId })!.toDomain()
    }

    func updateUser(userId: UUID, name: String, email: String, profileImageUrl: String?) throws -> User {
        var state = loadState()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let index = state.users.firstIndex(where: { $0.id == userId }) else {
            throw LocalDataStoreError.userNotFound
        }

        if state.users.contains(where: { $0.id != userId && $0.email.lowercased() == normalizedEmail }) {
            throw LocalDataStoreError.emailAlreadyExists
        }

        state.users[index].name = name
        state.users[index].email = normalizedEmail
        state.users[index].profileImageUrl = profileImageUrl
        state.users[index].updatedAt = Date()
        let updated = state.users[index]
        saveState(state)
        return updated.toDomain()
    }

    // MARK: - Run

    func runTarget(userId: UUID, date: Date) -> RunTarget? {
        let targetDate = startOfDay(date)
        return loadState().runTargets.first(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) })?.toDomain()
    }

    func upsertRunTarget(userId: UUID, date: Date, target: Double? = nil, attempt: Double? = nil) -> RunTarget {
        var state = loadState()
        let targetDate = startOfDay(date)
        let now = Date()
        if let index = state.runTargets.firstIndex(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            if let target { state.runTargets[index].target = target }
            if let attempt { state.runTargets[index].attempt = attempt }
            state.runTargets[index].isAchieved = state.runTargets[index].attempt >= state.runTargets[index].target
            state.runTargets[index].updatedAt = now
            let value = state.runTargets[index]
            saveState(state)
            return value.toDomain()
        }

        let value = LocalRunTarget(
            userId: userId,
            date: targetDate,
            target: target ?? 0,
            attempt: attempt ?? 0,
            isAchieved: (attempt ?? 0) >= (target ?? 0),
            createdAt: now,
            updatedAt: now
        )
        state.runTargets.append(value)
        saveState(state)
        return value.toDomain()
    }

    func deleteRunTarget(userId: UUID, date: Date) {
        var state = loadState()
        let targetDate = startOfDay(date)
        state.runTargets.removeAll { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
        saveState(state)
    }

    // MARK: - Run records（端末ローカル・ユーザー紐付けなし）

    func addRunRecord(
        distanceKm: Double,
        durationSeconds: TimeInterval,
        source: RunRecordSource,
        caloriesKcal: Double? = nil,
        treadmillInclineDegrees: Double? = nil,
        treadmillSpeedKmh: Double? = nil
    ) -> RunRecord {
        var state = loadState()
        let now = Date()
        let local = LocalRunRecord(
            id: UUID(),
            endedAt: now,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            source: source.rawValue,
            caloriesKcal: caloriesKcal,
            treadmillInclineDegrees: treadmillInclineDegrees,
            treadmillSpeedKmh: treadmillSpeedKmh
        )
        state.runRecords.append(local)
        saveState(state)
        return local.toDomain()
    }

    /// 新しい順
    func runRecords() -> [RunRecord] {
        loadState().runRecords
            .sorted { $0.endedAt > $1.endedAt }
            .map { $0.toDomain() }
    }

    /// 指定日（ローカル日付）に保存した Run の消費カロリー合計。`caloriesKcal` が nil の記録は 0 扱い。
    func runBurnedCaloriesKcal(on date: Date) -> Double {
        let day = startOfDay(date)
        return loadState().runRecords
            .filter { Calendar.current.isDate($0.endedAt, inSameDayAs: day) }
            .reduce(0) { $0 + ($1.caloriesKcal ?? 0) }
    }

    // MARK: - Weight

    func weightEntry(userId: UUID, date: Date) -> WeightEntry? {
        let targetDate = startOfDay(date)
        return loadState().weightEntries.first(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) })?.toDomain()
    }

    func upsertWeightEntry(userId: UUID, date: Date, weight: Double) -> WeightEntry {
        var state = loadState()
        let targetDate = startOfDay(date)
        let now = Date()

        if let index = state.weightEntries.firstIndex(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            state.weightEntries[index].weight = weight
            state.weightEntries[index].updatedAt = now
            let value = state.weightEntries[index]
            saveState(state)
            return value.toDomain()
        }

        state.nextWeightEntryId += 1
        let newEntry = LocalWeightEntry(
            id: state.nextWeightEntryId,
            userId: userId,
            date: targetDate,
            weight: weight,
            createdAt: now,
            updatedAt: now
        )
        state.weightEntries.append(newEntry)
        saveState(state)
        return newEntry.toDomain()
    }

    func deleteWeightEntry(userId: UUID, date: Date) {
        var state = loadState()
        let targetDate = startOfDay(date)
        state.weightEntries.removeAll { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
        saveState(state)
    }

    func latestWeight(userId: UUID) -> WeightEntry? {
        let entries = loadState().weightEntries
            .filter { $0.userId == userId }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.createdAt > rhs.createdAt
            }
        return entries.first?.toDomain()
    }

    func weightEntries(userId: UUID, days: Int) -> [WeightEntry] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        return loadState().weightEntries
            .filter { $0.userId == userId && $0.date >= startOfDay(start) }
            .sorted { $0.date < $1.date }
            .map { $0.toDomain() }
    }

    // MARK: - Calories

    func caloriesEntries(userId: UUID, date: Date) -> [CaloriesEntry] {
        let targetDate = startOfDay(date)
        return loadState().caloriesEntries
            .filter { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
            .sorted { $0.createdAt > $1.createdAt }
            .map { $0.toDomain() }
    }

    func addCaloriesEntry(userId: UUID, date: Date, foodName: String, calories: Double, protein: Double?, fat: Double?, carbs: Double?) -> CaloriesEntry {
        var state = loadState()
        state.nextCaloriesEntryId += 1
        let value = LocalCaloriesEntry(
            id: state.nextCaloriesEntryId,
            userId: userId,
            date: startOfDay(date),
            foodName: foodName,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            createdAt: Date()
        )
        state.caloriesEntries.append(value)
        saveState(state)
        return value.toDomain()
    }

    func deleteCaloriesEntry(entryId: Int, userId: UUID) {
        var state = loadState()
        state.caloriesEntries.removeAll { $0.id == entryId && $0.userId == userId }
        saveState(state)
    }

    func caloriesTarget(userId: UUID, date: Date) -> CaloriesTarget? {
        let targetDate = startOfDay(date)
        return loadState().caloriesTargets.first(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) })?.toDomain()
    }

    /// 選択日に行がなければ、同一ユーザーの過去最新の目標を使う。保存が1件もなければ基本情報（TDEE）から推定（永続化しない）。
    func resolvedCaloriesTarget(userId: UUID, date: Date) -> CaloriesTarget? {
        let targetDate = startOfDay(date)
        let all = loadState().caloriesTargets.filter { $0.userId == userId }
        if let exact = all.first(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            return exact.toDomain()
        }
        let onOrBefore = all.filter { $0.date <= targetDate }.sorted { $0.date < $1.date }
        if let row = onOrBefore.last {
            return row.toDomain()
        }
        if let row = all.sorted(by: { $0.date < $1.date }).last {
            return row.toDomain()
        }
        let profile = FitnessProfileStorage.load(userId: userId)
        if let result = CalorieCalculator.calculate(profile: profile, userId: userId, referenceDate: targetDate) {
            let now = Date()
            return CaloriesTarget(
                userId: userId,
                date: targetDate,
                target: result.targetCalories.rounded(),
                createdAt: now,
                updatedAt: now
            )
        }
        return nil
    }

    func upsertCaloriesTarget(userId: UUID, date: Date, target: Double) -> CaloriesTarget {
        var state = loadState()
        let targetDate = startOfDay(date)
        let now = Date()
        if let index = state.caloriesTargets.firstIndex(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            state.caloriesTargets[index].target = target
            state.caloriesTargets[index].updatedAt = now
            let value = state.caloriesTargets[index]
            saveState(state)
            return value.toDomain()
        }

        let value = LocalCaloriesTarget(userId: userId, date: targetDate, target: target, createdAt: now, updatedAt: now)
        state.caloriesTargets.append(value)
        saveState(state)
        return value.toDomain()
    }

    func deleteCaloriesTarget(userId: UUID, date: Date) {
        var state = loadState()
        let targetDate = startOfDay(date)
        state.caloriesTargets.removeAll { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
        saveState(state)
    }

    func caloriesHistory(userId: UUID, days: Int) -> [(date: Date, totalCalories: Double)] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let df = dateFormatter
        var totalsByDay: [String: Double] = [:]
        for item in loadState().caloriesEntries where item.userId == userId && item.date >= startOfDay(startDate) && item.date <= startOfDay(endDate) {
            let key = df.string(from: item.date)
            totalsByDay[key, default: 0] += item.calories
        }

        var result: [(date: Date, totalCalories: Double)] = []
        var cursor = startOfDay(startDate)
        while cursor <= startOfDay(endDate) {
            let key = df.string(from: cursor)
            result.append((date: cursor, totalCalories: totalsByDay[key] ?? 0))
            cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return result
    }

    func searchCaloriesEntries(userId: UUID, keyword: String, startDate: Date, endDate: Date) -> [CaloriesEntry] {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        let start = startOfDay(startDate)
        let end = startOfDay(endDate)
        return loadState().caloriesEntries
            .filter { $0.userId == userId && $0.date >= start && $0.date <= end && $0.foodName.lowercased().contains(query) }
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.createdAt > $1.createdAt
            }
            .map { $0.toDomain() }
    }

    // MARK: - Training

    func trainingTargets(userId: UUID, date: Date) -> [TrainingTarget] {
        let targetDate = startOfDay(date)
        return loadState().trainingTargets
            .filter { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.toDomain() }
    }

    func trainingTarget(userId: UUID, date: Date, exerciseType: String) -> TrainingTarget? {
        let targetDate = startOfDay(date)
        return loadState().trainingTargets
            .first { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) && $0.exerciseType == exerciseType }?
            .toDomain()
    }

    func upsertTrainingTarget(userId: UUID, date: Date, exerciseType: String, target: Double? = nil, attempt: Double? = nil) -> TrainingTarget {
        var state = loadState()
        let targetDate = startOfDay(date)
        let now = Date()
        if let index = state.trainingTargets.firstIndex(where: { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) && $0.exerciseType == exerciseType }) {
            if let target { state.trainingTargets[index].target = target }
            if let attempt { state.trainingTargets[index].attempt = attempt }
            state.trainingTargets[index].isAchieved = state.trainingTargets[index].attempt >= state.trainingTargets[index].target
            state.trainingTargets[index].updatedAt = now
            let value = state.trainingTargets[index]
            saveState(state)
            return value.toDomain()
        }

        let value = LocalTrainingTarget(
            userId: userId,
            date: targetDate,
            exerciseType: exerciseType,
            target: target ?? 0,
            attempt: attempt ?? 0,
            isAchieved: (attempt ?? 0) >= (target ?? 0),
            createdAt: now,
            updatedAt: now
        )
        state.trainingTargets.append(value)
        saveState(state)
        return value.toDomain()
    }

    func deleteTrainingTarget(userId: UUID, date: Date, exerciseType: String) {
        var state = loadState()
        let targetDate = startOfDay(date)
        state.trainingTargets.removeAll {
            $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) && $0.exerciseType == exerciseType
        }
        saveState(state)
    }

    func trainingTags(userId: UUID) -> [TrainingTag] {
        loadState().trainingTags
            .filter { $0.userId == userId }
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.toDomain() }
    }

    func createTrainingTag(userId: UUID, tagName: String) -> TrainingTag {
        var state = loadState()
        let now = Date()
        let value = LocalTrainingTag(id: UUID(), userId: userId, tagName: tagName, createdAt: now, updatedAt: now)
        state.trainingTags.append(value)
        saveState(state)
        return value.toDomain()
    }

    func deleteTrainingTag(userId: UUID, tagId: UUID) {
        var state = loadState()
        state.trainingTags.removeAll { $0.userId == userId && $0.id == tagId }
        saveState(state)
    }

    // MARK: - Training Record (セットの重量/回数)

    func trainingRecord(userId: UUID, date: Date, exerciseType: String) -> TrainingRecord? {
        let targetDate = startOfDay(date)
        return loadState().trainingRecords
            .first { $0.userId == userId && Calendar.current.isDate($0.date, inSameDayAs: targetDate) && $0.exerciseType == exerciseType }?
            .toDomain()
    }

    func trainingRecords(userId: UUID, exerciseType: String) -> [TrainingRecord] {
        loadState().trainingRecords
            .filter { $0.userId == userId && $0.exerciseType == exerciseType }
            .sorted { (lhs, rhs) in
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.updatedAt > rhs.updatedAt
            }
            .map { $0.toDomain() }
    }

    func upsertTrainingRecord(
        userId: UUID,
        date: Date,
        exerciseType: String,
        sets: [TrainingSetEntry]
    ) -> TrainingRecord {
        var state = loadState()
        let targetDate = startOfDay(date)
        let now = Date()

        let localSets = sets.map { LocalTrainingSet(weight: $0.weight, reps: $0.reps) }

        if let index = state.trainingRecords.firstIndex(where: {
            $0.userId == userId &&
            Calendar.current.isDate($0.date, inSameDayAs: targetDate) &&
            $0.exerciseType == exerciseType
        }) {
            state.trainingRecords[index].sets = localSets
            state.trainingRecords[index].updatedAt = now
            let value = state.trainingRecords[index]
            saveState(state)
            return value.toDomain()
        }

        let newRecord = LocalTrainingRecord(
            id: UUID(),
            userId: userId,
            date: targetDate,
            exerciseType: exerciseType,
            sets: localSets,
            createdAt: now,
            updatedAt: now
        )
        state.trainingRecords.append(newRecord)
        saveState(state)
        return newRecord.toDomain()
    }

    // MARK: - Private

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func loadState() -> LocalAppState {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let decoded = try? decoder.decode(LocalAppState.self, from: data) else {
            return LocalAppState()
        }
        return decoded
    }

    private func saveState(_ state: LocalAppState) {
        guard let data = try? encoder.encode(state) else { return }
        UserDefaults.standard.set(data, forKey: stateKey)
    }
}

private struct LocalAppState: Codable {
    var users: [LocalUser] = []
    var runTargets: [LocalRunTarget] = []
    var runRecords: [LocalRunRecord] = []
    var weightEntries: [LocalWeightEntry] = []
    var caloriesEntries: [LocalCaloriesEntry] = []
    var caloriesTargets: [LocalCaloriesTarget] = []
    var trainingTargets: [LocalTrainingTarget] = []
    var trainingTags: [LocalTrainingTag] = []
    var trainingRecords: [LocalTrainingRecord] = []
    var nextWeightEntryId: Int = 0
    var nextCaloriesEntryId: Int = 0
}

private struct LocalUser: Codable {
    let id: UUID
    var name: String
    var email: String
    var password: String
    var profileImageUrl: String?
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> User {
        User(id: id, name: name, email: email, profileImageUrl: profileImageUrl, createdAt: createdAt, updatedAt: updatedAt)
    }
}

private struct LocalRunTarget: Codable {
    let userId: UUID
    let date: Date
    var target: Double
    var attempt: Double
    var isAchieved: Bool
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> RunTarget {
        RunTarget(userId: userId, date: date, target: target, attempt: attempt, isAchieved: isAchieved, createdAt: createdAt, updatedAt: updatedAt)
    }
}

private struct LocalRunRecord: Codable {
    let id: UUID
    let endedAt: Date
    let distanceKm: Double
    let durationSeconds: TimeInterval
    let source: String
    var caloriesKcal: Double?
    let treadmillInclineDegrees: Double?
    let treadmillSpeedKmh: Double?

    func toDomain() -> RunRecord {
        RunRecord(
            id: id,
            endedAt: endedAt,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            source: RunRecordSource(rawValue: source) ?? .map,
            caloriesKcal: caloriesKcal,
            treadmillInclineDegrees: treadmillInclineDegrees,
            treadmillSpeedKmh: treadmillSpeedKmh
        )
    }
}

private struct LocalWeightEntry: Codable {
    let id: Int
    let userId: UUID
    let date: Date
    var weight: Double
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> WeightEntry {
        WeightEntry(id: id, userId: userId, date: date, weight: weight, createdAt: createdAt, updatedAt: updatedAt)
    }
}

private struct LocalCaloriesEntry: Codable {
    let id: Int
    let userId: UUID
    let date: Date
    let foodName: String
    let calories: Double
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let createdAt: Date

    func toDomain() -> CaloriesEntry {
        CaloriesEntry(id: id, userId: userId, date: date, foodName: foodName, calories: calories, protein: protein, fat: fat, carbs: carbs, createdAt: createdAt)
    }
}

private struct LocalCaloriesTarget: Codable {
    let userId: UUID
    let date: Date
    var target: Double
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> CaloriesTarget {
        CaloriesTarget(userId: userId, date: date, target: target, createdAt: createdAt, updatedAt: updatedAt)
    }
}

private struct LocalTrainingTarget: Codable {
    let userId: UUID
    let date: Date
    let exerciseType: String
    var target: Double
    var attempt: Double
    var isAchieved: Bool
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> TrainingTarget {
        TrainingTarget(
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            target: target,
            attempt: attempt,
            isAchieved: isAchieved,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct LocalTrainingRecord: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let exerciseType: String
    var sets: [LocalTrainingSet]
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> TrainingRecord {
        TrainingRecord(
            id: id,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            sets: sets.map { $0.toDomain() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct LocalTrainingSet: Codable {
    var weight: String
    var reps: String

    func toDomain() -> TrainingSetEntry {
        TrainingSetEntry(weight: weight, reps: reps)
    }
}

private struct LocalTrainingTag: Codable {
    let id: UUID
    let userId: UUID
    let tagName: String
    let createdAt: Date
    var updatedAt: Date

    func toDomain() -> TrainingTag {
        TrainingTag(id: id, userId: userId, tagName: tagName, createdAt: createdAt, updatedAt: updatedAt)
    }
}

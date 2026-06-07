import SwiftUI
import HealthKit

/// Gymモード（屋内トレッドミル）。記録はローカルに保存し、ワークアウトはヘルスケアへ書き込む。
struct RunGymView: View {
    enum MotionType: String, CaseIterable, Identifiable {
        case running = "Running"
        case walking = "Walking"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var motion: MotionType = .running
    @State private var inclinePercent: Double = 0
    @State private var speedKmPerHour: Double = 8

    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    @State private var totalDistanceKm: Double = 0

    @State private var showingSaveConfirmation = false
    @State private var showingCompletedMessage = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    private var currentDistanceKm: Double {
        guard speedKmPerHour > 0 else { return 0 }
        return speedKmPerHour * (elapsedTime / 3600.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("種目", selection: $motion) {
                    ForEach(MotionType.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: motion) { newValue in
                    guard !isRunning else { return }
                    switch newValue {
                    case .walking:
                        speedKmPerHour = 5
                    case .running:
                        speedKmPerHour = 8
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("傾斜: \(Int(inclinePercent))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Slider(value: $inclinePercent, in: 0...15, step: 1)
                        .disabled(isRunning)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("スピード: \(String(format: "%.1f", speedKmPerHour)) km/h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Slider(value: $speedKmPerHour, in: 1...18, step: 0.5)
                        .disabled(isRunning)
                }

                Text("消費カロリーはヘルスケアのアクティブエネルギーから読み込みます（Homeの収支に反映）。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            VStack(spacing: 15) {
                HStack(spacing: 40) {
                    VStack {
                        Text(String(format: "%.2f", isRunning ? currentDistanceKm : totalDistanceKm))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.red)
                        Text("km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.red)
                        Text("時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if isRunning {
                    HStack(spacing: 12) {
                        Button(action: pauseGym) {
                            HStack {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 18))
                                Text("中断")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }

                        Button(action: endGym) {
                            HStack {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 18))
                                Text("終了")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    Button(action: resumeOrStartGym) {
                        HStack {
                            Image(systemName: elapsedTime > 0 ? "play.circle.fill" : "play.fill")
                                .font(.system(size: 20))
                            Text(elapsedTime > 0 ? "再開" : "開始")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .task {
            try? await HealthKitCalorieService.shared.requestAuthorization()
        }
        .alert("Gymを保存", isPresented: $showingSaveConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("保存") {
                Task { await saveGym() }
            }
        } message: {
            Text(saveConfirmationMessage)
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("お疲れ様でした！", isPresented: $showingCompletedMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Runを保存しました。消費カロリーはヘルスケアに反映されます。")
        }
    }

    private func startGym() {
        isRunning = true
        startTime = Date()
        elapsedTime = 0
        totalDistanceKm = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let start = startTime else { return }
            elapsedTime = Date().timeIntervalSince(start)
        }
    }

    private func resumeOrStartGym() {
        if elapsedTime > 0 {
            resumeGym()
        } else {
            startGym()
        }
    }

    private func resumeGym() {
        isRunning = true
        startTime = Date().addingTimeInterval(-elapsedTime)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let start = startTime else { return }
            elapsedTime = Date().timeIntervalSince(start)
        }
    }

    private func pauseGym() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        totalDistanceKm = currentDistanceKm
    }

    private func endGym() {
        pauseGym()
        showingSaveConfirmation = true
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var saveConfirmationMessage: String {
        [
            "距離: \(String(format: "%.2f", totalDistanceKm)) km",
            "時間: \(formatTime(elapsedTime))",
            "ヘルスケアにワークアウトとして保存します。"
        ].joined(separator: "\n")
    }

    @MainActor
    private func saveGym() async {
        guard totalDistanceKm > 0 else {
            errorMessage = "距離が0です。Runを記録できません。"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        let end = Date()
        let start = end.addingTimeInterval(-elapsedTime)
        let activity: HKWorkoutActivityType = motion == .running ? .running : .walking

        do {
            try await HealthKitCalorieService.shared.requestAuthorization()
            try await HealthKitCalorieService.shared.saveIndoorWorkout(
                activity: activity,
                start: start,
                end: end,
                distanceMeters: totalDistanceKm * 1000
            )
        } catch {
            errorMessage = "ヘルスケアへの保存に失敗しました: \(error.localizedDescription)"
            showError = true
            return
        }

        let source: RunRecordSource = motion == .running ? .gymRunning : .gymWalking
        _ = LocalDataStore.shared.addRunRecord(
            distanceKm: totalDistanceKm,
            durationSeconds: elapsedTime,
            source: source,
            caloriesKcal: nil,
            treadmillInclinePercent: inclinePercent,
            treadmillSpeedKmh: speedKmPerHour
        )
        NotificationCenter.default.post(name: .runRecordDidSave, object: nil)
        resetGymSessionState()
        showingCompletedMessage = true
    }

    private func resetGymSessionState() {
        isRunning = false
        startTime = nil
        elapsedTime = 0
        totalDistanceKm = 0
        timer?.invalidate()
        timer = nil
    }
}

extension Notification.Name {
    static let runRecordDidSave = Notification.Name("RunRecordDidSave")
}

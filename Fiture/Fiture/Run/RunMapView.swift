//
//  RunMapView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/12/11.
//

import SwiftUI
import MapKit

struct RunMapView: View {
    @Environment(\.dismiss) private var dismiss
    // 東京の座標をデフォルトに設定
    private let defaultLocation = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京の座標（デフォルト）
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var hasInitialLocation = false
    @StateObject private var locationManager = RunLocationManager()
    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingSaveConfirmation = false
    @State private var showingCompletedMessage = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var userTrackingMode: MapUserTrackingMode = .none

    /// セッション平均速度（km/h）。屋外は傾斜0として ACSM を適用。
    private var mapAverageSpeedKmh: Double {
        guard elapsedTime > 0 else { return 0 }
        let km = locationManager.totalDistance / 1000.0
        return km / (elapsedTime / 3600.0)
    }

    private var mapEstimatedCaloriesKcal: Double? {
        guard let weight = RunCalorieProfile.weightKg(),
              elapsedTime > 0,
              mapAverageSpeedKmh > 0 else { return nil }
        let kind = ACSMRunCalorieCalculator.mapActivityKind(averageSpeedKmh: mapAverageSpeedKmh)
        return ACSMRunCalorieCalculator.totalCalories(
            weightKg: weight,
            speedKmh: mapAverageSpeedKmh,
            gradeDecimal: 0,
            durationSeconds: elapsedTime,
            kind: kind
        )
    }

    var body: some View {
        ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: $userTrackingMode)
                    .onAppear {
                        setupLocation()
                    }
                    .onReceive(locationManager.$location) { newLocation in
                        if let location = newLocation {
                            // 位置情報が取得できた場合のみ更新
                            if !hasInitialLocation {
                                // 日本周辺の座標かチェック
                                let isJapanArea = location.latitude >= 24.0 && location.latitude <= 46.0 &&
                                                  location.longitude >= 122.0 && location.longitude <= 146.0
                                
                                if isJapanArea {
                                    updateRegion(to: location)
                                    hasInitialLocation = true
                                } else {
                                    // 海外の場合は東京を表示（シミュレーターの場合など）
                                    print("位置情報が日本以外です。デフォルト位置（東京）を表示します。")
                                    updateRegion(to: defaultLocation)
                                    hasInitialLocation = true
                                }
                            }
                            if isRunning {
                                locationManager.addLocation(location)
                            }
                        }
                    }
                
                // 位置情報許可状態の表示
                if !locationManager.isAuthorized {
                    VStack(spacing: 15) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("位置情報の許可が必要です")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Runを記録するために位置情報の使用を許可してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            locationManager.requestAuthorization()
                        }) {
                            Text("位置情報を許可")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.95))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                } else if !hasInitialLocation && !isRunning {
                    // 位置情報取得中のインジケーター
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("現在地を取得中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(10)
                }
                
                // ランニング情報オーバーレイ
                VStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // 距離と時間の表示
                        HStack(spacing: 20) {
                            VStack {
                                Text(String(format: "%.2f", locationManager.totalDistance / 1000.0))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack {
                                Text(formatTime(elapsedTime))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack {
                                if let kcal = mapEstimatedCaloriesKcal {
                                    Text(String(format: "%.0f", kcal))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.orange)
                                    Text("kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("—")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text("kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.95))
                        .cornerRadius(15)
                        .shadow(radius: 5)

                        if RunCalorieProfile.weightKg() == nil {
                            Text("消費カロリーはプロフィールの体重が必要です")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        if isRunning {
                            HStack(spacing: 12) {
                                Button(action: {
                                    pauseRun()
                                }) {
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

                                Button(action: {
                                    endRun()
                                }) {
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
                            .padding(.horizontal)
                        } else {
                            Button(action: {
                                resumeOrStartRun()
                            }) {
                                HStack {
                                    Image(systemName: elapsedTime > 0 ? "play.circle.fill" : "play.fill")
                                        .font(.system(size: 20))
                                    Text(elapsedTime > 0 ? "再開" : "開始")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .alert("Runを保存", isPresented: $showingSaveConfirmation) {
                Button("キャンセル", role: .cancel) { }
                Button("保存") {
                    saveRun()
                }
            } message: {
                Text(mapSaveConfirmationMessage)
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
                Text("Runを保存しました。")
            }
    }
    
    private func setupLocation() {
        // まずデフォルト位置（東京）を表示
        updateRegion(to: defaultLocation)
        // その後、位置情報の取得を開始
        locationManager.startUpdatingLocation()
    }
    
    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        // 座標が有効かチェック（緯度: -90〜90、経度: -180〜180）
        guard coordinate.latitude >= -90 && coordinate.latitude <= 90,
              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
            print("無効な座標です: \(coordinate)")
            return
        }
        
        // 日本周辺の座標かチェック（大まかな範囲）
        let isJapanArea = coordinate.latitude >= 24.0 && coordinate.latitude <= 46.0 &&
                          coordinate.longitude >= 122.0 && coordinate.longitude <= 146.0
        
        // 日本周辺でない場合は、デフォルト位置（東京）を使用
        let locationToUse = isJapanArea ? coordinate : defaultLocation
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: locationToUse,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func startRun() {
        isRunning = true
        startTime = Date()
        elapsedTime = 0
        userTrackingMode = .follow
        locationManager.startRun()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func resumeOrStartRun() {
        if elapsedTime > 0 {
            resumeRun()
        } else {
            startRun()
        }
    }

    private func resumeRun() {
        isRunning = true
        startTime = Date().addingTimeInterval(-elapsedTime)
        userTrackingMode = .follow
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func pauseRun() {
        isRunning = false
        userTrackingMode = .none
        timer?.invalidate()
        timer = nil
    }

    private func endRun() {
        pauseRun()
        locationManager.stopRun()
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
    
    private var mapSaveConfirmationMessage: String {
        let km = locationManager.totalDistance / 1000.0
        var lines = [
            "距離: \(String(format: "%.2f", km)) km",
            "時間: \(formatTime(elapsedTime))"
        ]
        if let kcal = mapEstimatedCaloriesKcal {
            lines.append("消費カロリー（推定）: \(String(format: "%.0f", kcal)) kcal")
        }
        if mapAverageSpeedKmh > 0 {
            lines.append(String(format: "平均ペース: %.1f km/h（6未満=歩行式）", mapAverageSpeedKmh))
        }
        return lines.joined(separator: "\n")
    }

    private func saveRun() {
        guard locationManager.totalDistance > 0 else {
            errorMessage = "距離が0です。Runを記録できません。"
            showError = true
            return
        }
        
        isLoading = true
        let distanceInKm = locationManager.totalDistance / 1000.0

        _ = LocalDataStore.shared.addRunRecord(
            distanceKm: distanceInKm,
            durationSeconds: elapsedTime,
            source: .map,
            caloriesKcal: mapEstimatedCaloriesKcal
        )
        NotificationCenter.default.post(name: .init("RunRecordDidSave"), object: nil)

        isLoading = false
        resetRunSessionState()
        showingCompletedMessage = true
    }

    private func resetRunSessionState() {
        isRunning = false
        startTime = nil
        elapsedTime = 0
        timer?.invalidate()
        timer = nil
        userTrackingMode = .none
    }
}

// ランニング用の位置情報管理クラス
class RunLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var isAuthorized = false
    @Published var totalDistance: Double = 0.0 // メートル単位
    
    private var locations: [CLLocation] = []
    private var isRunning = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 5メートルごとに更新（ランニング用）
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            isAuthorized = false
            print("位置情報の使用が許可されていません")
        @unknown default:
            break
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func startRun() {
        isRunning = true
        locations.removeAll()
        totalDistance = 0.0
    }
    
    func stopRun() {
        isRunning = false
    }
    
    func addLocation(_ coordinate: CLLocationCoordinate2D) {
        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        if let lastLocation = locations.last {
            let distance = newLocation.distance(from: lastLocation)
            totalDistance += distance
        }
        
        locations.append(newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                isAuthorized = false
            case .locationUnknown:
                print("位置情報が不明です")
            default:
                break
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorizationStatus()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            isAuthorized = false
        default:
            break
        }
    }
}

#Preview {
    NavigationView {
        RunMapView()
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.inline)
    }
}

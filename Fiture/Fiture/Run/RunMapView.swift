//
//  RunMapView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/12/11.
//

import SwiftUI
import MapKit

struct RunMapView: View {
    let runTarget: RunTarget
    let runTargetManager: RunTargetManager
    let userId: UUID
    
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
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var userTrackingMode: MapUserTrackingMode = .none
    
    var body: some View {
        NavigationView {
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
                        HStack(spacing: 30) {
                            VStack {
                                Text(String(format: "%.2f", locationManager.totalDistance / 1000.0))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(formatTime(elapsedTime))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.95))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        
                        // 開始/停止ボタン
                        Button(action: {
                            if isRunning {
                                stopRun()
                            } else {
                                startRun()
                            }
                        }) {
                            HStack {
                                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                                    .font(.system(size: 20))
                                Text(isRunning ? "停止" : "開始")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRunning ? Color.red : Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Run記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        if isRunning {
                            stopRun()
                        }
                        dismiss()
                    }
                }
            }
            .alert("Runを保存", isPresented: $showingSaveConfirmation) {
                Button("キャンセル", role: .cancel) { }
                Button("保存") {
                    saveRun()
                }
            } message: {
                Text("距離: \(String(format: "%.2f", locationManager.totalDistance / 1000.0)) km\n時間: \(formatTime(elapsedTime))")
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
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
        userTrackingMode = .follow
        locationManager.startRun()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopRun() {
        isRunning = false
        userTrackingMode = .none
        timer?.invalidate()
        timer = nil
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
    
    private func saveRun() {
        guard locationManager.totalDistance > 0 else {
            errorMessage = "距離が0です。Runを記録できません。"
            showError = true
            return
        }
        
        isLoading = true
        let distanceInKm = locationManager.totalDistance / 1000.0
        let newAttempt = runTarget.attempt + distanceInKm
        
        Task {
            do {
                try await runTargetManager.updateRunTarget(
                    userId: userId,
                    attempt: newAttempt,
                    date: runTarget.date
                )
                
                // Run目標更新を通知
                NotificationCenter.default.post(name: .init("RunTargetDidUpdate"), object: nil)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
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
    let sampleTarget = RunTarget(
        userId: UUID(),
        date: Date(),
        target: 10.0,
        attempt: 0.0,
        isAchieved: false,
        createdAt: Date(),
        updatedAt: Date()
    )
    RunMapView(
        runTarget: sampleTarget,
        runTargetManager: RunTargetManager(),
        userId: UUID()
    )
}

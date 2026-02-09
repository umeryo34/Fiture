//
//  RunView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import SwiftUI

struct RunView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var runTargetManager = RunTargetManager()
    @State private var showingRunMap = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("Run")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity)
                
                // 今日のRun目標
                if let runTarget = runTargetManager.runTarget {
                    VStack(spacing: 20) {
                        // 目標カード
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                // アイコン
                                Image("run")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                // 目標情報
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("今日の目標")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("目標: \(String(format: "%.1f", runTarget.target)) km")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("現在: \(String(format: "%.1f", runTarget.attempt)) km")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // 進捗表示
                                VStack {
                                    Text("\(String(format: "%.0f", runTarget.progressPercentage))%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    Text("進捗")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 進捗バー
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * (runTarget.progressPercentage / 100.0), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            // Run開始ボタン
                            Button(action: {
                                showingRunMap = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                    Text("Runを開始")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                    }
                } else {
                    // 目標が設定されていない場合
                    VStack(spacing: 20) {
                        Image("run")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        
                        Text("Run目標が設定されていません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Runを開始するには目標を設定してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showingRunMap = true
                        }) {
                            HStack {
                                Image(systemName: "target")
                                    .font(.system(size: 16))
                                Text("Run目標を設定")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
        }
        .task {
            await fetchRunTarget()
        }
        .sheet(isPresented: $showingRunMap) {
            if let userId = authManager.currentUser?.id {
                if let runTarget = runTargetManager.runTarget {
                    RunMapView(
                        runTarget: runTarget,
                        runTargetManager: runTargetManager,
                        userId: userId
                    )
                } else {
                    // 目標がない場合は目標設定画面を表示
                    RunSettingView()
                        .environmentObject(authManager)
                        .environmentObject(runTargetManager)
                        .onDisappear {
                            // 目標設定後にRun目標を再取得
                            Task {
                                await fetchRunTarget()
                            }
                        }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("RunTargetDidUpdate"))) { _ in
            // Run目標が更新された時に再取得
            Task {
                await fetchRunTarget()
            }
        }
    }
    
    private func fetchRunTarget() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await runTargetManager.fetchRunTarget(userId: userId)
        } catch {
            print("Run目標の取得に失敗: \(error)")
        }
    }
}

#Preview {
    RunView()
        .environmentObject(AuthManager.shared)
}

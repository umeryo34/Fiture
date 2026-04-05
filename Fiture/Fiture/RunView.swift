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
    @State private var showingRunSession = false
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
                
                VStack(spacing: 20) {
                    Image("run")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    Text("モードを選んでRunを開始")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Button(action: {
                        showingRunSession = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                            Text("Runを開始")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
            }
        }
        .task {
            await fetchRunTarget()
        }
        .sheet(isPresented: $showingRunSession) {
            if let userId = authManager.currentUser?.id {
                // 目標が未作成でも、いきなりモード選択へ遷移する
                let baseRunTarget = runTargetManager.runTarget ?? RunTarget(
                    userId: userId,
                    date: runTargetManager.selectedDate,
                    target: 0,
                    attempt: 0,
                    isAchieved: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                RunModeSelectionView(
                    runTarget: baseRunTarget,
                    runTargetManager: runTargetManager,
                    userId: userId
                )
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

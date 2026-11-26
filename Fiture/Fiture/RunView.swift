//
//  RunView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import SwiftUI

struct RunView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: RunViewModel
    @State private var gymWalkingSpeedKmh = ExcessBurnExercisePlanner.defaultGymWalkingSpeedKmh
    @State private var gymWalkingInclinePercent = ExcessBurnExercisePlanner.defaultGymWalkingInclinePercent
    @State private var isGymSessionActive = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 計測中はキャラクターと記録を上に出し、運動の目安は下に回す
                    if !isGymSessionActive {
                        excessSection
                    }

                    RunGymView(
                        mood: viewModel.excessOverTargetKcal == nil ? .angel : .devil,
                        isSessionActive: $isGymSessionActive
                    )

                    if isGymSessionActive {
                        excessSection
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .fitureScreenBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var excessSection: some View {
        if let excess = viewModel.excessOverTargetKcal {
            RunExcessExerciseSection(
                excessKcal: excess,
                plan: viewModel.exercisePlan(
                    gymWalkingSpeedKmh: gymWalkingSpeedKmh,
                    gymWalkingInclinePercent: gymWalkingInclinePercent
                ),
                needsWeightForEstimate: viewModel.dailyBalance.weightKg == nil
                    || (viewModel.dailyBalance.weightKg ?? 0) <= 0,
                gymWalkingSpeedKmh: $gymWalkingSpeedKmh,
                gymWalkingInclinePercent: $gymWalkingInclinePercent
            )
        }
    }
}

#Preview {
    RunView(viewModel: RunViewModel())
        .environmentObject(AuthManager.shared)
        .environmentObject(RunCalorieReminderState())
}

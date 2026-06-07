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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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

                    RunGymView()
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    RunView(viewModel: RunViewModel())
        .environmentObject(AuthManager.shared)
        .environmentObject(RunCalorieReminderState())
}

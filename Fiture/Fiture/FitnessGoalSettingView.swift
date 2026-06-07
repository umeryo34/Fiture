//
//  FitnessProfileGoalSettingView.swift
//  Fiture
//
//  設定から開く「目標を変更」用（UserView と同じ NavigationView スタイル）
//

import SwiftUI

struct FitnessProfileGoalSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TargetSettingView(
            screenTitle: "目標を変更",
            onCompleted: {
                dismiss()
            }
        )
        .environmentObject(authManager)
    }
}

#Preview {
    FitnessProfileGoalSettingView()
        .environmentObject(AuthManager.shared)
}

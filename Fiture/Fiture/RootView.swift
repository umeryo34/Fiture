//
//  RootView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var runCalorieReminder = RunCalorieReminderState()
    @StateObject private var runTabViewModel = RunViewModel()
    @State private var fitnessProfileCompleted = false
    @State private var selectedTab = 0
    @State private var runTabAnchor: TabBarItemAnchor?
    @State private var tabBarLayoutRevision = 0

    private enum MainTab: Int {
        case home = 0
        case run = 1
        case user = 2
    }

    var body: some View {
        Group {
            if fitnessProfileCompleted {
                mainTabView
            } else {
                TargetSettingView(allowsManualDismiss: false) {
                    fitnessProfileCompleted = true
                }
                .environmentObject(authManager)
            }
        }
        .task(id: authManager.currentUser?.id) {
            let profile = FitnessProfileStorage.load(userId: authManager.currentUser?.id)
            fitnessProfileCompleted = profile.isCompleted
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(authManager)
                .environmentObject(runCalorieReminder)
                .tag(MainTab.home.rawValue)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Home")
                }

            RunView(viewModel: runTabViewModel)
                .environmentObject(authManager)
                .environmentObject(runCalorieReminder)
                .tag(MainTab.run.rawValue)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Run")
                }

            UserView()
                .environmentObject(authManager)
                .environmentObject(runCalorieReminder)
                .tag(MainTab.user.rawValue)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("ユーザー")
                }
        }
        .environmentObject(runCalorieReminder)
        .background {
            TabBarItemAnchorObserver(
                tabIndex: MainTab.run.rawValue,
                layoutRevision: tabBarLayoutRevision,
                anchor: $runTabAnchor
            )
        }
        .overlay {
            runTabSpeechBubbleOverlay
        }
        .onChange(of: selectedTab) { _, _ in
            tabBarLayoutRevision += 1
        }
        .onChange(of: runCalorieReminder.isExcessActive) { _, _ in
            tabBarLayoutRevision += 1
        }
        .onAppear {
            runTabViewModel.configure(authManager: authManager, runReminder: runCalorieReminder)
        }
        .task(id: authManager.currentUser?.id) {
            runTabViewModel.configure(authManager: authManager, runReminder: runCalorieReminder)
            await runTabViewModel.refreshToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
            Task { await runTabViewModel.refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .runRecordDidSave)) { _ in
            Task { await runTabViewModel.refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightDataDidUpdate)) { _ in
            Task { await runTabViewModel.refreshToday() }
        }
    }

    @ViewBuilder
    private var runTabSpeechBubbleOverlay: some View {
        if selectedTab != MainTab.run.rawValue,
           runCalorieReminder.isExcessActive,
           let excess = runCalorieReminder.excessKcal {
            GeometryReader { proxy in
                let globalOrigin = proxy.frame(in: .global).origin
                let x = runTabBubbleCenterX(in: proxy) ?? proxy.size.width / 2
                let iconTopY = runTabAnchor.map { $0.iconTopY - globalOrigin.y }
                    ?? (proxy.size.height - proxy.safeAreaInsets.bottom - 49)
                let calloutHeight: CGFloat = 58
                let gapAboveTab: CGFloat = 6
                let y = iconTopY - gapAboveTab - calloutHeight / 2

                RunTabSpeechBubbleView(excessKcal: excess)
                    .position(x: x, y: y)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.2), value: runCalorieReminder.isExcessActive)
        }
    }

    private func runTabBubbleCenterX(in proxy: GeometryProxy) -> CGFloat? {
        guard let anchor = runTabAnchor else { return nil }
        let globalOrigin = proxy.frame(in: .global).origin
        return anchor.centerX - globalOrigin.x
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager.shared)
}

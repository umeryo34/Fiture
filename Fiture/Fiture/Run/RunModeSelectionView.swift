import SwiftUI

/// Run開始時に「Anywhere / Gym」を選ばせて、内容を切り替えるための画面。
struct RunModeSelectionView: View {
    enum RunMode: String, CaseIterable, Identifiable {
        case anywhere = "at anywhere"
        case gym = "at Gym"

        var id: String { rawValue }
    }

    let runTarget: RunTarget
    let runTargetManager: RunTargetManager
    let userId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var mode: RunMode = .anywhere

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Runの場所を選択")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Picker("モード", selection: $mode) {
                        ForEach(RunMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                }

                Divider()

                // 選択に応じて表示を切り替える（地図はAnywhereだけ）
                if mode == .anywhere {
                    RunMapView(
                        runTarget: runTarget,
                        runTargetManager: runTargetManager,
                        userId: userId
                    )
                } else {
                    RunGymView(
                        runTarget: runTarget,
                        runTargetManager: runTargetManager,
                        userId: userId
                    )
                }
            }
            .navigationTitle("Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}


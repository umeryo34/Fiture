//
//  RunCharacterScene.swift
//  Fiture
//

import SwiftUI

/// ラン計測中に表示する、ベルトの上を走る（歩く）キャラクター
struct RunCharacterScene: View {
    let mood: CharacterMood
    let motion: RunGymView.MotionType
    let speedKmPerHour: Double
    /// 計測中は true。中断中は立ち止まる
    let isMoving: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activity: CharacterActivity {
        guard isMoving else { return .idle }
        return motion == .running ? .run : .walk
    }

    /// 設定スピードに合わせた足の速さ（Running 8km/h、Walking 5km/h が標準）
    private var animationSpeed: Float {
        guard isMoving else { return 1 }
        let standard = motion == .running ? 8.0 : 5.0
        return Float(min(max(speedKmPerHour / standard, 0.6), 1.7))
    }

    var body: some View {
        ZStack {
            MovingBackground(
                speedKmPerHour: speedKmPerHour,
                isMoving: isMoving && !reduceMotion
            )

            CharacterView(
                mood: mood,
                activity: activity,
                speed: animationSpeed,
                facing: isMoving ? .pi / 3.2 : 0,
                height: 230
            )
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

/// 後ろへ流れる雲とベルト
private struct MovingBackground: View {
    let speedKmPerHour: Double
    let isMoving: Bool
    /// 止まるまでに進んだ距離（pt）。中断してもその位置から再開する
    @State private var travelled: Double = 0
    @State private var startedAt: Date?

    private var pointsPerSecond: Double { speedKmPerHour * 22 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isMoving)) { timeline in
            // Canvas の中で読むと状態の変化が反映されないため、外で計算して渡す
            let distance = distance(at: timeline.date)
            Canvas { context, size in
                draw(in: context, size: size, distance: distance)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 1, green: 0.93, blue: 0.92), Color(red: 1, green: 0.98, blue: 0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear { startedAt = isMoving ? Date() : nil }
        .onChange(of: isMoving) { _, moving in
            if moving {
                startedAt = Date()
            } else {
                travelled = distance(at: Date())
                startedAt = nil
            }
        }
        .accessibilityHidden(true)
    }

    private func distance(at date: Date) -> Double {
        guard let startedAt else { return travelled }
        return travelled + max(0, date.timeIntervalSince(startedAt)) * pointsPerSecond
    }

    private func draw(in context: GraphicsContext, size: CGSize, distance: Double) {
        // 雲（ゆっくり流れる）
        let clouds: [(x: Double, y: Double, width: Double)] = [(0.1, 0.16, 70), (0.45, 0.3, 52), (0.8, 0.12, 62)]
        for cloud in clouds {
            let x = wrapped(cloud.x * size.width - distance * 0.12, span: size.width + 120) - 80
            let y = cloud.y * size.height
            var path = Path()
            path.addEllipse(in: CGRect(x: x, y: y, width: cloud.width, height: cloud.width * 0.34))
            path.addEllipse(in: CGRect(x: x + cloud.width * 0.22, y: y - cloud.width * 0.16, width: cloud.width * 0.5, height: cloud.width * 0.42))
            context.fill(path, with: .color(.white.opacity(0.9)))
        }

        // ベルト
        let beltTop = size.height - 42
        context.fill(
            Path(CGRect(x: 0, y: beltTop, width: size.width, height: 42)),
            with: .color(Color(red: 0.36, green: 0.31, blue: 0.32))
        )
        context.fill(
            Path(CGRect(x: 0, y: beltTop, width: size.width, height: 4)),
            with: .color(.red)
        )
        let spacing = 56.0
        var x = -(distance.truncatingRemainder(dividingBy: spacing))
        while x < size.width {
            context.fill(
                Path(roundedRect: CGRect(x: x, y: beltTop + 20, width: 28, height: 5), cornerRadius: 2.5),
                with: .color(.white.opacity(0.55))
            )
            x += spacing
        }
    }

    private func wrapped(_ value: Double, span: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: span)
        return remainder < 0 ? remainder + span : remainder
    }
}

#Preview {
    RunCharacterScene(mood: .angel, motion: .running, speedKmPerHour: 8, isMoving: true)
        .padding()
}

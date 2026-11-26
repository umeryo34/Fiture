//
//  CharacterLibrary.swift
//  Fiture
//

import CoreGraphics
import Foundation
import RealityKit

/// カロリー収支（摂取 − 消費）に応じたキャラクターの状態
enum CharacterMood: String, CaseIterable {
    /// 目標内
    case angel
    /// 目標超過
    case devil

    var modelName: String {
        switch self {
        case .angel: return "Angel"
        case .devil: return "Devil"
        }
    }

    /// 3Dモデルの準備ができるまで（または読み込めなかったとき）に表示する静止画
    var imageName: String {
        switch self {
        case .angel: return "CharacterAngel"
        case .devil: return "CharacterDevil"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .angel: return "天使のキャラクター。カロリーは目標内です"
        case .devil: return "悪魔のキャラクター。カロリーが目標を超えています"
        }
    }
}

/// キャラクターの動き
enum CharacterActivity {
    case idle, run, walk

    /// USDZ の1本のタイムラインに入っている範囲（秒）。3DCharacter/build_character.py と揃える
    fileprivate var clip: ClosedRange<TimeInterval> {
        switch self {
        case .idle: return 0...2
        case .run: return (70.0 / 30.0)...(88.0 / 30.0)
        case .walk: return (100.0 / 30.0)...(130.0 / 30.0)
        }
    }
}

/// 画面に置けるキャラクター1体
@MainActor
struct Character3D {
    let entity: Entity
    /// 骨を持つ部品。動きはここで再生する（モデルの一番上で再生しても骨は動かない）
    let skeleton: Entity
    private let animations: [CharacterActivity: AnimationResource]

    fileprivate init(entity: Entity) {
        let found = Self.findSkeleton(in: entity)
        self.entity = entity
        skeleton = found?.entity ?? entity
        var animations: [CharacterActivity: AnimationResource] = [:]
        if let source = found?.animation {
            for activity in [CharacterActivity.idle, .run, .walk] {
                let view = AnimationView(
                    source: source.definition,
                    trimStart: activity.clip.lowerBound,
                    trimEnd: activity.clip.upperBound
                )
                animations[activity] = try? AnimationResource.generate(with: view)
            }
        }
        self.animations = animations
    }

    @discardableResult
    func play(_ activity: CharacterActivity) -> AnimationPlaybackController? {
        guard let animation = animations[activity] else { return nil }
        return skeleton.playAnimation(animation.repeat(), transitionDuration: 0.2)
    }

    private static func findSkeleton(in entity: Entity) -> (entity: Entity, animation: AnimationResource)? {
        if let animation = entity.availableAnimations.first(where: { $0.definition is SampledAnimation<JointTransforms> }) {
            return (entity, animation)
        }
        for child in entity.children {
            if let found = findSkeleton(in: child) { return found }
        }
        return nil
    }
}

/// 3Dモデルを一度だけ読み込んで、画面ごとに複製を渡す
@MainActor
final class CharacterLibrary {
    static let shared = CharacterLibrary()

    private var loading: [CharacterMood: Task<Entity, Error>] = [:]

    private var environmentTask: Task<EnvironmentResource?, Never>?

    private init() {}

    /// 起動直後に呼び、ホームが表示されるまでに読み込みを進めておく
    func preload() {
        for mood in CharacterMood.allCases {
            _ = loadTask(for: mood)
        }
        _ = loadEnvironment()
    }

    /// 全体をやわらかく照らす環境光（上が白、下が少し暗い）
    func environment() async -> EnvironmentResource? {
        await loadEnvironment().value
    }

    private func loadEnvironment() -> Task<EnvironmentResource?, Never> {
        if let environmentTask { return environmentTask }
        let task = Task { () -> EnvironmentResource? in
            guard let image = Self.makeEnvironmentImage() else { return nil }
            return try? await EnvironmentResource(equirectangular: image)
        }
        environmentTask = task
        return task
    }

    private static func makeEnvironmentImage() -> CGImage? {
        let width = 128, height = 64
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ),
              let gradient = CGGradient(
                colorsSpace: space,
                colors: [CGColor(gray: 0.78, alpha: 1), CGColor(gray: 1, alpha: 1)] as CFArray,
                locations: [0, 1]
              ) else { return nil }
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
        return context.makeImage()
    }

    func makeCharacter(_ mood: CharacterMood) async throws -> Character3D {
        do {
            let template = try await loadTask(for: mood).value
            return Character3D(entity: template.clone(recursive: true))
        } catch {
            loading[mood] = nil // 次の表示で読み直せるようにする
            throw error
        }
    }

    private func loadTask(for mood: CharacterMood) -> Task<Entity, Error> {
        if let task = loading[mood] { return task }
        let task = Task { try await Entity(named: mood.modelName, in: .main) }
        loading[mood] = task
        return task
    }
}

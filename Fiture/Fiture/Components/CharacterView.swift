//
//  CharacterView.swift
//  Fiture
//

import SwiftUI
import RealityKit

/// 3Dキャラクター。タップで走り、横になぞると回る。
/// `mood` が nil の間（状態がまだ分からない間）は場所だけ確保する
struct CharacterView: View {
    let mood: CharacterMood?
    var activity: CharacterActivity = .idle
    /// 動きの速さ（1 が標準）
    var speed: Float = 1
    /// 体の向き（ラジアン）。正の値で画面右を向く
    var facing: Float = 0
    var height: CGFloat = 280
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage = CharacterStage()
    /// 別のタブの裏にある間は、電池の節約のため3D表示を外す
    @State private var isVisible = false

    private var request: CharacterStage.Request {
        .init(mood: mood, activity: activity, speed: speed, facing: facing, reduceMotion: reduceMotion)
    }

    /// 静止画は正面・待機の姿なので、それ以外の動きのつなぎには使わない
    private var showsStill: Bool {
        stage.loadFailed || (!stage.isReady && activity == .idle)
    }

    var body: some View {
        ZStack {
            if isVisible, !stage.loadFailed {
                stageView
            }
            if let mood {
                Image(mood.imageName)
                    .resizable()
                    .scaledToFit()
                    .opacity(showsStill ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: showsStill)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mood?.accessibilityLabel ?? "")
        .accessibilityHidden(mood == nil)
        .onAppear { isVisible = true }
        .onDisappear {
            isVisible = false
            stage.didLeaveScene()
        }
        .task(id: request) {
            await stage.update(request)
        }
    }

    private var stageView: some View {
        CharacterStageView(stage: stage)
        .contentShape(Rectangle())
        .onTapGesture {
            stage.runBriefly()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    // 縦のスクロールでは回さない
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    stage.turn(by: Float(value.translation.width) * 0.012)
                }
                .onEnded { _ in
                    stage.resetTurn()
                }
        )
    }
}

/// 背景が透明な3D表示
private struct CharacterStageView: UIViewRepresentable {
    let stage: CharacterStage

    func makeUIView(context: Context) -> CharacterMetalView {
        let view = CharacterMetalView(stage: stage)
        stage.didEnterScene()
        return view
    }

    func updateUIView(_ uiView: CharacterMetalView, context: Context) {}

    static func dismantleUIView(_ uiView: CharacterMetalView, coordinator: ()) {
        uiView.stop()
    }
}

/// RealityRenderer を自前のタイミングで描画する。
/// RealityView や ARView は、3D表示が数秒間どこにも出ていないと描画が止まり、
/// 再び表示しても戻らないことがあるため使わない（Home と Run のタブ切り替えで起きる）
private final class CharacterMetalView: UIView {
    override class var layerClass: AnyClass { CAMetalLayer.self }

    private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
    private let stage: CharacterStage
    private var renderer: RealityRenderer?
    private var displayLink: CADisplayLink?
    private var isLit = false
    private var lastTimestamp: CFTimeInterval?

    init(stage: CharacterStage) {
        self.stage = stage
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear

        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm_srgb
        metalLayer.framebufferOnly = false
        metalLayer.isOpaque = false

        guard metalLayer.device != nil, let renderer = try? RealityRenderer() else {
            stage.didFailToRender()
            return
        }
        renderer.cameraSettings.colorBackground = .color(CGColor(gray: 0, alpha: 0))
        renderer.cameraSettings.antialiasing = .multisample4X
        // イラストの発色に近づける
        renderer.cameraSettings.isToneMappingEnabled = false
        self.renderer = renderer
        renderer.entities.append(stage.root)
        renderer.activeCamera = stage.camera
        Task {
            // 環境光が届いてから描き始める（暗い姿を一瞬見せない）
            renderer.lighting.resource = await CharacterLibrary.shared.environment()
            renderer.lighting.intensityExponent = -0.15
            isLit = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = window?.screen.scale ?? traitCollection.displayScale
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        guard displayLink == nil, renderer != nil else { return }
        setNeedsLayout()
        lastTimestamp = nil
        // 弱参照で包み、displayLink がこのビューを抱え続けないようにする
        let target = DisplayLinkTarget { [weak self] link in self?.render(link) }
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick(_:)))
        // 電池の節約のため毎秒30コマに抑える
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 24, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func render(_ link: CADisplayLink) {
        guard let renderer, isLit, metalLayer.drawableSize.width > 0, metalLayer.drawableSize.height > 0,
              let drawable = metalLayer.nextDrawable() else { return }
        let deltaTime = lastTimestamp.map { min(link.timestamp - $0, 0.1) } ?? 0
        lastTimestamp = link.timestamp

        nonisolated(unsafe) let presented = drawable
        do {
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: drawable.texture))
            try renderer.updateAndRender(deltaTime: deltaTime, cameraOutput: output, onComplete: { _ in
                presented.present()
            })
            stage.didRenderFrame()
        } catch {
            stop()
            stage.didFailToRender()
        }
    }

    private final class DisplayLinkTarget: NSObject {
        private let onTick: (CADisplayLink) -> Void

        init(onTick: @escaping (CADisplayLink) -> Void) {
            self.onTick = onTick
        }

        @objc func tick(_ link: CADisplayLink) {
            onTick(link)
        }
    }
}

/// 1画面分の舞台。キャラクターの入れ替えと動きの切り替えを受け持つ
@MainActor
@Observable
private final class CharacterStage {
    struct Request: Equatable {
        var mood: CharacterMood?
        var activity: CharacterActivity = .idle
        var speed: Float = 1
        var facing: Float = 0
        var reduceMotion = false
    }

    private(set) var isReady = false
    private(set) var loadFailed = false

    @ObservationIgnored let root = Entity()
    @ObservationIgnored let camera = PerspectiveCamera()
    @ObservationIgnored private var renderedFrames = 0
    /// 横になぞったときの回転用
    @ObservationIgnored private let turntable = Entity()
    /// 天使と悪魔を入れ替えるときの拡大縮小用
    @ObservationIgnored private let pivot = Entity()
    @ObservationIgnored private var characters: [CharacterMood: Character3D] = [:]
    @ObservationIgnored private var current = Request()
    @ObservationIgnored private var shownMood: CharacterMood?
    @ObservationIgnored private var briefRunTask: Task<Void, Never>?
    @ObservationIgnored private var swapTask: Task<Void, Never>?

    /// 画面の再描画のたびに作られても軽いよう、中身は最初に表示するときに組み立てる
    private func setUpIfNeeded() {
        guard root.children.isEmpty else { return }

        camera.camera.fieldOfViewInDegrees = 30
        camera.look(at: [0, 0.04, 0], from: [0, 0.14, 3.15], relativeTo: nil)
        root.addChild(camera)

        // 主光と、顔の下側を明るくする補助光
        for (intensity, position) in [(700, SIMD3<Float>(0.6, 1.2, 2)), (150, SIMD3<Float>(-0.5, -0.8, 2))] {
            let light = DirectionalLight()
            light.light.intensity = Float(intensity)
            light.look(at: .zero, from: position, relativeTo: nil)
            root.addChild(light)
        }

        turntable.addChild(pivot)
        root.addChild(turntable)
    }

    /// 画面に追加される前に始めた動きは再生されないことがあるため、追加後に始め直す
    func didEnterScene() {
        setUpIfNeeded()
        playCurrentActivity()
    }

    /// 戻ってきたときに最初の1コマが出るまで、また静止画でつなぐ
    func didLeaveScene() {
        briefRunTask?.cancel()
        turntable.orientation = simd_quatf(angle: current.facing, axis: [0, 1, 0])
        isReady = false
        renderedFrames = 0
    }

    /// 実際に数コマ描けてから静止画を消す
    func didRenderFrame() {
        guard !isReady, shownMood != nil else { return }
        renderedFrames += 1
        if renderedFrames >= 3 { isReady = true }
    }

    func didFailToRender() {
        loadFailed = true
    }

    func update(_ request: Request) async {
        setUpIfNeeded()
        let previous = current
        current = request
        guard let mood = request.mood else { return }

        // 必要な1体だけを待って表示する
        if characters[mood] == nil {
            do {
                let character = try await CharacterLibrary.shared.makeCharacter(mood)
                guard !Task.isCancelled else { return }
                if characters[mood] == nil {
                    character.entity.isEnabled = false
                    pivot.addChild(character.entity)
                    characters[mood] = character
                }
            } catch {
                if !Task.isCancelled { loadFailed = true }
                return
            }
        }

        if shownMood == nil {
            turntable.orientation = simd_quatf(angle: request.facing, axis: [0, 1, 0])
        } else if previous.facing != request.facing {
            resetTurn()
        }

        if shownMood == mood {
            briefRunTask?.cancel()
            playCurrentActivity()
        } else {
            show(mood)
        }
    }

    /// その場で少し走ってから元の動きに戻る
    func runBriefly() {
        guard current.activity == .idle, !current.reduceMotion,
              let mood = shownMood, let character = characters[mood] else { return }
        briefRunTask?.cancel()
        character.play(.run)
        face(yaw: .pi / 5, duration: 0.2)
        briefRunTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            playCurrentActivity()
            resetTurn()
        }
    }

    func turn(by angle: Float) {
        turntable.stopAllAnimations()
        turntable.orientation = simd_quatf(angle: current.facing + angle, axis: [0, 1, 0])
    }

    func resetTurn() {
        face(yaw: current.facing, duration: 0.4)
    }

    private func face(yaw: Float, duration: TimeInterval) {
        var transform = Transform.identity
        transform.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        turntable.move(to: transform, relativeTo: root, duration: duration, timingFunction: .easeInOut)
    }

    private func show(_ mood: CharacterMood) {
        briefRunTask?.cancel()
        swapTask?.cancel()
        let isFirst = shownMood == nil
        shownMood = mood

        guard !isFirst, !current.reduceMotion else {
            pivot.transform = .identity
            activate(mood)
            return
        }

        swapTask = Task {
            var small = Transform.identity
            small.scale = .init(repeating: 0.05)
            small.rotation = simd_quatf(angle: .pi * 0.9, axis: [0, 1, 0])
            pivot.move(to: small, relativeTo: turntable, duration: 0.25, timingFunction: .easeIn)
            try? await Task.sleep(for: .seconds(0.25))
            guard !Task.isCancelled else { return }
            activate(mood)
            pivot.move(to: .identity, relativeTo: turntable, duration: 0.35, timingFunction: .easeOut)
        }
    }

    private func activate(_ mood: CharacterMood) {
        for (key, character) in characters {
            character.entity.isEnabled = key == mood
            character.skeleton.stopAllAnimations()
        }
        playCurrentActivity()
    }

    private func playCurrentActivity() {
        guard let mood = shownMood, let character = characters[mood] else { return }
        guard !current.reduceMotion else {
            character.skeleton.stopAllAnimations()
            return
        }
        character.play(current.activity)?.speed = current.speed
    }
}

#Preview("目標内") {
    CharacterView(mood: .angel)
}

#Preview("目標超過") {
    CharacterView(mood: .devil)
}

#Preview("走る") {
    CharacterView(mood: .angel, activity: .run, facing: .pi / 3)
}

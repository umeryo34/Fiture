//
//  RulerScrollValuePicker.swift
//  Fiture
//

import SwiftUI
import UIKit

/// 定規風の横スクロールピッカー（0.1 刻み・画面内埋め込み）
struct RulerScrollValuePicker: View {
    let title: String
    let unit: String
    let minTenth: Int
    let maxTenth: Int
    @Binding var selectionTenth: Int

    @State private var scrollPosition: Int?

    /// 小さいほど同じスワイプ量でより多くの値が動く（感度アップ）
    private let tickWidth: CGFloat = 4.5
    private var values: [Int] {
        Array(minTenth...maxTenth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(formatTenth(selectionTenth)) \(unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .monospacedDigit()
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.04))

                // 中央の定規読み取り線
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 72)
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(180))
                        .offset(y: -2)
                }
                .allowsHitTesting(false)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(values, id: \.self) { tenth in
                            rulerTickColumn(tenth: tenth)
                                .frame(width: tickWidth)
                                .id(tenth)
                        }
                    }
                    .padding(.vertical, 8)
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPosition, anchor: .center)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .contentMargins(.horizontal, 40, for: .scrollContent)
                .background(FastHorizontalScrollPhysics())
                .frame(height: 88)
            }
            .frame(height: 88)
        }
        .onAppear {
            scrollPosition = clamped(selectionTenth)
            selectionTenth = scrollPosition ?? selectionTenth
        }
        .onChange(of: selectionTenth) { _, newValue in
            let clampedValue = clamped(newValue)
            if clampedValue != scrollPosition {
                scrollPosition = clampedValue
            }
        }
        .onChange(of: scrollPosition) { _, newValue in
            if let newValue {
                let clampedValue = clamped(newValue)
                if clampedValue != selectionTenth {
                    selectionTenth = clampedValue
                }
            }
        }
    }

    @ViewBuilder
    private func rulerTickColumn(tenth: Int) -> some View {
        let offset = tenth - minTenth
        VStack(spacing: 3) {
            Rectangle()
                .fill(Color.primary.opacity(tickOpacity(offset: offset)))
                .frame(width: tickLineWidth(offset: offset), height: tickHeight(offset: offset))
                .frame(maxHeight: 32, alignment: .bottom)

            if showsLabel(offset: offset) {
                Text(labelText(tenth: tenth))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Color.clear.frame(height: 12)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func tickHeight(offset: Int) -> CGFloat {
        if offset % 100 == 0 { return 28 }
        if offset % 10 == 0 { return 18 }
        if offset % 5 == 0 { return 12 }
        return 6
    }

    private func tickLineWidth(offset: Int) -> CGFloat {
        if offset % 10 == 0 { return 1.5 }
        return 1
    }

    private func tickOpacity(offset: Int) -> Double {
        if offset % 10 == 0 { return 0.85 }
        return 0.35
    }

    private func showsLabel(offset: Int) -> Bool {
        offset % 10 == 0
    }

    private func labelText(tenth: Int) -> String {
        let value = Double(tenth) / 10
        if offsetIsMajor(offset: tenth - minTenth) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func offsetIsMajor(offset: Int) -> Bool {
        offset % 100 == 0
    }

    private func formatTenth(_ tenth: Int) -> String {
        String(format: "%.1f", Double(tenth) / 10)
    }

    private func clamped(_ value: Int) -> Int {
        min(maxTenth, max(minTenth, value))
    }
}

// MARK: - 横スクロールを速め・キビキビさせる

private struct FastHorizontalScrollPhysics: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = uiView.enclosingScrollView(where: { $0.contentSize.width > $0.bounds.width + 1 }) else {
                return
            }
            scrollView.decelerationRate = .fast
            scrollView.alwaysBounceHorizontal = true
        }
    }
}

private extension UIView {
    func enclosingScrollView(where predicate: (UIScrollView) -> Bool) -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView, predicate(scrollView) {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}

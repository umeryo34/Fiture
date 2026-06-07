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
    /// 表示値 = 内部値 ÷ valueScale（10 なら 0.1 刻み、1 なら整数）
    var valueScale: Double = 10
    @Binding var selectionTenth: Int

    @State private var scrollPosition: Int?

    /// 小さいほど同じスワイプ量でより多くの値が動く（感度アップ）
    private let tickWidth: CGFloat = 3.2
    private var values: [Int] {
        Array(minTenth...maxTenth)
    }

    private var rulerHeight: CGFloat { 96 }

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
                .frame(height: rulerHeight)
            }
            .frame(height: rulerHeight)
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
        if valueScale == 1 {
            integerCalorieTickColumn(tenth: tenth)
        } else {
            decimalTickColumn(tenth: tenth)
        }
    }

    @ViewBuilder
    private func integerCalorieTickColumn(tenth: Int) -> some View {
        twoRowTickColumn(
            tenth: tenth,
            topLabel: tenth % 100 == 0,
            bottomLabel: tenth % 10 == 0 && tenth % 100 != 0,
            topStyle: .major,
            bottomStyle: .minor
        )
    }

    @ViewBuilder
    private func decimalTickColumn(tenth: Int) -> some View {
        // 上: 5単位ごと（60, 65 kg / 170, 175 cm）、下: 1単位ごと（67, 68 など）
        twoRowTickColumn(
            tenth: tenth,
            topLabel: tenth % 50 == 0,
            bottomLabel: tenth % 10 == 0 && tenth % 50 != 0,
            topStyle: .major,
            bottomStyle: .minor
        )
    }

    private enum TickLabelStyle {
        case major
        case minor
    }

    @ViewBuilder
    private func twoRowTickColumn(
        tenth: Int,
        topLabel: Bool,
        bottomLabel: Bool,
        topStyle: TickLabelStyle,
        bottomStyle: TickLabelStyle
    ) -> some View {
        VStack(spacing: 2) {
            tickLabel(text: topLabel ? labelText(tenth: tenth, style: topStyle) : nil, style: topStyle)
                .frame(height: 12)

            Rectangle()
                .fill(Color.primary.opacity(tickOpacity(tenth: tenth)))
                .frame(width: tickLineWidth(tenth: tenth), height: tickHeight(tenth: tenth))
                .frame(maxHeight: 30, alignment: .bottom)

            tickLabel(text: bottomLabel ? labelText(tenth: tenth, style: bottomStyle) : nil, style: bottomStyle)
                .frame(height: 11)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func tickLabel(text: String?, style: TickLabelStyle) -> some View {
        if let text {
            Text(text)
                .font(.system(size: style == .major ? 10 : 8, weight: style == .major ? .semibold : .medium))
                .foregroundColor(style == .major ? .primary.opacity(0.85) : .secondary)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
                .allowsHitTesting(false)
        } else {
            Color.clear
        }
    }

    private func tickHeight(tenth: Int) -> CGFloat {
        if isMajorTick(tenth) { return 28 }
        if isMidTick(tenth) { return 16 }
        if isMinorTick(tenth) { return 10 }
        return 6
    }

    private func tickLineWidth(tenth: Int) -> CGFloat {
        if isMajorTick(tenth) { return 2 }
        if isMidTick(tenth) { return 1.5 }
        return 1
    }

    private func tickOpacity(tenth: Int) -> Double {
        if isMajorTick(tenth) { return 0.9 }
        if isMidTick(tenth) { return 0.55 }
        return 0.3
    }

    private func isMajorTick(_ tenth: Int) -> Bool {
        if valueScale == 1 { return tenth % 100 == 0 }
        return tenth % 50 == 0
    }

    private func isMidTick(_ tenth: Int) -> Bool {
        if valueScale == 1 { return tenth % 10 == 0 }
        return tenth % 10 == 0
    }

    private func isMinorTick(_ tenth: Int) -> Bool {
        tenth % 5 == 0
    }

    private func labelText(tenth: Int, style: TickLabelStyle) -> String {
        let value = displayValue(tenth)
        if valueScale == 1 {
            return String(format: "%.0f", value)
        }
        if style == .major {
            return String(format: "%.0f", value)
        }
        return decimalMinorLabel(value)
    }

    /// 下段ラベル: 67.0 → 67、67.3 → 67.3
    private func decimalMinorLabel(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if abs(rounded - rounded.rounded()) < 0.001 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    private func formatTenth(_ tenth: Int) -> String {
        let value = displayValue(tenth)
        if valueScale == 1 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func displayValue(_ tenth: Int) -> Double {
        Double(tenth) / valueScale
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
            scrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.992)
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

//
//  FitureTheme.swift
//  Fiture
//
//  天使・悪魔キャラクターに合わせた色と、角丸カードなどの共通部品
//

import SwiftUI

enum FitureTheme {
    /// 画面の地色（クリーム）
    static let background = Color(red: 1.0, green: 0.972, blue: 0.957)
    static let card = Color.white
    /// 文字の基本色（こげ茶）
    static let ink = Color(red: 0.29, green: 0.17, blue: 0.15)
    static let subInk = Color(red: 0.29, green: 0.17, blue: 0.15).opacity(0.55)
    /// 天使の肌（ピンク）
    static let blush = Color(red: 0.98, green: 0.76, blue: 0.73)
    static let blushLight = Color(red: 1.0, green: 0.92, blue: 0.9)
    /// マフラーの赤（主ボタン）
    static let coral = Color(red: 0.91, green: 0.33, blue: 0.29)
    /// 双葉の緑（目標内）
    static let leaf = Color(red: 0.49, green: 0.69, blue: 0.24)
    /// 天使の輪の金色
    static let halo = Color(red: 0.97, green: 0.79, blue: 0.29)
    /// 悪魔の赤（超過）
    static let devil = Color(red: 0.74, green: 0.13, blue: 0.17)
    static let devilLight = Color(red: 0.99, green: 0.9, blue: 0.9)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// 三大栄養素（PFC）
enum Macro: CaseIterable, Identifiable {
    case protein, fat, carbs

    var id: Self { self }

    var name: String {
        switch self {
        case .protein: return "たんぱく質"
        case .fat: return "脂質"
        case .carbs: return "炭水化物"
        }
    }

    var letter: String {
        switch self {
        case .protein: return "P"
        case .fat: return "F"
        case .carbs: return "C"
        }
    }

    var emoji: String {
        switch self {
        case .protein: return "🍗"
        case .fat: return "🧈"
        case .carbs: return "🍙"
        }
    }

    /// 1gあたりのエネルギー（kcal）
    var kcalPerGram: Double {
        switch self {
        case .protein, .carbs: return 4
        case .fat: return 9
        }
    }

    var color: Color {
        switch self {
        case .protein: return Color(red: 0.93, green: 0.42, blue: 0.47)
        case .fat: return Color(red: 0.96, green: 0.7, blue: 0.2)
        case .carbs: return Color(red: 0.42, green: 0.7, blue: 0.36)
        }
    }

    var lightColor: Color { color.opacity(0.16) }
}

/// 食事の区分
enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snack

    var id: Self { self }

    var name: String {
        switch self {
        case .breakfast: return "朝ごはん"
        case .lunch: return "昼ごはん"
        case .dinner: return "夜ごはん"
        case .snack: return "間食"
        }
    }

    var shortName: String {
        switch self {
        case .breakfast: return "朝"
        case .lunch: return "昼"
        case .dinner: return "夜"
        case .snack: return "間食"
        }
    }

    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍪"
        }
    }

    /// 記録した時刻から区分を推測する
    static func guess(for date: Date = Date()) -> MealType {
        switch Calendar.current.component(.hour, from: date) {
        case 4..<10: return .breakfast
        case 10..<15: return .lunch
        case 17..<22: return .dinner
        default: return .snack
        }
    }
}

/// 白い角丸カード
struct CuteCard: ViewModifier {
    var padding: CGFloat = 18
    var fill: Color = FitureTheme.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(fill)
                    .shadow(color: FitureTheme.coral.opacity(0.1), radius: 14, y: 6)
            )
    }
}

extension View {
    /// 画面をクリーム色にし、スクロールした内容がステータスバーに重ならないようにする
    func fitureScreenBackground() -> some View {
        background(FitureTheme.background.ignoresSafeArea())
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    FitureTheme.background
                        .frame(height: proxy.safeAreaInsets.top)
                        .offset(y: -proxy.safeAreaInsets.top)
                }
                .frame(height: 0)
                .allowsHitTesting(false)
            }
    }

    func cuteCard(padding: CGFloat = 18, fill: Color = FitureTheme.card) -> some View {
        modifier(CuteCard(padding: padding, fill: fill))
    }
}

/// ふっくらした主ボタン
struct PuffyButtonStyle: ButtonStyle {
    var color: Color = FitureTheme.coral
    var isEnabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitureTheme.rounded(17, .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(isEnabled ? color : Color.gray.opacity(0.45))
                    .shadow(color: (isEnabled ? color : .clear).opacity(0.35), radius: 0, y: configuration.isPressed ? 1 : 4)
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// 見出し（絵文字＋太字）
struct CuteSectionTitle: View {
    let emoji: String
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(emoji)
            Text(title)
                .font(FitureTheme.rounded(17, .heavy))
                .foregroundColor(FitureTheme.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(FitureTheme.rounded(12, .semibold))
                    .foregroundColor(FitureTheme.subInk)
            }
        }
    }
}

/// キャラクターの吹き出し（下向きのしっぽ付き）
struct SpeechBubble<Content: View>: View {
    var tint: Color = FitureTheme.coral
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: -1) {
            content
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(tint.opacity(0.35), lineWidth: 2)
                        )
                )
            BubbleTail()
                .fill(Color.white)
                .overlay(BubbleTail().stroke(tint.opacity(0.35), lineWidth: 2).mask(Rectangle().padding(.top, 2)))
                .frame(width: 22, height: 12)
        }
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX - 2, y: rect.minY + 4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX + 2, y: rect.minY + 4))
        return path
    }
}

/// 角丸の進み具合バー
struct CuteProgressBar: View {
    let progress: Double
    var color: Color
    var track: Color = Color.black.opacity(0.06)
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: max(height, proxy.size.width * min(max(progress, 0), 1)))
                    .opacity(progress > 0 ? 1 : 0)
                    // 光沢
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: height * 0.3)
                            .padding(.horizontal, height * 0.4)
                            .padding(.top, height * 0.18)
                            .opacity(progress > 0.05 ? 1 : 0)
                    }
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }
}

/// 栄養素の小さなバッジ（例: P 20g）
struct MacroChip: View {
    let macro: Macro
    let grams: Double?

    var body: some View {
        HStack(spacing: 2) {
            Text(macro.letter)
                .font(FitureTheme.rounded(10, .heavy))
            Text(grams.map { NutritionFormat.grams($0) } ?? "–")
                .font(FitureTheme.rounded(11, .semibold))
        }
        .foregroundColor(macro.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(macro.lightColor))
    }
}

enum NutritionFormat {
    static func kcal(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    static func grams(_ value: Double) -> String {
        value < 10 && value != value.rounded() ? String(format: "%.1fg", value) : String(format: "%.0fg", value)
    }
}

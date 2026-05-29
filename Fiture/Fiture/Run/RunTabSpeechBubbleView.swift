//
//  RunTabSpeechBubbleView.swift
//  Fiture
//
//  タブバーの Run アイコン直上に表示する吹き出し
//

import SwiftUI

struct RunTabSpeechBubbleView: View {
    let excessKcal: Double

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 1) {
                    Text("カロリーを消費しよう！")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("目標 +\(String(format: "%.0f", excessKcal)) kcal")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.45), lineWidth: 1.5)
                    )
            )

            RunTabBubbleTail()
                .fill(Color(.systemBackground))
                .frame(width: 14, height: 8)
                .overlay(
                    RunTabBubbleTail()
                        .stroke(Color.red.opacity(0.45), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .fixedSize()
    }
}

private struct RunTabBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

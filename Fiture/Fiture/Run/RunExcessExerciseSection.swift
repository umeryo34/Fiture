//
//  RunExcessExerciseSection.swift
//  Fiture
//

import SwiftUI

struct RunExcessExerciseSection: View {
    let excessKcal: Double
    let plan: ExcessBurnExercisePlan?
    let needsWeightForEstimate: Bool
    @Binding var gymWalkingSpeedKmh: Double
    @Binding var gymWalkingInclinePercent: Double
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("目標超過分を落とす目安")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.red)

            Text("あと \(String(format: "%.0f", excessKcal)) kcal 分の運動が必要です（ACSM式・体重ベースの推定）。")
                .font(.caption)
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)

            if let plan {
                HStack(spacing: 16) {
                    quickEstimate(label: "ジム", estimate: plan.gymWalking)
                    quickEstimate(label: "屋外", estimate: plan.outdoorRunning)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "詳細を閉じる" : "傾斜・速度を調整")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.black.opacity(0.55))
                }
                .buttonStyle(.plain)

                if isExpanded {
                    expandedControls(plan: plan)
                }
            } else if needsWeightForEstimate {
                Text("運動時間の目安には、プロフィールの体重登録が必要です。")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private func quickEstimate(label: String, estimate: ExerciseTimeEstimate) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.5))
            Text("約 \(estimate.formattedDuration)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }

    @ViewBuilder
    private func expandedControls(plan: ExcessBurnExercisePlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("傾斜（勾配）")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                Spacer()
                Text("\(Int(gymWalkingInclinePercent))%")
                    .font(.caption)
            }
            Slider(value: $gymWalkingInclinePercent, in: 0...15, step: 1)
                .tint(.red)

            HStack {
                Text("速度")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                Spacer()
                Text(String(format: "%.1f km/h", gymWalkingSpeedKmh))
                    .font(.caption)
            }
            Slider(value: $gymWalkingSpeedKmh, in: 3...8, step: 0.5)
                .tint(.red)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.03))
        )

        detailCard(estimate: plan.gymWalking)
        detailCard(estimate: plan.outdoorRunning)
    }

    private func detailCard(estimate: ExerciseTimeEstimate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(estimate.title)
                .font(.caption)
                .fontWeight(.semibold)
            HStack(spacing: 8) {
                if estimate.inclinePercent > 0 {
                    Text("傾斜 \(Int(estimate.inclinePercent))%")
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.55))
                }
                Text(String(format: "%.1f km/h", estimate.speedKmh))
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.55))
            }
            Text("約 \(estimate.formattedDuration)")
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.04))
        )
    }
}

//
//  WeightChartView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct WeightChartView: View {
    let weightEntries: [WeightEntry]

    private static let windowDayCount = 7

    /// 左端＝6日前 … 右端＝今日（毎日シフトする固定7日枠）
    private var rollingWindowDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<Self.windowDayCount).compactMap { index in
            let dayOffset = index - (Self.windowDayCount - 1)
            return calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }

    private var weightByDay: [Date: Double] {
        let calendar = Calendar.current
        var map: [Date: Double] = [:]
        for entry in weightEntries {
            map[calendar.startOfDay(for: entry.date)] = entry.weight
        }
        return map
    }

    private var plottedPoints: [(slotIndex: Int, date: Date, weight: Double)] {
        rollingWindowDays.enumerated().compactMap { index, day in
            guard let weight = weightByDay[day] else { return nil }
            return (slotIndex: index, date: day, weight: weight)
        }
    }

    private var hasAnyWeightInWindow: Bool {
        !plottedPoints.isEmpty
    }

    private var minWeight: Double {
        plottedPoints.map(\.weight).min() ?? 0
    }

    private var maxWeight: Double {
        plottedPoints.map(\.weight).max() ?? 0
    }

    private static let yAxisPreferredStep: Double = 0.2
    private static let yAxisMaxTicks: Int = 11

    private var yAxisLayout: (minY: Double, maxY: Double, step: Double, ticksDescending: [Double]) {
        guard hasAnyWeightInWindow else {
            return (0, 0.2, 0.2, [0.2, 0])
        }
        let pad = Self.yAxisPreferredStep
        var step = Self.yAxisPreferredStep

        if abs(maxWeight - minWeight) < 1e-9 {
            let c = minWeight
            let lo = c - 0.4
            let hi = c + 0.4
            var ascending: [Double] = []
            var t = lo
            while t <= hi + 1e-9 {
                ascending.append((t * 500).rounded() / 500)
                t += Self.yAxisPreferredStep
            }
            return (lo, hi, Self.yAxisPreferredStep, Array(ascending.reversed()))
        }

        var lo = floor((minWeight - pad) / step) * step
        var hi = ceil((maxWeight + pad) / step) * step
        if hi <= lo { hi = lo + step }

        var tickCount = Int((hi - lo) / step + 0.5) + 1
        while tickCount > Self.yAxisMaxTicks && step < 50 {
            step += Self.yAxisPreferredStep
            lo = floor((minWeight - pad) / step) * step
            hi = ceil((maxWeight + pad) / step) * step
            if hi <= lo { hi = lo + step }
            tickCount = Int((hi - lo) / step + 0.5) + 1
        }

        var ascending: [Double] = []
        var v = lo
        while v <= hi + 1e-9 {
            ascending.append((v * 500).rounded() / 500)
            v += step
        }
        return (lo, hi, step, Array(ascending.reversed()))
    }

    private var chartYRange: Double {
        let y = yAxisLayout
        let r = y.maxY - y.minY
        return r > 1e-9 ? r : Self.yAxisPreferredStep
    }

    private func xPosition(forSlotIndex index: Int, width: CGFloat) -> CGFloat {
        guard Self.windowDayCount > 1 else { return width / 2 }
        return width * CGFloat(index) / CGFloat(Self.windowDayCount - 1)
    }

    var body: some View {
        if !hasAnyWeightInWindow {
            VStack(spacing: 12) {
                Text("体重データがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("体重を記録するとグラフが表示されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        } else {
            let yLayout = yAxisLayout
            let yMin = yLayout.minY
            let yTicks = yLayout.ticksDescending
            let yRange = chartYRange

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    GeometryReader { labelGeo in
                        let h = labelGeo.size.height
                        let n = yTicks.count
                        ZStack(alignment: .topLeading) {
                            ForEach(Array(yTicks.enumerated()), id: \.offset) { i, w in
                                let y = n <= 1 ? h / 2 : h * CGFloat(i) / CGFloat(n - 1)
                                Text(String(format: "%.1f", w))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .position(x: labelGeo.size.width - 12, y: y)
                            }
                        }
                    }
                    .frame(width: 36, height: 200)
                    .padding(.trailing, 4)

                    VStack(spacing: 0) {
                        GeometryReader { geometry in
                            let h = geometry.size.height
                            let w = geometry.size.width
                            let tickCount = yTicks.count
                            ZStack {
                                Path { path in
                                    guard tickCount > 0 else { return }
                                    if tickCount == 1 {
                                        let y = h / 2
                                        path.move(to: CGPoint(x: 0, y: y))
                                        path.addLine(to: CGPoint(x: w, y: y))
                                    } else {
                                        for i in 0..<tickCount {
                                            let y = h * CGFloat(i) / CGFloat(tickCount - 1)
                                            path.move(to: CGPoint(x: 0, y: y))
                                            path.addLine(to: CGPoint(x: w, y: y))
                                        }
                                    }
                                }
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)

                                if plottedPoints.count > 1 {
                                    Path { path in
                                        var started = false
                                        for point in plottedPoints {
                                            let x = xPosition(forSlotIndex: point.slotIndex, width: w)
                                            let normalized = (point.weight - yMin) / yRange
                                            let y = h * (1 - CGFloat(normalized))
                                            if !started {
                                                path.move(to: CGPoint(x: x, y: y))
                                                started = true
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                    .stroke(Color.red, lineWidth: 3)
                                }

                                ForEach(plottedPoints, id: \.slotIndex) { point in
                                    let x = xPosition(forSlotIndex: point.slotIndex, width: w)
                                    let normalized = (point.weight - yMin) / yRange
                                    let y = h * (1 - CGFloat(normalized))

                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .position(x: x, y: y)
                                }
                            }
                        }
                        .frame(height: 200)

                        GeometryReader { dateGeometry in
                            let w = dateGeometry.size.width
                            ZStack {
                                ForEach(Array(rollingWindowDays.enumerated()), id: \.offset) { index, day in
                                    Text(formatDateShort(day))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                        .position(
                                            x: xPosition(forSlotIndex: index, width: w),
                                            y: 15
                                        )
                                }
                            }
                        }
                        .frame(height: 30)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
    }

    private func formatDateShort(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
}

#Preview {
    WeightChartView(weightEntries: [
        WeightEntry(id: 1, userId: UUID(), date: Date(), weight: 65.0, createdAt: Date(), updatedAt: Date()),
        WeightEntry(id: 2, userId: UUID(), date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), weight: 64.5, createdAt: Date(), updatedAt: Date()),
        WeightEntry(id: 3, userId: UUID(), date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), weight: 64.8, createdAt: Date(), updatedAt: Date())
    ])
    .padding()
}

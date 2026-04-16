//
//  WeightChartView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct WeightChartView: View {
    let weightEntries: [WeightEntry]
    
    private var chartData: [(date: Date, weight: Double)] {
        weightEntries.map { ($0.date, $0.weight) }
    }
    
    private var minWeight: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.weight }.min() ?? 0
    }
    
    private var maxWeight: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.weight }.max() ?? 0
    }

    /// 縦軸: 0.2kg 刻みを基本にし、メモリ本数が多すぎるときだけ 0.4, 0.6 … に広げる
    private static let yAxisPreferredStep: Double = 0.2
    private static let yAxisMaxTicks: Int = 11

    private var yAxisLayout: (minY: Double, maxY: Double, step: Double, ticksDescending: [Double]) {
        guard !chartData.isEmpty else {
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
            ascending.append((v * 500).rounded() / 500) // 0.2 刻みの丸め誤差抑制
            v += step
        }
        return (lo, hi, step, Array(ascending.reversed()))
    }

    private var chartYRange: Double {
        let y = yAxisLayout
        let r = y.maxY - y.minY
        return r > 1e-9 ? r : Self.yAxisPreferredStep
    }
    
    // 表示する日付のインデックスを計算（適切に間引く）
    private var visibleDateIndices: [Int] {
        guard chartData.count > 1 else {
            return chartData.isEmpty ? [] : [0]
        }
        
        let maxLabels = 7 // 最大表示ラベル数
        if chartData.count <= maxLabels {
            return Array(0..<chartData.count)
        }
        
        // 均等に間引く
        let step = Double(chartData.count - 1) / Double(maxLabels - 1)
        var indices: [Int] = []
        for i in 0..<maxLabels {
            let index = Int(round(step * Double(i)))
            if !indices.contains(index) {
                indices.append(index)
            }
        }
        
        // 最後のインデックスを必ず含める
        if indices.last != chartData.count - 1 {
            indices.append(chartData.count - 1)
        }
        
        return indices
    }
    
    var body: some View {
        if weightEntries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
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
                Text("体重の変化")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                
                // グラフエリア
                HStack(alignment: .top, spacing: 8) {
                    // 縦軸（0.2kg 基準のメモリ）
                    GeometryReader { labelGeo in
                        let h = labelGeo.size.height
                        let n = yTicks.count
                        ZStack(alignment: .topLeading) {
                            ForEach(Array(yTicks.enumerated()), id: \.offset) { i, w in
                                let y = n <= 1 ? h / 2 : h * CGFloat(i) / CGFloat(n - 1)
                                Text(String(format: "%.1f", w))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .position(x: labelGeo.size.width - 8, y: y)
                            }
                        }
                    }
                    .frame(width: 52, height: 200)
                    .padding(.trailing, 2)
                    
                    // グラフ本体
                    VStack(spacing: 0) {
                        GeometryReader { geometry in
                            let h = geometry.size.height
                            let w = geometry.size.width
                            let tickCount = yTicks.count
                            ZStack {
                                // 背景グリッド（横線＝メモリ位置に一致）
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
                                
                                // 折れ線グラフ
                                if chartData.count > 1 {
                                    Path { path in
                                        for (index, data) in chartData.enumerated() {
                                            let x = w * CGFloat(index) / CGFloat(chartData.count - 1)
                                            let normalized = (data.weight - yMin) / yRange
                                            let y = h * (1 - CGFloat(normalized))
                                            
                                            if index == 0 {
                                                path.move(to: CGPoint(x: x, y: y))
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                    .stroke(Color.purple, lineWidth: 3)
                                    
                                    // データポイント
                                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                                        let x = w * CGFloat(index) / CGFloat(chartData.count - 1)
                                        let normalized = (data.weight - yMin) / yRange
                                        let y = h * (1 - CGFloat(normalized))
                                        
                                        Circle()
                                            .fill(Color.purple)
                                            .frame(width: 8, height: 8)
                                            .position(x: x, y: y)
                                    }
                                } else if chartData.count == 1 {
                                    let normalized = (chartData[0].weight - yMin) / yRange
                                    let y = h * (1 - CGFloat(normalized))
                                    
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 8, height: 8)
                                        .position(x: w / 2, y: y)
                                }
                            }
                        }
                        .frame(height: 200)
                        
                        // 横軸（日付）
                        if chartData.count > 1 {
                            GeometryReader { dateGeometry in
                                ZStack {
                                    ForEach(visibleDateIndices, id: \.self) { index in
                                        let data = chartData[index]
                                        // グラフ上の実際のX位置を計算（データポイントの位置と一致させる）
                                        let xPosition = dateGeometry.size.width * CGFloat(index) / CGFloat(chartData.count - 1)
                                        
                                        Text(formatDateShort(data.date))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.primary)
                                            .position(x: xPosition, y: 15)
                                    }
                                }
                            }
                            .frame(height: 30)
                            .padding(.top, 8)
                        } else if chartData.count == 1 {
                            Text(formatDateShort(chartData[0].date))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(height: 30)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 凡例と範囲表示
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最小: \(String(format: "%.1f", minWeight)) kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("最大: \(String(format: "%.1f", maxWeight)) kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(weightEntries.count)件の記録")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // 日付を短い形式でフォーマット（M/d）
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




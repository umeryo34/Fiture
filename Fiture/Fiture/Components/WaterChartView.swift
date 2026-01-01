//
//  WaterChartView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI
import Charts

struct WaterChartData: Identifiable {
    let id = UUID()
    let date: Date
    let totalMl: Double
}

struct WaterChartView: View {
    let chartData: [(date: Date, totalMl: Double)]
    
    private var waterData: [WaterChartData] {
        chartData.map { WaterChartData(date: $0.date, totalMl: $0.totalMl) }
    }
    
    private var maxMl: Double {
        guard !waterData.isEmpty else { return 2000 }
        return max(waterData.map { $0.totalMl }.max() ?? 2000, 2000)
    }
    
    var body: some View {
        if chartData.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("水のデータがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("水を記録するとグラフが表示されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // グラフ
                Chart(waterData) { data in
                    BarMark(
                        x: .value("日付", data.date, unit: .day),
                        y: .value("水量", data.totalMl)
                    )
                    .foregroundStyle(
                        data.totalMl >= 2000 ? Color.cyan :
                        data.totalMl >= 1500 ? Color.blue :
                        Color.gray
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 7))) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDateShort(date))
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 10)
                
                // 凡例
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                        Text("1500ml未満")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("1500-2000ml")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.cyan)
                            .frame(width: 12, height: 12)
                        Text("2000ml以上")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(chartData.count)日分")
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
    WaterChartView(chartData: [
        (date: Date(), totalMl: 1800),
        (date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), totalMl: 2200),
        (date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), totalMl: 1500)
    ])
    .padding()
}


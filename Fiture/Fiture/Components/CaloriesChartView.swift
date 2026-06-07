//
//  CaloriesChartView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI
import Charts

struct CaloriesChartData: Identifiable {
    let id = UUID()
    let date: Date
    let totalCalories: Double
}

struct CaloriesChartView: View {
    let chartData: [(date: Date, totalCalories: Double)]
    
    private var caloriesData: [CaloriesChartData] {
        chartData.map { CaloriesChartData(date: $0.date, totalCalories: $0.totalCalories) }
    }
    
    var body: some View {
        if chartData.isEmpty {
            VStack(spacing: 12) {
                Text("カロリーデータがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("食事を記録するとグラフが表示されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // グラフ
                Chart(caloriesData) { data in
                    BarMark(
                        x: .value("日付", data.date, unit: .day),
                        y: .value("カロリー", data.totalCalories)
                    )
                    .foregroundStyle(Color.red)
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
                
                HStack {
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
    CaloriesChartView(chartData: [
        (date: Date(), totalCalories: 1800),
        (date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), totalCalories: 2200),
        (date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), totalCalories: 1500)
    ])
    .padding()
}


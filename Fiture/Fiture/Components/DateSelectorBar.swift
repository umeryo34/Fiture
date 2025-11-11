//
//  DateSelectorBar.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/10.
//

import SwiftUI

struct DateSelectorBar: View {
    @Binding var selectedDate: Date
    let onDateChange: (Date) -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 前の日
            Button(action: {
                let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                selectedDate = newDate
                onDateChange(newDate)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
            
            // 現在の日付
            Text(dateFormatter.string(from: selectedDate))
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            // 次の日（今日まで）
            Button(action: {
                let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                let today = Calendar.current.startOfDay(for: Date())
                if Calendar.current.startOfDay(for: newDate) <= today {
                    selectedDate = newDate
                    onDateChange(newDate)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(canGoForward ? .primary : .gray)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
            .disabled(!canGoForward)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var canGoForward: Bool {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: nextDay) <= today
    }
}

#Preview {
    @State var date = Date()
    return DateSelectorBar(selectedDate: $date) { _ in }
}


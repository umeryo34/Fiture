//
//  CaloriesImageDisplayView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct CaloriesImageDisplayView: View {
    let totalCalories: Double
    let targetCalories: Double?
    
    // カロリーに応じた画像名を決定
    private var imageName: String {
        guard let target = targetCalories, target > 0 else {
            // 目標が設定されていない場合はデフォルト画像
            return "calories"
        }
        
        let percentage = (totalCalories / target) * 100
        
        // 目標の120%以上の場合、fat画像を表示
        if percentage >= 120 {
            return "fat"
        } else {
            // それ以外は通常のcalories画像
            return "calories"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 画像表示
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // カロリー情報
            if let target = targetCalories, target > 0 {
                VStack(spacing: 8) {
                    Text("\(String(format: "%.0f", totalCalories)) / \(String(format: "%.0f", target)) kcal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // 進捗バー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(progressColor)
                                .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(min(totalCalories / target, 1.0))), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
            } else {
                Text("\(String(format: "%.0f", totalCalories)) kcal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 20)
    }
    
    // 進捗バーの色を決定
    private var progressColor: Color {
        guard let target = targetCalories, target > 0 else {
            return .green
        }
        
        let percentage = (totalCalories / target) * 100
        
        if percentage >= 120 {
            return .red
        } else if percentage >= 80 {
            return .green
        } else {
            return .orange
        }
    }
}

#Preview {
    CaloriesImageDisplayView(totalCalories: 1500, targetCalories: 2000)
}


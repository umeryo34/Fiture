//
//  AchievementView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/24.
//

import SwiftUI

struct AchievementView: View {
    var body: some View {
        VStack {
            Image(systemName: "medal")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .padding()
            Text("達成済み")
                .font(.title2)
                .fontWeight(.semibold)
            Text("目標に向けて行動しよう")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    AchievementView()
}

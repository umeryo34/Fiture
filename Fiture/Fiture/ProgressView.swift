//
//  ProgressView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/10/24.
//

import SwiftUI

struct ProgressView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            Text("進捗")
                .font(.title2)
                .fontWeight(.semibold)
            Text("あなたの成長を確認")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ProgressView()
}

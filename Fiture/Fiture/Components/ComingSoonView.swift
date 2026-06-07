//
//  ComingSoonView.swift
//  Fiture
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    let systemImage: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Coming Soon")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(title)は現在準備中です。\n今後のアップデートでお届けします。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

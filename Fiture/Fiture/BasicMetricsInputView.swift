//
//  BasicMetricsInputView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/23.
//

import SwiftUI

struct BasicMetricsInputView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var heightCm: Double?
    @Binding var weightKg: Double?

    @State private var heightPickerCm = 170
    @State private var weightTenthKg = 600

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("身長")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("身長", selection: $heightPickerCm) {
                            ForEach(Self.heightCmRange, id: \.self) { cm in
                                Text("\(cm) cm").tag(cm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 4) {
                        Text("体重")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("体重", selection: $weightTenthKg) {
                            ForEach(Self.weightTenthRange, id: \.self) { tenth in
                                Text(String(format: "%.1f kg", Double(tenth) / 10)).tag(tenth)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 200)

                Spacer()

                Button("保存") {
                    saveAndClose()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
            .navigationTitle("身長・体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear {
                if let h = heightCm {
                    heightPickerCm = min(250, max(100, Int(h.rounded())))
                } else {
                    heightPickerCm = 170
                }
                if let w = weightKg {
                    let tenth = Int((w * 10).rounded())
                    weightTenthKg = min(3000, max(200, tenth))
                } else {
                    weightTenthKg = 600
                }
            }
        }
    }

    private func saveAndClose() {
        heightCm = Double(heightPickerCm)
        weightKg = Double(weightTenthKg) / 10
        dismiss()
    }

    private static let heightCmRange = Array(100...250)
    private static let weightTenthRange: [Int] = Array(stride(from: 200, through: 3000, by: 1))
}

#Preview {
    BasicMetricsInputView(heightCm: .constant(170), weightKg: .constant(60))
}

//
//  HealthInformationSourcesView.swift
//  Fiture
//

import SwiftUI

struct HealthInformationSourcesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(HealthInformationSources.disclaimer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("重要")
                }

                ForEach(HealthSourceCategory.allCases) { category in
                    Section {
                        ForEach(HealthInformationSources.sources(for: category)) { source in
                            sourceRow(source)
                        }
                    } header: {
                        Text(category.rawValue)
                    }
                }
            }
            .navigationTitle("健康情報の出典")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sourceRow(_ source: HealthInformationSource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(source.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Text(source.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("本アプリでの利用: \(source.usedInApp)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: source.url) {
                HStack(spacing: 4) {
                    Image(systemName: "safari")
                    Text("出典を開く")
                }
                .font(.caption)
                .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 健康情報の出典画面を開くインラインリンク
struct HealthSourcesLink: View {
    var label: String = "健康情報の出典を見る"
    var systemImage: String = "book.closed"
    @State private var showingSources = false

    var body: some View {
        Button {
            showingSources = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSources) {
            HealthInformationSourcesView()
        }
    }
}

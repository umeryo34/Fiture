//
//  HelpView.swift
//  Fiture
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let supportEmail = "fiture.support@gmail.com"

    private let faqItems: [(question: String, answer: String)] = [
        (
            "消費カロリーが 0 のままです",
            "設定アプリ → ヘルスケア → データアクセスとデバイス → Fiture で「アクティブエネルギー」の読み取りを許可してください。"
        ),
        (
            "Run を保存したのにすぐ反映されません",
            "HealthKit への反映に少し時間がかかることがあります。Home 画面を開き直すと更新される場合があります。"
        ),
        (
            "体重はどこに保存されますか？",
            "体重は端末内（本アプリのローカルデータ）に保存されます。HealthKit には保存しません。"
        ),
        (
            "食事を間違えて登録しました",
            "Home 画面のカロリー表示下にある「詳細」から、今日の食事一覧を開き、左スワイプで削除できます。"
        ),
        (
            "データはクラウドに送信されますか？",
            "いいえ。食事・体重・運動の記録は端末内に保存されます。消費カロリーのみ HealthKit から読み取ります。"
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    helpBullet(
                        title: "はじめかた",
                        items: [
                            "初回起動時に身長・体重・目標を入力します。",
                            "毎日、まず体重を記録してから食事を追加できます。",
                            "目標はユーザー画面の「目標を変更」からいつでも更新できます。"
                        ]
                    )
                }

                Section {
                    helpBullet(
                        title: "Home タブ",
                        items: [
                            "カロリー収支は「食事摂取 − HealthKit の消費カロリー」で表示します。",
                            "「食事を追加」で名前とカロリーを記録できます。",
                            "「詳細」から今日の食事を確認・削除できます。",
                            "体重グラフは直近 7 日分を表示します。"
                        ]
                    )
                }

                Section {
                    helpBullet(
                        title: "食事の記録",
                        items: [
                            "名前を入力し、定規スクロールでカロリーを選びます。",
                            "過去に入力した食事名は候補として表示されます。"
                        ]
                    )
                }

                Section {
                    helpBullet(
                        title: "Run タブ",
                        items: [
                            "ジムのトレッドミル向けに、ウォーキング・ランニングを記録できます。",
                            "保存すると HealthKit にワークアウトが記録されます。",
                            "消費カロリーは HealthKit のアクティブエネルギーを読み取って Home に反映します。"
                        ]
                    )
                }

                Section {
                    helpBullet(
                        title: "目標超過時",
                        items: [
                            "食事 − 消費が 1 日の目標を超えると、Run タブに運動時間の目安を表示します。",
                            "他のタブにいるときは、Run タブの上に吹き出しでお知らせします。"
                        ]
                    )
                }

                Section {
                    ForEach(faqItems.indices, id: \.self) { index in
                        DisclosureGroup(faqItems[index].question) {
                            Text(faqItems[index].answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("よくある質問")
                }

                Section {
                    Link(destination: URL(string: "mailto:\(supportEmail)")!) {
                        LabeledContent("お問い合わせ", value: supportEmail)
                    }
                    Text("不具合のご報告時は、iOS のバージョンとお使いの機種名もお知らせください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("サポート")
                }
            }
            .navigationTitle("ヘルプ")
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
    private func helpBullet(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

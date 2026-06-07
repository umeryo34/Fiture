//
//  TermsOfServiceView.swift
//  Fiture
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            HTMLWebView(html: Self.termsHTML)
                .navigationTitle("利用規約")
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

    private static let termsHTML = """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Fiture 利用規約</title>
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.8;">

        <h1>Fiture 利用規約</h1>

        <p>最終更新日：2026年6月</p>

        <p>
            本利用規約（以下、「本規約」）は、
            Fiture（以下、「本アプリ」）の利用条件を定めるものです。
            ユーザーは、本規約に同意したうえで本アプリを利用するものとします。
        </p>

        <h2>第1条（適用）</h2>

        <p>
            本規約は、本アプリの利用に関して、
            ユーザーと運営者との間の一切の関係に適用されます。
        </p>

        <h2>第2条（利用について）</h2>

        <p>
            ユーザーは、自己の責任において本アプリを利用するものとします。
        </p>

        <h2>第3条（禁止事項）</h2>

        <p>ユーザーは以下の行為を行ってはなりません。</p>

        <ul>
            <li>法令または公序良俗に違反する行為</li>
            <li>本アプリの運営を妨害する行為</li>
            <li>不正アクセスまたはその試み</li>
            <li>その他、運営者が不適切と判断する行為</li>
        </ul>

        <h2>第4条（免責事項）</h2>

        <p>
            本アプリは健康管理を支援することを目的としており、
            医療行為、診断、治療を提供するものではありません。
        </p>

        <p>
            本アプリが提供する情報は参考情報であり、
            その正確性、完全性、有用性を保証するものではありません。
        </p>

        <p>
            本アプリの利用によって生じた損害について、
            運営者は責任を負わないものとします。
        </p>

        <h2>第5条（サービス内容の変更）</h2>

        <p>
            運営者は、ユーザーへの事前通知なく、
            本アプリの内容を変更または提供を終了することがあります。
        </p>

        <h2>第6条（利用規約の変更）</h2>

        <p>
            運営者は、必要に応じて本規約を変更することができます。
        </p>

        <h2>第7条（お問い合わせ）</h2>

        <p>
            本規約に関するお問い合わせは、
            以下のメールアドレスまでお願いいたします。
        </p>

        <p>
            Email：fiture.support@gmail.com
        </p>

    </body>
    </html>
    """
}

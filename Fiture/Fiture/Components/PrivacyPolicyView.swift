//
//  PrivacyPolicyView.swift
//  Fiture
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PrivacyPolicyWebView(html: Self.privacyPolicyHTML)
                .navigationTitle("プライバシー")
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

    private static let privacyPolicyHTML = """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Fiture プライバシーポリシー</title>
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.8;">

        <h1>Fiture プライバシーポリシー</h1>

        <p>最終更新日：2026年6月</p>

        <p>
            Fiture（以下、「本アプリ」）は、ユーザーのプライバシーを尊重し、
            個人情報を適切に取り扱います。
        </p>

        <p>
            お問い合わせ：
            <strong>fiture.support@gmail.com</strong>
        </p>

        <h2>1. 取得する情報</h2>

        <h3>ユーザーが入力する情報</h3>
        <ul>
            <li>身長</li>
            <li>体重</li>
            <li>目標体重</li>
            <li>食事記録</li>
            <li>運動記録</li>
        </ul>

        <h3>HealthKitから取得する情報</h3>
        <p>
            本アプリは、ユーザーの許可を得た場合に限り、
            Apple HealthKitから以下の情報を取得します。
        </p>

        <ul>
            <li>アクティブエネルギー（消費カロリー）</li>
        </ul>

        <h3>HealthKitへ保存する情報</h3>
        <p>
            本アプリは、ユーザーの許可を得た場合に限り、
            以下の情報をHealthKitへ保存します。
        </p>

        <ul>
            <li>ワークアウト記録</li>
            <li>運動距離</li>
            <li>アクティブエネルギー</li>
        </ul>

        <h2>2. 利用目的</h2>

        <ul>
            <li>健康管理機能の提供</li>
            <li>消費カロリーの計算</li>
            <li>運動記録の管理</li>
            <li>目標体重管理</li>
            <li>アプリの改善および品質向上</li>
            <li>不正利用防止</li>
        </ul>

        <h2>3. データの保存</h2>

        <p>
            本アプリが保存するデータは、主にユーザーの端末内に保存されます。
        </p>

        <p>
            運営者が管理する外部サーバーへ個人データを送信または保存することはありません。
        </p>

        <h2>4. 第三者への提供</h2>

        <p>
            本アプリは、法令に基づく場合を除き、
            取得した情報を第三者へ提供することはありません。
        </p>

        <h2>5. HealthKitデータの取り扱い</h2>

        <p>
            HealthKitから取得したデータは、
            本アプリの機能提供のためにのみ利用します。
        </p>

        <p>
            HealthKitデータを広告、マーケティング、
            データ分析、または第三者への販売目的で利用することはありません。
        </p>

        <h2>6. データの削除</h2>

        <ul>
            <li>アプリを削除する</li>
            <li>Healthアプリから本アプリとの連携を解除する</li>
        </ul>

        <h2>7. お問い合わせ</h2>

        <p>
            Email：fiture.support@gmail.com
        </p>

        <h2>8. プライバシーポリシーの変更</h2>

        <p>
            本ポリシーは、必要に応じて改定される場合があります。
        </p>

        <p>
            変更後の内容は、本ページに掲載した時点で効力を生じるものとします。
        </p>

    </body>
    </html>
    """
}

private struct PrivacyPolicyWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

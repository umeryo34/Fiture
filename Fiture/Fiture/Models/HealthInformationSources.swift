//
//  HealthInformationSources.swift
//  Fiture
//
//  App Store Guideline 1.4.1 対応: 健康・栄養情報の出典
//

import Foundation

enum HealthSourceCategory: String, CaseIterable, Identifiable {
    case calorieTarget = "1日のカロリー目標"
    case exercise = "運動時間の目安"
    case healthData = "消費カロリーの表示"

    var id: String { rawValue }
}

struct HealthInformationSource: Identifiable {
    let id: String
    let category: HealthSourceCategory
    let title: String
    let summary: String
    let url: URL
    let usedInApp: String
}

enum HealthInformationSources {
    static let disclaimer =
        "本アプリが表示する数値は一般的な栄養・運動科学の式に基づく推定値です。医療行為・診断・治療を目的としたものではありません。体調や持病がある場合は、医師や管理栄養士などの専門家にご相談ください。"

    static let all: [HealthInformationSource] = [
        HealthInformationSource(
            id: "bmr-mifflin",
            category: .calorieTarget,
            title: "基礎代謝量（BMR）— ミフリン・サン・ジェオール式",
            summary: "身長・体重・年齢・性別から基礎代謝量を推定する式。本アプリの「推定BMR」に使用しています。",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/2305711/")!,
            usedInApp: "目標設定のカロリー目安"
        ),
        HealthInformationSource(
            id: "tdee-pal",
            category: .calorieTarget,
            title: "1日の総消費エネルギー（TDEE）— 身体活動レベル係数",
            summary: "BMR に活動係数（1.2 / 1.55 / 1.725）を掛けて TDEE を算出。FAO/WHO/UNU の身体活動レベル（PAL）に基づく一般的な係数です。",
            url: URL(string: "https://www.fao.org/4/x0242e/x0242e06.htm")!,
            usedInApp: "目標設定の活動レベル選択・推定TDEE"
        ),
        HealthInformationSource(
            id: "deficit-500",
            category: .calorieTarget,
            title: "減量時のカロリー不足（約500 kcal/日）",
            summary: "減量目標では TDEE から約 500 kcal を控えた摂取量を目安とします。安全な減量ペースの一般的な指針です。",
            url: URL(string: "https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html")!,
            usedInApp: "体組成目標「減量」の1日摂取目標"
        ),
        HealthInformationSource(
            id: "fat-energy",
            category: .calorieTarget,
            title: "体脂肪1kgあたりのエネルギー（約7,200 kcal）",
            summary: "目標体重と期限から1日の不足分を逆算する際、1kgの体脂肪相当を約7,200 kcalとみなします。",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/18429030/")!,
            usedInApp: "目標体重・達成日からのペース計算"
        ),
        HealthInformationSource(
            id: "min-kcal",
            category: .calorieTarget,
            title: "摂取目標の下限（1,200 kcal/日）",
            summary: "過度な制限を避けるため、算出した摂取目標が 1,200 kcal 未満にならないよう下限を設けています。",
            url: URL(string: "https://www.niddk.nih.gov/health-information/weight-management")!,
            usedInApp: "1日の摂取目標の安全域"
        ),
        HealthInformationSource(
            id: "protein",
            category: .calorieTarget,
            title: "タンパク質の目安（体重×1.8 g/日）",
            summary: "活動的な成人向けのタンパク質摂取の一般的な目安として、体重1kgあたり1.8gを参考値にしています。",
            url: URL(string: "https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0177-8")!,
            usedInApp: "目標設定のタンパク質目安"
        ),
        HealthInformationSource(
            id: "acsm-treadmill",
            category: .exercise,
            title: "ACSM トレッドミル式（ウォーキング・ランニング）",
            summary: "速度・勾配・体重から酸素摂取量（VO₂）を推定し、運動による消費カロリーを計算。目標超過分の運動時間見積もりに使用しています。",
            url: URL(string: "https://www.acsm.org/education-resources/trending-topics-resources/physical-activity-guidelines")!,
            usedInApp: "Runタブの運動時間の目安"
        ),
        HealthInformationSource(
            id: "metabolic-conversion",
            category: .exercise,
            title: "酸素摂取量からカロリーへの換算（5 kcal/L O₂）",
            summary: "運動生理学で広く用いられる換算係数（1L O₂ ≈ 5 kcal）を用いて、VO₂から消費カロリーを算出しています。",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/1898244/")!,
            usedInApp: "Runタブの運動時間の目安"
        ),
        HealthInformationSource(
            id: "healthkit-active-energy",
            category: .healthData,
            title: "Apple HealthKit — アクティブエネルギー",
            summary: "Home画面の消費カロリーは、ヘルスアプリの「アクティブエネルギー」（その日の合計）を読み取って表示しています。",
            url: URL(string: "https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/1615771-activeenergyburned")!,
            usedInApp: "Homeタブの消費カロリー表示"
        )
    ]

    static func sources(for category: HealthSourceCategory) -> [HealthInformationSource] {
        all.filter { $0.category == category }
    }
}

//
//  NutritionAPI.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//
//  Edamam Recipe Search APIを使用して料理の栄養情報を取得します。
//  APIキーの取得方法:
//  1. https://developer.edamam.com/ にアクセス
//  2. アカウントを作成（無料）
//  3. "Recipe Search API" を選択
//  4. Application ID と Application Key を取得
//  5. Info.plist の edamamAppId と edamamAppKey に設定
//  無料プラン: 1日5,000リクエストまで（レート制限あり）

import Foundation

// 栄養情報APIのレスポンスモデル
struct FoodSearchResult: Identifiable, Codable {
    let id: String
    let label: String
    let calories: Double
    let nutrients: Nutrients?
    
    struct Nutrients: Codable {
        let calories: Double?
        let protein: Double?
        let fat: Double?
        let carbs: Double?
    }
}

struct FoodSearchResponse: Codable {
    let hits: [RecipeHit]
    
    struct RecipeHit: Codable {
        let recipe: Recipe
        
        struct Recipe: Codable {
            let uri: String
            let label: String
            let calories: Double
            let totalNutrients: TotalNutrients?
            
            struct TotalNutrients: Codable {
                let ENERC_KCAL: NutrientValue?
                let PROCNT: NutrientValue?
                let FAT: NutrientValue?
                let CHOCDF: NutrientValue?
                
                struct NutrientValue: Codable {
                    let label: String
                    let quantity: Double
                    let unit: String
                }
            }
        }
    }
}

// Edamam Recipe Search API サービス
class NutritionAPI {
    static let shared = NutritionAPI()
    
    private let appId: String
    private let appKey: String
    // Edamam Recipe Search API エンドポイント（料理の栄養情報を取得）
    private let baseURL = "https://api.edamam.com/api/recipes/v2"
    
    private init() {
        // Info.plistからAPIキーを読み込む
        guard let appId = Bundle.main.object(forInfoDictionaryKey: "edamamAppId") as? String,
              let appKey = Bundle.main.object(forInfoDictionaryKey: "edamamAppKey") as? String else {
            // フォールバック: 環境変数から読み込むか、デフォルト値を使用
            self.appId = ""
            self.appKey = ""
            print("警告: Edamam APIキーが設定されていません。Info.plistにedamamAppIdとedamamAppKeyを追加してください。")
            return
        }
        // 空白文字を削除
        self.appId = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appKey = appKey.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Edamam API初期化:")
        print("  AppId: '\(self.appId)' (長さ: \(self.appId.count))")
        print("  AppKey: '\(self.appKey.prefix(8))...' (長さ: \(self.appKey.count))")
        
        // APIキーが空でないことを確認
        if self.appId.isEmpty || self.appKey.isEmpty {
            print("警告: APIキーが空です！")
        }
    }
    
    // 食べ物を検索してカロリー情報を取得
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        guard !appId.isEmpty && !appKey.isEmpty else {
            print("エラー: APIキーが設定されていません")
            throw NutritionAPIError.apiKeyNotConfigured
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("エラー: クエリのエンコードに失敗しました: \(query)")
            throw NutritionAPIError.invalidQuery
        }
        
        // Edamam Recipe Search APIのパラメータ
        // URLコンポーネントを使用して安全にURLを構築
        var urlComponents = URLComponents(string: baseURL)
        urlComponents?.queryItems = [
            URLQueryItem(name: "type", value: "public"),
            URLQueryItem(name: "q", value: query), // 検索クエリ
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey)
        ]
        
        guard let url = urlComponents?.url else {
            print("エラー: 無効なURL")
            throw NutritionAPIError.invalidURL
        }
        
        print("APIリクエストURL: \(url.absoluteString.replacingOccurrences(of: appKey, with: "***"))")
        print("AppId確認: '\(appId)' (長さ: \(appId.count))")
        print("AppKey確認: '\(appKey.prefix(8))...' (長さ: \(appKey.count))")
        print("検索クエリ: '\(query)'")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("エラー: 無効なHTTPレスポンス")
                throw NutritionAPIError.invalidResponse
            }
            
            print("HTTPステータス: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "不明"
                print("HTTPエラー: \(httpResponse.statusCode)")
                print("エラーレスポンス: \(errorBody.prefix(500))")
                
                // 401エラーの場合、APIキーの問題を明確に示す
                if httpResponse.statusCode == 401 {
                    print("⚠️ 認証エラー: APIキーが無効か、アプリケーションが正しく登録されていません。")
                    print("Edamam Developer Portal (https://developer.edamam.com/) で以下を確認してください:")
                    print("1. アプリケーションが作成されているか")
                    print("2. 'Recipe Search API' が有効になっているか")
                    print("3. Application ID と Application Key が正しいか")
                }
                
                // 429エラーの場合、レート制限を説明
                if httpResponse.statusCode == 429 {
                    print("⚠️ レート制限エラー: リクエストが多すぎます。")
                    print("しばらく待ってから再度お試しください。")
                }
                
                throw NutritionAPIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // デバッグ用: レスポンスデータを確認
            if let jsonString = String(data: data, encoding: .utf8) {
                print("APIレスポンス: \(jsonString.prefix(500))")
            }
            
            let decoder = JSONDecoder()
            
            let searchResponse: FoodSearchResponse
            do {
                searchResponse = try decoder.decode(FoodSearchResponse.self, from: data)
            } catch let decodingError as DecodingError {
                print("デコードエラー詳細:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("型不一致: \(type), パス: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("値が見つからない: \(type), パス: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("キーが見つからない: \(key), パス: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("データ破損: \(context)")
                @unknown default:
                    print("不明なエラー: \(decodingError)")
                }
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("レスポンスJSON: \(jsonString.prefix(1000))")
                }
                throw NutritionAPIError.decodingError
            } catch {
                print("デコードエラー: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("レスポンスJSON: \(jsonString.prefix(1000))")
                }
                throw NutritionAPIError.decodingError
            }
            
            print("検索結果: \(searchResponse.hits.count)件")
            
            return searchResponse.hits.map { hit in
                let recipe = hit.recipe
                let calories = recipe.calories
                let nutrients = recipe.totalNutrients
                
                return FoodSearchResult(
                    id: recipe.uri,
                    label: recipe.label,
                    calories: calories,
                    nutrients: FoodSearchResult.Nutrients(
                        calories: nutrients?.ENERC_KCAL?.quantity,
                        protein: nutrients?.PROCNT?.quantity,
                        fat: nutrients?.FAT?.quantity,
                        carbs: nutrients?.CHOCDF?.quantity
                    )
                )
            }
        } catch let error as NutritionAPIError {
            throw error
        } catch {
            print("予期しないエラー: \(error.localizedDescription)")
            throw error
        }
    }
}

enum NutritionAPIError: LocalizedError {
    case apiKeyNotConfigured
    case invalidQuery
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "APIキーが設定されていません"
        case .invalidQuery:
            return "無効な検索クエリです"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .httpError(let statusCode):
            return "HTTPエラー: \(statusCode)"
        case .decodingError:
            return "データの解析に失敗しました"
        }
    }
}

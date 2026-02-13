//
//  FoodNameHistory.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import Foundation

// 食べ物名と栄養素のペア
struct FoodEntry: Codable {
    let foodName: String
    let calories: Double
    let protein: Double?
    let fat: Double?
    let carbs: Double?
}

// 食べ物名の履歴を管理するクラス
class FoodNameHistory {
    static let shared = FoodNameHistory()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "foodNameHistory"
    private let maxHistoryCount = 50 // 最大保存数
    
    private init() {}
    
    // 食べ物名と栄養素を履歴に追加
    func addFoodEntry(foodName: String, calories: Double, protein: Double? = nil, fat: Double? = nil, carbs: Double? = nil) {
        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        var history = getHistory()
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newEntry = FoodEntry(foodName: trimmedName, calories: calories, protein: protein, fat: fat, carbs: carbs)
        
        // 既に存在する場合は削除してから先頭に追加（最近使ったものを上に）
        history.removeAll { $0.foodName.lowercased() == trimmedName.lowercased() }
        history.insert(newEntry, at: 0)
        
        // 最大数を超えた場合は古いものを削除
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    // 検索クエリに一致する食べ物エントリを取得
    func searchFoodEntries(query: String) -> [FoodEntry] {
        guard !query.isEmpty else { return [] }
        
        let history = getHistory()
        let lowercasedQuery = query.lowercased()
        
        // 部分一致で検索（大文字小文字を区別しない）
        let filtered = history.filter { entry in
            entry.foodName.lowercased().contains(lowercasedQuery)
        }
        
        // 最大5件まで返す
        return Array(filtered.prefix(5))
    }
    
    // 全履歴を取得
    func getAllHistory() -> [FoodEntry] {
        return getHistory()
    }
    
    // 履歴をクリア
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    // プライベートメソッド: 履歴を取得
    private func getHistory() -> [FoodEntry] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([FoodEntry].self, from: data) else {
            return []
        }
        return history
    }
    
    // プライベートメソッド: 履歴を保存
    private func saveHistory(_ history: [FoodEntry]) {
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
}

//
//  CaloriesSearchView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/11/11.
//

import SwiftUI

struct CaloriesSearchView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var caloriesTargetManager: CaloriesTargetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var searchResults: [CaloriesEntry] = []
    @State private var isLoading: Bool = false
    @State private var searchDateRange: Int = 30 // 過去30日間を検索
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("食べ物名で検索", text: $searchText)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 検索範囲選択
                Picker("検索範囲", selection: $searchDateRange) {
                    Text("過去7日").tag(7)
                    Text("過去30日").tag(30)
                    Text("過去90日").tag(90)
                    Text("すべて").tag(365)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 検索結果
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("検索結果が見つかりませんでした")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("食べ物名を入力して検索")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(searchResults) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.foodName)
                                        .font(.headline)
                                    
                                    Text(formatDate(entry.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatTime(entry.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(String(format: "%.0f", entry.calories)) kcal")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("食事を検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                searchResults = []
            } else if newValue.count >= 2 {
                // 2文字以上入力されたら自動検索
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty, let userId = authManager.currentUser?.id else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -searchDateRange, to: endDate) ?? endDate
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone.current
                let startDateString = dateFormatter.string(from: startDate)
                let endDateString = dateFormatter.string(from: endDate)
                
                let userIdString = userId.uuidString.lowercased()
                
                // 食べ物名で検索（部分一致）
                let response: [CaloriesEntry] = try await SupabaseManager.shared.client
                    .from("calories_entries")
                    .select()
                    .eq("user_id", value: userIdString)
                    .gte("date", value: startDateString)
                    .lte("date", value: endDateString)
                    .ilike("food_name", pattern: "%\(searchText)%")
                    .order("date", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    searchResults = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("検索エラー: \(error)")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年M月d日"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CaloriesSearchView()
        .environmentObject(AuthManager.shared)
        .environmentObject(CaloriesTargetManager())
}


//
//  CalrendarView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/04/16.
//

import SwiftUI
import UIKit

struct CalendarView: View {
    private let calendar = Calendar.current
    @EnvironmentObject private var authManager: AuthManager

    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void

    @State private var weekStartDate: Date
    @State private var entriesByDayKey: [String: [CaloriesEntry]] = [:]
    @State private var quickAddSlot: MealSlot = .breakfast
    @State private var quickAddPhotoImage: UIImage?
    @State private var photoPathByCellKey: [String: String] = [:]
    @State private var previewImage: UIImage?
    @State private var showingPhotoPreview = false
    @State private var previewTargetDate: Date
    @State private var previewTargetSlot: MealSlot
    @State private var showingCameraCapture = false
    @State private var showingLibraryPicker = false

    enum MealSlot: String, CaseIterable {
        case breakfast
        case lunch
        case dinner
        case snack

        var title: String {
            switch self {
            case .breakfast: return "朝食"
            case .lunch: return "昼食"
            case .dinner: return "夕食"
            case .snack: return "間食"
            }
        }
    }

    init(selectedDate: Binding<Date>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        _weekStartDate = State(initialValue: Calendar.current.startOfWeek(for: selectedDate.wrappedValue))
        _previewTargetDate = State(initialValue: selectedDate.wrappedValue)
        _previewTargetSlot = State(initialValue: .breakfast)
    }

    var body: some View {
        VStack(spacing: 0) {
            weekHeader
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

            GeometryReader { proxy in
                let horizontalPadding: CGFloat = 14
                let containerWidth = proxy.size.width - (horizontalPadding * 2)
                let dateColumnWidth: CGFloat = 42
                let mealColumnWidth = floor((containerWidth - dateColumnWidth) / CGFloat(MealSlot.allCases.count))

                VStack(spacing: 0) {
                    mealHeaderRow(dateColumnWidth: dateColumnWidth, mealColumnWidth: mealColumnWidth)
                    Divider()
                    ForEach(weekDates, id: \.self) { day in
                        weekRow(day: day, dateColumnWidth: dateColumnWidth, mealColumnWidth: mealColumnWidth)
                        Divider()
                    }
                }
                .frame(width: containerWidth, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, horizontalPadding)
            }
            .frame(height: 7 * 59 + 40)

            Spacer(minLength: 8)
        }
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            quickAddPanel
        }
        .navigationTitle("カレンダー")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            weekStartDate = calendar.startOfWeek(for: selectedDate)
            loadWeekEntries()
            loadPhotoMappings()
        }
        .onChange(of: selectedDate) { _, newDate in
            weekStartDate = calendar.startOfWeek(for: newDate)
            loadWeekEntries()
        }
        .onChange(of: weekStartDate) { _, _ in
            loadWeekEntries()
            loadPhotoMappings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .caloriesDataDidUpdate)) { _ in
            loadWeekEntries()
            loadPhotoMappings()
        }
        .fullScreenCover(isPresented: $showingCameraCapture) {
            CalendarCameraEntryView(
                onCaptured: { image in
                    openPreview(with: image)
                },
                onCancel: {
                    showingCameraCapture = false
                }
            )
        }
        .sheet(isPresented: $showingLibraryPicker) {
            CalendarImagePicker(sourceType: .photoLibrary) { image in
                if let image {
                    openPreview(with: image)
                }
                showingLibraryPicker = false
            }
        }
        .sheet(isPresented: $showingPhotoPreview) {
            if let previewImage {
                CalendarCellPhotoPreviewView(
                    image: previewImage,
                    targetDate: $previewTargetDate,
                    targetSlot: $previewTargetSlot,
                    onClose: {
                        showingPhotoPreview = false
                    },
                    onSubmit: { image, targetDate, targetSlot in
                        quickAddPhotoImage = image
                        quickAddSlot = targetSlot
                        selectedDate = targetDate
                        savePhotoForCell(image: image, day: targetDate, slot: targetSlot)
                        showingPhotoPreview = false
                    }
                )
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)
            }

            Spacer()

            Text(weekRangeLabel)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }

    private func mealHeaderRow(dateColumnWidth: CGFloat, mealColumnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text("日付")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: dateColumnWidth, alignment: .leading)
                .padding(.leading, 2)
                .padding(.vertical, 8)

            ForEach(MealSlot.allCases, id: \.title) { slot in
                Text(slot.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: mealColumnWidth)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGray5))
    }

    private func weekRow(day: Date, dateColumnWidth: CGFloat, mealColumnWidth: CGFloat) -> some View {
        let dayKey = dateKey(day)
        let entries = entriesByDayKey[dayKey] ?? []
        let weekday = weekdayJP(day)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)

        return HStack(spacing: 0) {
            Button {
                selectedDate = day
                onDateSelected(day)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel(day))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .red : .primary)
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: dateColumnWidth, alignment: .leading)
                .padding(.leading, 2)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            ForEach(MealSlot.allCases, id: \.title) { slot in
                mealCell(entries: entries, slot: slot, day: day, isSelected: isSelected, mealColumnWidth: mealColumnWidth)
            }
        }
        .background(isSelected ? Color.red.opacity(0.08) : Color.clear)
    }

    private func mealCell(entries: [CaloriesEntry], slot: MealSlot, day: Date, isSelected: Bool, mealColumnWidth: CGFloat) -> some View {
        let items = entriesForSlot(entries, slot: slot)
        let total = items.reduce(0) { $0 + $1.calories }
        let hasEntry = !items.isEmpty
        let photoPath = photoPathByCellKey[cellKey(day: day, slot: slot)]

        return Button {
            selectedDate = day
            onDateSelected(day)
        } label: {
            ZStack {
                if let photoPath,
                   let image = UIImage(contentsOfFile: photoPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .opacity(0.75)
                }

                VStack(spacing: 2) {
                if hasEntry {
                    Text("\(Int(total.rounded()))kcal")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(photoPath == nil ? (isSelected ? .red : .primary) : .white)
                    Text("\(items.count)件")
                        .font(.caption2)
                        .foregroundColor(photoPath == nil ? .secondary : .white.opacity(0.95))
                } else {
                    Text("-")
                        .font(.caption)
                        .foregroundColor(photoPath == nil ? Color.secondary.opacity(0.8) : .white.opacity(0.95))
                    }
                }
            }
            .frame(width: mealColumnWidth)
            .frame(height: 58)
            .background(photoPath == nil ? Color(.systemGray6) : Color.black.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .clipShape(Rectangle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var weekDates: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStartDate) }
    }

    private var weekRangeLabel: String {
        guard let end = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else { return "" }
        return "\(monthDayLabel(weekStartDate)) 〜 \(monthDayLabel(end))"
    }

    private func moveWeek(by offset: Int) {
        guard let next = calendar.date(byAdding: .day, value: 7 * offset, to: weekStartDate) else { return }
        weekStartDate = calendar.startOfWeek(for: next)
    }

    private func loadWeekEntries() {
        guard let userId = authManager.currentUser?.id else {
            entriesByDayKey = [:]
            return
        }
        var map: [String: [CaloriesEntry]] = [:]
        for day in weekDates {
            let key = dateKey(day)
            map[key] = LocalDataStore.shared.caloriesEntries(userId: userId, date: day)
        }
        entriesByDayKey = map
    }

    private func entriesForSlot(_ entries: [CaloriesEntry], slot: MealSlot) -> [CaloriesEntry] {
        entries.filter { entry in
            if let tagged = slotFromFoodName(entry.foodName) {
                return tagged == slot
            }
            let hour = calendar.component(.hour, from: entry.createdAt)
            switch slot {
            case .breakfast:
                return hour >= 4 && hour < 11
            case .lunch:
                return hour >= 11 && hour < 15
            case .dinner:
                return hour >= 17 && hour < 22
            case .snack:
                return !(hour >= 4 && hour < 11) && !(hour >= 11 && hour < 15) && !(hour >= 17 && hour < 22)
            }
        }
    }

    private func dateKey(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "M/d"
        return df.string(from: date)
    }

    private func monthDayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "M/d"
        return df.string(from: date)
    }

    private func weekdayJP(_ date: Date) -> String {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let idx = calendar.component(.weekday, from: date) - 1
        guard symbols.indices.contains(idx) else { return "" }
        return symbols[idx]
    }

    private func cellKey(day: Date, slot: MealSlot) -> String {
        "\(dateKey(day))_\(slot.rawValue)"
    }

    private func loadPhotoMappings() {
        guard let userId = authManager.currentUser?.id else {
            photoPathByCellKey = [:]
            return
        }
        photoPathByCellKey = CalendarCellPhotoStore.load(userId: userId)
    }

    private func openPreview(with image: UIImage) {
        previewImage = image
        previewTargetDate = selectedDate
        previewTargetSlot = quickAddSlot
        showingPhotoPreview = true
    }

    private var quickAddPanel: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCameraCapture = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text("撮影")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingLibraryPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text("画像アップロード")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    private func savePhotoForCell(image: UIImage, day: Date, slot: MealSlot) {
        guard let userId = authManager.currentUser?.id else { return }
        let key = cellKey(day: day, slot: slot)
        CalendarCellPhotoStore.saveImage(image, userId: userId, cellKey: key)
        loadPhotoMappings()
    }

    private func slotFromFoodName(_ foodName: String) -> MealSlot? {
        if foodName.hasPrefix("【朝食】") { return .breakfast }
        if foodName.hasPrefix("【昼食】") { return .lunch }
        if foodName.hasPrefix("【夕食】") { return .dinner }
        if foodName.hasPrefix("【間食】") { return .snack }
        return nil
    }

}

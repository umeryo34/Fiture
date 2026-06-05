//
//  TargetSettingView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2026/03/21.
//

import SwiftUI

struct TargetSettingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    let screenTitle: String
    private let onCompleted: (() -> Void)?

    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var heightCm: Double?
    @State private var weightKg: Double?
    @State private var heightTenthCm = 1700
    @State private var weightTenthKg = 600
    @State private var gender: FitnessGender?
    @State private var bodyGoal: FitnessBodyGoal?
    @State private var activityLevel: FitnessActivityLevel?
    @State private var currentStep: Step = .birthDate
    @State private var didLoad = false
    @State private var goalTimelineEnabled = false
    @State private var goalWeightText = ""
    @State private var goalTargetDate = Calendar.current.date(byAdding: .day, value: 56, to: Date()) ?? Date()

    init(
        screenTitle: String = "基本情報",
        onCompleted: (() -> Void)? = nil
    ) {
        self.screenTitle = screenTitle
        self.onCompleted = onCompleted
    }

    var body: some View {
        NavigationView {
            wizardScrollContent
                .navigationTitle(screenTitle)
                .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: bodyGoal) { _, newGoal in
            if newGoal != .lose {
                goalTimelineEnabled = false
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            loadFromStorage()
        }
    }

    private var wizardScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 16) {
                    Text(currentStep.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(currentStep.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    stepContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button(action: goToPreviousStep) {
                        Text("戻る")
                            .font(.headline)
                            .foregroundColor(canGoPrevious ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canGoPrevious)

                    Button(action: handlePrimaryAction) {
                        Text(isLastStep ? "保存" : "次へ")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(canProceedCurrentStep ? Color.red : Color.gray)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceedCurrentStep)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }

    private var stepHeader: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.red : Color(.systemGray4))
                    .frame(height: 6)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .birthDate:
            inlineDatePicker(
                title: "誕生日",
                selection: $birthDate,
                range: ...Date()
            )

            if let age = computedAge(from: birthDate) {
                Text("現在 \(age) 歳")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

        case .gender:
            optionButtons(
                options: FitnessGender.allCases.map(\.rawValue),
                selected: gender?.rawValue
            ) { value in
                gender = FitnessGender(rawValue: value)
            }

        case .bodyMetrics:
            VStack(spacing: 20) {
                RulerScrollValuePicker(
                    title: "身長",
                    unit: "cm",
                    minTenth: Self.heightMinTenth,
                    maxTenth: Self.heightMaxTenth,
                    selectionTenth: $heightTenthCm
                )

                RulerScrollValuePicker(
                    title: "体重",
                    unit: "kg",
                    minTenth: Self.weightMinTenth,
                    maxTenth: Self.weightMaxTenth,
                    selectionTenth: $weightTenthKg
                )
            }

            if let bmr = estimatedProfileWithPickers.bmr {
                Text("推定BMR: \(Int(bmr.rounded())) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

        case .bodyGoal:
            optionButtons(
                options: FitnessBodyGoal.allCases.map(\.rawValue),
                selected: bodyGoal?.rawValue
            ) { value in
                bodyGoal = FitnessBodyGoal(rawValue: value)
            }

        case .activityLevel:
            VStack(spacing: 10) {
                ForEach(FitnessActivityLevel.allCases, id: \.self) { level in
                    Button {
                        activityLevel = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.rawValue)
                                    .foregroundColor(.primary)
                                Text("\(level.descriptionText) / 係数 \(String(format: "%.3f", level.coefficient))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            if activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }

                if bodyGoal == .lose {
                    Toggle(isOn: $goalTimelineEnabled) {
                        Text("目標体重と達成日からペースを決める（任意）")
                            .font(.subheadline)
                    }
                    .onChange(of: goalTimelineEnabled) { _, isOn in
                        if isOn, goalWeightText.isEmpty {
                            goalWeightText = String(format: "%.1f", Double(weightTenthKg) / 10)
                        }
                    }

                    if goalTimelineEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            inlineDatePicker(
                                title: "達成予定日",
                                selection: $goalTargetDate,
                                range: goalDateRange
                            )

                            labeledField(title: "目標体重 (kg)") {
                                TextField("例: 55.0", text: $goalWeightText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("1kg の体脂肪相当は約 7200kcal とみなし、期限までに必要な 1 日の不足分を計算します（TDEE−500 より大きいとき採用）。")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                }

                caloriePreviewSection
            }
        }
    }

    /// 画面内に埋め込む日付選択（compact による下からのシートを避ける）
    private func inlineDatePicker(
        title: String,
        selection: Binding<Date>,
        range: PartialRangeThrough<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            DatePicker(
                title,
                selection: selection,
                in: range,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    private func inlineDatePicker(
        title: String,
        selection: Binding<Date>,
        range: ClosedRange<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            DatePicker(
                title,
                selection: selection,
                in: range,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder field: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            field()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalDateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: Date())) ?? Date()
        let end = cal.date(byAdding: .day, value: 365 * 3, to: Date()) ?? Date()
        return start ... end
    }

    private var canGoPrevious: Bool {
        currentStep.rawValue > 0
    }

    private var isLastStep: Bool {
        currentStep == .activityLevel
    }

    private var canProceedCurrentStep: Bool {
        switch currentStep {
        case .birthDate:
            return computedAge(from: birthDate) != nil
        case .gender:
            return gender != nil
        case .bodyMetrics:
            return true
        case .bodyGoal:
            return bodyGoal != nil
        case .activityLevel:
            if activityLevel == nil { return false }
            if bodyGoal == .lose && goalTimelineEnabled {
                return parsedGoalWeightKg != nil
            }
            return true
        }
    }

    private func goToPreviousStep() {
        guard canGoPrevious else { return }
        currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .birthDate
        if currentStep == .bodyMetrics {
            syncPickersFromProfile()
        }
    }

    private func handlePrimaryAction() {
        guard canProceedCurrentStep else { return }
        if currentStep == .bodyMetrics {
            applyPickerValuesToProfile()
        }
        if isLastStep {
            saveProfile()
            if let onCompleted {
                onCompleted()
            } else {
                dismiss()
            }
            return
        }
        currentStep = Step(rawValue: currentStep.rawValue + 1) ?? currentStep
    }

    /// 保存済みプロフィールのみで判定（未保存のデフォルト誕生日を「入力済み」とみなさない）
    private func firstIncompleteStep(from profile: FitnessTargetProfile) -> Step {
        if profile.birthDate == nil { return .birthDate }
        if profile.gender == nil { return .gender }
        if profile.heightCm == nil || profile.weightKg == nil { return .bodyMetrics }
        if profile.bodyGoal == nil { return .bodyGoal }
        if profile.activityLevel == nil { return .activityLevel }
        return .birthDate
    }

    private var parsedGoalWeightKg: Double? {
        parsePositiveDouble(goalWeightText)
    }

    private func parsePositiveDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(trimmed), value > 0 else { return nil }
        return value
    }

    private func profileMergingGoals(base: FitnessTargetProfile) -> FitnessTargetProfile {
        FitnessTargetProfile(
            birthDate: base.birthDate,
            heightCm: base.heightCm,
            weightKg: base.weightKg,
            gender: base.gender,
            bodyGoal: base.bodyGoal,
            activityLevel: base.activityLevel,
            goalTargetWeightKg: (bodyGoal == .lose && goalTimelineEnabled) ? parsedGoalWeightKg : nil,
            goalTargetDate: (bodyGoal == .lose && goalTimelineEnabled) ? goalTargetDate : nil
        )
    }

    @ViewBuilder
    private var caloriePreviewSection: some View {
        let previewProfile = profileMergingGoals(base: estimatedProfileFromFields)
        if let r = CalorieCalculator.calculate(
            profile: previewProfile,
            userId: authManager.currentUser?.id
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("カロリー目安")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("推定BMR: \(Int(r.bmr.rounded())) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("推定TDEE: \(Int(r.tdee.rounded())) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("1日の摂取目標: \(Int(r.targetCalories.rounded())) kcal")
                    .font(.headline)
                    .foregroundColor(.primary)
                if let d = r.weightGoalDailyDeficit {
                    Text("目標体重からの不足ペース: 約 \(Int(d.rounded())) kcal/日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if r.weeklyTrendAdjustmentKcal != 0 {
                    Text("直近の体重トレンド補正: \(r.weeklyTrendAdjustmentKcal > 0 ? "+" : "")\(Int(r.weeklyTrendAdjustmentKcal.rounded())) kcal/日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("タンパク質の目安: 約 \(Int(r.suggestedProteinGramsPerDay.rounded())) g / 日（体重×1.8）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            )
            .padding(.top, 8)
        }
    }

    private func optionButtons(options: [String], selected: String?, onSelect: @escaping (String) -> Void) -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { value in
                Button {
                    onSelect(value)
                } label: {
                    HStack {
                        Text(value)
                            .foregroundColor(.primary)
                        Spacer()
                        if selected == value {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var estimatedProfileWithPickers: FitnessTargetProfile {
        FitnessTargetProfile(
            birthDate: birthDate,
            heightCm: Double(heightTenthCm) / 10,
            weightKg: Double(weightTenthKg) / 10,
            gender: gender,
            bodyGoal: bodyGoal,
            activityLevel: activityLevel,
            goalTargetWeightKg: nil,
            goalTargetDate: nil
        )
    }

    private var estimatedProfileFromFields: FitnessTargetProfile {
        FitnessTargetProfile(
            birthDate: birthDate,
            heightCm: heightCm ?? Double(heightTenthCm) / 10,
            weightKg: weightKg ?? Double(weightTenthKg) / 10,
            gender: gender,
            bodyGoal: bodyGoal,
            activityLevel: activityLevel,
            goalTargetWeightKg: nil,
            goalTargetDate: nil
        )
    }

    private func applyPickerValuesToProfile() {
        heightCm = Double(heightTenthCm) / 10
        weightKg = Double(weightTenthKg) / 10
    }

    private func syncPickersFromProfile() {
        if let h = heightCm {
            heightTenthCm = snapTenth(Int((h * 10).rounded()), minTenth: Self.heightMinTenth, maxTenth: Self.heightMaxTenth, default: 1700)
        } else {
            heightTenthCm = 1700
        }
        if let w = weightKg {
            weightTenthKg = snapTenth(Int((w * 10).rounded()), minTenth: Self.weightMinTenth, maxTenth: Self.weightMaxTenth, default: 600)
        } else {
            weightTenthKg = 600
        }
    }

    private func snapTenth(_ tenth: Int, minTenth: Int, maxTenth: Int, default defaultValue: Int) -> Int {
        let clamped = Swift.min(maxTenth, Swift.max(minTenth, tenth))
        guard clamped >= minTenth, clamped <= maxTenth else { return defaultValue }
        return clamped
    }

    /// 100.0〜250.0 cm（0.1 cm 刻み）
    private static let heightMinTenth = 1000
    private static let heightMaxTenth = 2500
    /// 30.0〜200.0 kg（0.1 kg 刻み）
    private static let weightMinTenth = 300
    private static let weightMaxTenth = 2000

    private func computedAge(from date: Date) -> Int? {
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? -1
        return years >= 0 ? years : nil
    }

    private func loadFromStorage() {
        let p = FitnessProfileStorage.load(userId: authManager.currentUser?.id)
        birthDate = p.birthDate ?? birthDate
        heightCm = p.heightCm
        weightKg = p.weightKg
        gender = p.gender
        bodyGoal = p.bodyGoal
        activityLevel = p.activityLevel
        syncPickersFromProfile()
        if let gw = p.goalTargetWeightKg {
            goalWeightText = String(format: "%.1f", gw)
            goalTimelineEnabled = p.goalTargetDate != nil
        }
        if let gd = p.goalTargetDate {
            let cal = Calendar.current
            let start = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: Date())) ?? Date()
            let end = cal.date(byAdding: .day, value: 365 * 3, to: Date()) ?? Date()
            goalTargetDate = min(max(gd, start), end)
        }
        currentStep = firstIncompleteStep(from: p)
    }

    private func saveProfile() {
        applyPickerValuesToProfile()

        let profile = FitnessTargetProfile(
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            gender: gender,
            bodyGoal: bodyGoal,
            activityLevel: activityLevel,
            goalTargetWeightKg: (bodyGoal == .lose && goalTimelineEnabled) ? parsedGoalWeightKg : nil,
            goalTargetDate: (bodyGoal == .lose && goalTimelineEnabled) ? goalTargetDate : nil
        )
        FitnessProfileStorage.save(profile, userId: authManager.currentUser?.id)

        if let userId = authManager.currentUser?.id,
           let result = CalorieCalculator.calculate(profile: profile, userId: userId) {
            let targetKcal = result.targetCalories.rounded()
            _ = LocalDataStore.shared.upsertCaloriesTarget(userId: userId, date: Date(), target: targetKcal)
            NotificationCenter.default.post(name: .caloriesDataDidUpdate, object: nil)
        }
    }

    private enum Step: Int, CaseIterable {
        case birthDate
        case gender
        case bodyMetrics
        case bodyGoal
        case activityLevel

        var title: String {
            switch self {
            case .birthDate: return "誕生日を教えてください"
            case .gender: return "性別を選択してください"
            case .bodyMetrics: return "身長と体重を入力してください"
            case .bodyGoal: return "目標を選択してください"
            case .activityLevel: return "普段の運動状況を選択してください"
            }
        }

        var description: String {
            switch self {
            case .birthDate: return "年齢は誕生日から自動で計算します。"
            case .gender: return "あとで変更できます。"
            case .bodyMetrics: return "BMR/TDEEの計算に使います。"
            case .bodyGoal: return "あなたに合った提案に使います。"
            case .activityLevel: return "活動係数を使ってTDEEを計算します。"
            }
        }
    }
}

#Preview {
    TargetSettingView()
        .environmentObject(AuthManager.shared)
}

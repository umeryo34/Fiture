//
//  TrainingBodyView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import SwiftUI

struct TrainingBodyView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = TrainingBodyViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("筋トレ")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity)
                
                // 体の模型（タップ可能な部位付き）
                InteractiveBodyModelView(
                    selectedMuscle: $viewModel.selectedMuscleType,
                    onMuscleTapped: { muscleType in
                        viewModel.selectMuscle(muscleType)
                    }
                )
                .frame(height: 400)
                .padding(.vertical, 20)
                
                // 今日の筋トレ目標
                if !viewModel.trainingTargets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日の筋トレ")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                        
                        ForEach(viewModel.trainingTargets) { target in
                            TrainingSummaryCard(trainingTarget: target)
                                .padding(.horizontal, 20)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("まだ筋トレ目標が設定されていません")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("「目標」タブで筋トレ目標を設定してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
        .task {
            viewModel.setAuthManager(authManager)
            await viewModel.fetchTrainingTargets()
        }
        .sheet(isPresented: $viewModel.showingMuscleRecord) {
            if let muscleType = viewModel.selectedMuscleType {
                MuscleRecordView(
                    muscleType: muscleType,
                    trainingTargetManager: viewModel.getTrainingTargetManager()
                )
                .environmentObject(authManager)
            }
        }
    }
}

// 体の模型ビュー（タップ可能な部位付き）
struct InteractiveBodyModelView: View {
    @State private var selectedView: BodyViewType = .front
    @Binding var selectedMuscle: MuscleType?
    let onMuscleTapped: (MuscleType) -> Void
    
    enum BodyViewType: String, CaseIterable {
        case front = "前面"
        case back = "背面"
    }
    
    enum MuscleType: String {
        case chest = "胸"
        case arms = "前腕・二頭"
        case triceps = "三頭"
        case back = "背中"
        case legs = "脚"
        case glutes = "尻"
        case abs = "腹"
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // ビュー切り替えボタン
            Picker("ビュー", selection: $selectedView) {
                ForEach(BodyViewType.allCases, id: \.self) { viewType in
                    Text(viewType.rawValue).tag(viewType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            
            // 体のシルエット
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let centerX = width / 2
                let scale = min(width / 200, height / 400)
                
                ZStack {
                    // 背景
                    Color(.systemGray6)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // 選択されたビューに応じて表示
                    if selectedView == .front {
                        InteractiveBodyFrontView(
                            centerX: centerX,
                            height: height,
                            scale: scale,
                            selectedMuscle: $selectedMuscle,
                            onMuscleTapped: onMuscleTapped
                        )
                    } else {
                        InteractiveBodyBackView(
                            centerX: centerX,
                            height: height,
                            scale: scale,
                            selectedMuscle: $selectedMuscle,
                            onMuscleTapped: onMuscleTapped
                        )
                    }
                }
            }
        }
    }
}

// 体の模型ビュー（よりリアルなシルエット - 前面）
struct BodyModelView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let scale = min(width / 200, height / 400)
            
            ZStack {
                // 背景
                Color(.systemGray6)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // 体のシルエット（Pathを使用）
                BodySilhouette(centerX: centerX, height: height, scale: scale)
                    .fill(Color.blue.opacity(0.2))
                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                
                // 筋肉部位のマーカー（オプション）
                MuscleMarkers(centerX: centerX, height: height, scale: scale)
            }
        }
    }
}

// 体のシルエット（Pathで描画）
struct BodySilhouette: Shape {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let h = height
        
        // 頭（楕円）
        let headWidth = 50 * scale
        let headHeight = 60 * scale
        path.addEllipse(in: CGRect(
            x: centerX - headWidth / 2,
            y: h * 0.05,
            width: headWidth,
            height: headHeight
        ))
        
        // 首
        let neckWidth = 25 * scale
        let neckHeight = 30 * scale
        path.addRect(CGRect(
            x: centerX - neckWidth / 2,
            y: h * 0.12,
            width: neckWidth,
            height: neckHeight
        ))
        
        // 肩と胴体（台形）
        let shoulderWidth = 120 * scale
        let waistWidth = 80 * scale
        let torsoHeight = 180 * scale
        
        path.move(to: CGPoint(x: centerX - shoulderWidth / 2, y: h * 0.18))
        path.addLine(to: CGPoint(x: centerX + shoulderWidth / 2, y: h * 0.18))
        path.addLine(to: CGPoint(x: centerX + waistWidth / 2, y: h * 0.18 + torsoHeight))
        path.addLine(to: CGPoint(x: centerX - waistWidth / 2, y: h * 0.18 + torsoHeight))
        path.closeSubpath()
        
        // 左腕（上腕）
        let upperArmWidth = 35 * scale
        let upperArmHeight = 80 * scale
        path.addRect(CGRect(
            x: centerX - shoulderWidth / 2 - upperArmWidth * 0.7,
            y: h * 0.2,
            width: upperArmWidth,
            height: upperArmHeight
        ))
        
        // 左腕（前腕）
        let forearmWidth = 30 * scale
        let forearmHeight = 70 * scale
        path.addRect(CGRect(
            x: centerX - shoulderWidth / 2 - forearmWidth * 0.8,
            y: h * 0.2 + upperArmHeight,
            width: forearmWidth,
            height: forearmHeight
        ))
        
        // 右腕（上腕）
        path.addRect(CGRect(
            x: centerX + shoulderWidth / 2 - upperArmWidth * 0.3,
            y: h * 0.2,
            width: upperArmWidth,
            height: upperArmHeight
        ))
        
        // 右腕（前腕）
        path.addRect(CGRect(
            x: centerX + shoulderWidth / 2 - forearmWidth * 0.2,
            y: h * 0.2 + upperArmHeight,
            width: forearmWidth,
            height: forearmHeight
        ))
        
        // 左足（太もも）
        let thighWidth = 40 * scale
        let thighHeight = 100 * scale
        path.addRect(CGRect(
            x: centerX - waistWidth / 2 - thighWidth * 0.2,
            y: h * 0.18 + torsoHeight,
            width: thighWidth,
            height: thighHeight
        ))
        
        // 左足（すね）
        let shinWidth = 30 * scale
        let shinHeight = 90 * scale
        path.addRect(CGRect(
            x: centerX - waistWidth / 2 - shinWidth * 0.2,
            y: h * 0.18 + torsoHeight + thighHeight,
            width: shinWidth,
            height: shinHeight
        ))
        
        // 右足（太もも）
        path.addRect(CGRect(
            x: centerX + waistWidth / 2 - thighWidth * 0.8,
            y: h * 0.18 + torsoHeight,
            width: thighWidth,
            height: thighHeight
        ))
        
        // 右足（すね）
        path.addRect(CGRect(
            x: centerX + waistWidth / 2 - shinWidth * 0.8,
            y: h * 0.18 + torsoHeight + thighHeight,
            width: shinWidth,
            height: shinHeight
        ))
        
        return path
    }
}

// 前面ビュー（タップ可能）
struct InteractiveBodyFrontView: View {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    @Binding var selectedMuscle: InteractiveBodyModelView.MuscleType?
    let onMuscleTapped: (InteractiveBodyModelView.MuscleType) -> Void
    
    var body: some View {
        ZStack {
            BodySilhouette(centerX: centerX, height: height, scale: scale)
                .fill(Color.blue.opacity(0.2))
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
            
            // タップ可能な部位
            // 胸（判定エリアを大きく、下まで含める）
            MuscleButton(
                position: CGPoint(x: centerX, y: height * 0.28),
                size: CGSize(width: 80 * scale, height: 80 * scale),
                muscleType: .chest,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.chest) }
            )
            
            // 腹（位置を下に移動）
            MuscleButton(
                position: CGPoint(x: centerX, y: height * 0.42),
                size: CGSize(width: 45 * scale, height: 60 * scale),
                muscleType: .abs,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.abs) }
            )
            
            // 左腕
            MuscleButton(
                position: CGPoint(x: centerX - 60 * scale, y: height * 0.3),
                size: CGSize(width: 30 * scale, height: 100 * scale),
                muscleType: .arms,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.arms) }
            )
            
            // 右腕
            MuscleButton(
                position: CGPoint(x: centerX + 60 * scale, y: height * 0.3),
                size: CGSize(width: 30 * scale, height: 100 * scale),
                muscleType: .arms,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.arms) }
            )
            
            // 左脚
            MuscleButton(
                position: CGPoint(x: centerX - 20 * scale, y: height * 0.65),
                size: CGSize(width: 30 * scale, height: 80 * scale),
                muscleType: .legs,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.legs) }
            )
            
            // 右脚
            MuscleButton(
                position: CGPoint(x: centerX + 20 * scale, y: height * 0.65),
                size: CGSize(width: 30 * scale, height: 80 * scale),
                muscleType: .legs,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.legs) }
            )
        }
    }
}

// 背面ビュー（タップ可能）
struct InteractiveBodyBackView: View {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    @Binding var selectedMuscle: InteractiveBodyModelView.MuscleType?
    let onMuscleTapped: (InteractiveBodyModelView.MuscleType) -> Void
    
    var body: some View {
        ZStack {
            BodySilhouetteBack(centerX: centerX, height: height, scale: scale)
                .fill(Color.blue.opacity(0.2))
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
            
            // タップ可能な部位
            // 背中
            MuscleButton(
                position: CGPoint(x: centerX, y: height * 0.3),
                size: CGSize(width: 70 * scale, height: 90 * scale),
                muscleType: .back,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.back) }
            )
            
            // 左腕（三頭）
            MuscleButton(
                position: CGPoint(x: centerX - 60 * scale, y: height * 0.3),
                size: CGSize(width: 30 * scale, height: 100 * scale),
                muscleType: .triceps,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.triceps) }
            )
            
            // 右腕（三頭）
            MuscleButton(
                position: CGPoint(x: centerX + 60 * scale, y: height * 0.3),
                size: CGSize(width: 30 * scale, height: 100 * scale),
                muscleType: .triceps,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.triceps) }
            )
            
            // 尻
            MuscleButton(
                position: CGPoint(x: centerX, y: height * 0.5),
                size: CGSize(width: 60 * scale, height: 50 * scale),
                muscleType: .glutes,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.glutes) }
            )
            
            // 左脚
            MuscleButton(
                position: CGPoint(x: centerX - 20 * scale, y: height * 0.65),
                size: CGSize(width: 30 * scale, height: 80 * scale),
                muscleType: .legs,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.legs) }
            )
            
            // 右脚
            MuscleButton(
                position: CGPoint(x: centerX + 20 * scale, y: height * 0.65),
                size: CGSize(width: 30 * scale, height: 80 * scale),
                muscleType: .legs,
                selectedMuscle: $selectedMuscle,
                onTapped: { onMuscleTapped(.legs) }
            )
        }
    }
}

// 筋肉部位のタップ可能なボタン
struct MuscleButton: View {
    let position: CGPoint
    let size: CGSize
    let muscleType: InteractiveBodyModelView.MuscleType
    @Binding var selectedMuscle: InteractiveBodyModelView.MuscleType?
    let onTapped: () -> Void
    
    private var isSelected: Bool {
        selectedMuscle == muscleType
    }
    
    var body: some View {
        Button(action: {
            selectedMuscle = muscleType
            onTapped()
        }) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.5) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .frame(width: size.width, height: size.height)
        }
        .position(position)
    }
}

// 背面シルエット
struct BodySilhouetteBack: Shape {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = height
        
        // 頭（背面）
        let headWidth = 50 * scale
        let headHeight = 60 * scale
        path.addEllipse(in: CGRect(
            x: centerX - headWidth / 2,
            y: h * 0.05,
            width: headWidth,
            height: headHeight
        ))
        
        // 首
        let neckWidth = 25 * scale
        let neckHeight = 30 * scale
        path.addRect(CGRect(
            x: centerX - neckWidth / 2,
            y: h * 0.12,
            width: neckWidth,
            height: neckHeight
        ))
        
        // 肩と胴体（背面）
        let shoulderWidth = 120 * scale
        let waistWidth = 80 * scale
        let torsoHeight = 180 * scale
        
        path.move(to: CGPoint(x: centerX - shoulderWidth / 2, y: h * 0.18))
        path.addLine(to: CGPoint(x: centerX + shoulderWidth / 2, y: h * 0.18))
        path.addLine(to: CGPoint(x: centerX + waistWidth / 2, y: h * 0.18 + torsoHeight))
        path.addLine(to: CGPoint(x: centerX - waistWidth / 2, y: h * 0.18 + torsoHeight))
        path.closeSubpath()
        
        // 腕（背面）
        let upperArmWidth = 35 * scale
        let upperArmHeight = 80 * scale
        path.addRect(CGRect(
            x: centerX - shoulderWidth / 2 - upperArmWidth * 0.7,
            y: h * 0.2,
            width: upperArmWidth,
            height: upperArmHeight
        ))
        
        let forearmWidth = 30 * scale
        let forearmHeight = 70 * scale
        path.addRect(CGRect(
            x: centerX - shoulderWidth / 2 - forearmWidth * 0.8,
            y: h * 0.2 + upperArmHeight,
            width: forearmWidth,
            height: forearmHeight
        ))
        
        path.addRect(CGRect(
            x: centerX + shoulderWidth / 2 - upperArmWidth * 0.3,
            y: h * 0.2,
            width: upperArmWidth,
            height: upperArmHeight
        ))
        
        path.addRect(CGRect(
            x: centerX + shoulderWidth / 2 - forearmWidth * 0.2,
            y: h * 0.2 + upperArmHeight,
            width: forearmWidth,
            height: forearmHeight
        ))
        
        // 足（背面）
        let thighWidth = 40 * scale
        let thighHeight = 100 * scale
        path.addRect(CGRect(
            x: centerX - waistWidth / 2 - thighWidth * 0.2,
            y: h * 0.18 + torsoHeight,
            width: thighWidth,
            height: thighHeight
        ))
        
        let shinWidth = 30 * scale
        let shinHeight = 90 * scale
        path.addRect(CGRect(
            x: centerX - waistWidth / 2 - shinWidth * 0.2,
            y: h * 0.18 + torsoHeight + thighHeight,
            width: shinWidth,
            height: shinHeight
        ))
        
        path.addRect(CGRect(
            x: centerX + waistWidth / 2 - thighWidth * 0.8,
            y: h * 0.18 + torsoHeight,
            width: thighWidth,
            height: thighHeight
        ))
        
        path.addRect(CGRect(
            x: centerX + waistWidth / 2 - shinWidth * 0.8,
            y: h * 0.18 + torsoHeight + thighHeight,
            width: shinWidth,
            height: shinHeight
        ))
        
        return path
    }
}

// 前面の筋肉マーカー
struct MuscleMarkersFront: View {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // 胸筋
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 30 * scale, height: 30 * scale)
                .position(x: centerX, y: height * 0.25)
            
            // 腹筋
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.orange.opacity(0.3))
                .frame(width: 40 * scale, height: 50 * scale)
                .position(x: centerX, y: height * 0.35)
            
            // 上腕二頭筋（左）
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 20 * scale, height: 20 * scale)
                .position(x: centerX - 60 * scale, y: height * 0.3)
            
            // 上腕二頭筋（右）
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 20 * scale, height: 20 * scale)
                .position(x: centerX + 60 * scale, y: height * 0.3)
            
            // 太もも（左）
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.purple.opacity(0.3))
                .frame(width: 25 * scale, height: 40 * scale)
                .position(x: centerX - 20 * scale, y: height * 0.65)
            
            // 太もも（右）
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.purple.opacity(0.3))
                .frame(width: 25 * scale, height: 40 * scale)
                .position(x: centerX + 20 * scale, y: height * 0.65)
        }
    }
}

// 背面の筋肉マーカー
struct MuscleMarkersBack: View {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // 広背筋
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.cyan.opacity(0.3))
                .frame(width: 60 * scale, height: 80 * scale)
                .position(x: centerX, y: height * 0.3)
            
            // 僧帽筋
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 50 * scale, height: 30 * scale)
                .position(x: centerX, y: height * 0.22)
            
            // ハムストリング（左）
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.pink.opacity(0.3))
                .frame(width: 25 * scale, height: 50 * scale)
                .position(x: centerX - 20 * scale, y: height * 0.65)
            
            // ハムストリング（右）
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.pink.opacity(0.3))
                .frame(width: 25 * scale, height: 50 * scale)
                .position(x: centerX + 20 * scale, y: height * 0.65)
        }
    }
}

// 筋肉部位のマーカー（タップ可能にする場合）
struct MuscleMarkers: View {
    let centerX: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    var body: some View {
        MuscleMarkersFront(centerX: centerX, height: height, scale: scale)
    }
}

// 筋トレサマリーカード
struct TrainingSummaryCard: View {
    let trainingTarget: TrainingTarget
    
    var body: some View {
        HStack(spacing: 15) {
            Image("training")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trainingTarget.exerciseType)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("目標: \(String(format: "%.0f", trainingTarget.target)) セット")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("現在: \(String(format: "%.0f", trainingTarget.attempt)) セット")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("\(String(format: "%.0f", trainingTarget.progressPercentage))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("進捗")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// セット情報
struct TrainingSet: Identifiable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
}

// 部位別筋トレ記録画面
struct MuscleRecordView: View {
    let muscleType: InteractiveBodyModelView.MuscleType
    let trainingTargetManager: TrainingTargetManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: MuscleRecordViewModel
    
    init(muscleType: InteractiveBodyModelView.MuscleType, trainingTargetManager: TrainingTargetManager) {
        self.muscleType = muscleType
        self.trainingTargetManager = trainingTargetManager
        _viewModel = StateObject(wrappedValue: MuscleRecordViewModel(muscleType: muscleType, trainingTargetManager: trainingTargetManager))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 15) {
                    Image("training")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("\(muscleType.rawValue)の筋トレ記録")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 種目名選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("種目名")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Menu {
                                ForEach(viewModel.availableExercises, id: \.self) { exercise in
                                    Button(action: {
                                        viewModel.exerciseType = exercise
                                    }) {
                                        Text(exercise)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.exerciseType.isEmpty ? "選択してください" : viewModel.exerciseType)
                                        .foregroundColor(viewModel.exerciseType.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // セット一覧
                        VStack(alignment: .leading, spacing: 12) {
                            Text("セット")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ForEach(viewModel.sets.indices, id: \.self) { index in
                                SetRowView(
                                    setNumber: index + 1,
                                    set: $viewModel.sets[index],
                                    onDelete: {
                                        viewModel.removeSet(at: index)
                                    },
                                    showWeight: viewModel.showWeightInput
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // セットを追加ボタン
                            Button(action: {
                                viewModel.addSet()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("セットを追加")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1.5)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // エラーメッセージ
                if viewModel.showError {
                    Text(viewModel.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // 保存ボタン
                Button(action: {
                    Task {
                        await viewModel.saveRecord()
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("記録を保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(viewModel.isFormValid ? Color.red : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
            .navigationTitle("筋トレ記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setAuthManager(authManager)
        }
    }
}

// セット行ビュー
struct SetRowView: View {
    let setNumber: Int
    @Binding var set: TrainingSet
    let onDelete: () -> Void
    let showWeight: Bool
    
    init(setNumber: Int, set: Binding<TrainingSet>, onDelete: @escaping () -> Void, showWeight: Bool = true) {
        self.setNumber = setNumber
        self._set = set
        self.onDelete = onDelete
        self.showWeight = showWeight
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // セット番号
            Text("\(setNumber)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            // 重量入力（腹の場合は非表示）
            if showWeight {
                VStack(alignment: .leading, spacing: 4) {
                    Text("kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $set.weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
            }
            
            // 回数入力
            VStack(alignment: .leading, spacing: 4) {
                Text("回数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("0", text: $set.reps)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
            }
            
            Spacer()
            
            // 削除ボタン
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    TrainingBodyView()
        .environmentObject(AuthManager.shared)
}

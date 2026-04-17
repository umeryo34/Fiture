//
//  CalendarCellPhotoPreviewView.swift
//  Fiture
//

import SwiftUI
import UIKit

struct CalendarCellPhotoPreviewView: View {
    let image: UIImage
    @Binding var targetDate: Date
    @Binding var targetSlot: CalendarView.MealSlot
    let onClose: () -> Void
    let onSubmit: (UIImage, Date, CalendarView.MealSlot) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipShape(.rect(cornerRadius: 16))
                        .shadow(radius: 5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("保存先の日付")
                            .font(.headline)
                        DatePicker(
                            "日付を選択",
                            selection: $targetDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        Text("食事区分")
                            .font(.headline)
                            .padding(.top, 4)

                        HStack(spacing: 8) {
                            ForEach(CalendarView.MealSlot.allCases, id: \.rawValue) { slot in
                                Button {
                                    targetSlot = slot
                                } label: {
                                    Text(slot.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(targetSlot == slot ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(targetSlot == slot ? Color.red : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        onSubmit(image, targetDate, targetSlot)
                    } label: {
                        Text("このセルに画像を投稿")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(.white)
                            .background(Color.red)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("画像プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        onClose()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

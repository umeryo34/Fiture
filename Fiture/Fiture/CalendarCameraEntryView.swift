//
//  CalendarCameraEntryView.swift
//  Fiture
//

import SwiftUI
import UIKit

struct CalendarCameraEntryView: View {
    let onCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CalendarImagePicker(sourceType: .camera) { image in
                if let image {
                    onCaptured(image)
                } else {
                    onCancel()
                }
                dismiss()
            }
            .ignoresSafeArea()
        }
    }
}

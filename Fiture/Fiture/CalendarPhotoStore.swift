//
//  CalendarCellPhotoStore.swift
//  Fiture
//

import Foundation
import UIKit

enum CalendarCellPhotoStore {
    private static func mapKey(userId: UUID) -> String {
        "fiture_calendar_cell_photo_map_\(userId.uuidString.lowercased())"
    }

    static func load(userId: UUID) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: mapKey(userId: userId)) as? [String: String] ?? [:]
    }

    static func saveImage(_ image: UIImage, userId: UUID, cellKey: String) {
        var map = load(userId: userId)
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docs else { return }
        let filename = "calendarcell_\(userId.uuidString.lowercased())_\(cellKey.replacingOccurrences(of: ":", with: "-")).jpg"
        let fileURL = docs.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            map[cellKey] = fileURL.path
            UserDefaults.standard.set(map, forKey: mapKey(userId: userId))
        } catch {
            return
        }
    }
}

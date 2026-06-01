import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Relative Time
extension Date {
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Date {
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

extension Dictionary where Key == String, Value == Any {
    func string(_ key: String, default defaultValue: String = "") -> String {
        self[key] as? String ?? defaultValue
    }

    func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        self[key] as? Bool ?? defaultValue
    }

    func int(_ key: String, default defaultValue: Int = 0) -> Int {
        self[key] as? Int ?? defaultValue
    }

    func stringArray(_ key: String) -> [String] {
        self[key] as? [String] ?? []
    }

    func date(_ key: String, default defaultValue: Date = Date()) -> Date {
        if let timestamp = self[key] as? Timestamp {
            return timestamp.dateValue()
        }
        return defaultValue
    }
}

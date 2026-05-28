import FirebaseFirestore
import Foundation

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

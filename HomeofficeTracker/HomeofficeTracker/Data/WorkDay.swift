import SwiftData
import Foundation

/// SwiftData-Model für einen einzelnen Arbeitstag.
///
/// ⚠️ CloudKit-Kompatibilität:
/// - **Alle non-optional Properties MÜSSEN einen Default haben.** Sonst kann der
///   CloudKit-fähige ModelContainer das Schema nicht laden → `loadIssueModelContainer`.
/// - **Keine `@Attribute(.unique)`-Constraints** — CloudKit unterstützt das nicht.
///   Eindeutigkeit pro Datum wird stattdessen vor jedem `insert` im Code geprüft
///   (siehe `workDay(for:)` in den Tracking-Views).
@Model
final class WorkDay {
    var date: Date = Date.distantPast
    var isHomeoffice: Bool = false
    var note: String?
    var specialType: String?

    init(date: Date, isHomeoffice: Bool = false, note: String? = nil, specialType: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isHomeoffice = isHomeoffice
        self.note = note
        self.specialType = specialType
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

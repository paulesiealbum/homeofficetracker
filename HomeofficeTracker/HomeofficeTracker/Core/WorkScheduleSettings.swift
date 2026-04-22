import Foundation
import Observation

@Observable
final class WorkScheduleSettings {
    static let allWeekdays: [(iso: Int, label: String)] = [
        (1, "Montag"), (2, "Dienstag"), (3, "Mittwoch"),
        (4, "Donnerstag"), (5, "Freitag"), (6, "Samstag"), (7, "Sonntag")
    ]

    var workingDays: Set<Int> {
        didSet { UserDefaults.standard.set(encode(workingDays), forKey: "workingDays") }
    }

    var homefficeDays: Set<Int> {
        didSet { UserDefaults.standard.set(encode(homefficeDays), forKey: "homefficeDays") }
    }

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    /// Name des Nutzers — erscheint im PDF-Export-Header.
    var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }

    /// Beschäftigungsstatus — beeinflusst Abzugsart im PDF (Werbungskosten / Betriebsausgaben).
    var employmentType: EmploymentType {
        didSet { UserDefaults.standard.set(employmentType.rawValue, forKey: "employmentType") }
    }

    /// Farbmodus: "system", "light" oder "dark".
    var colorSchemePreference: String {
        didSet { UserDefaults.standard.set(colorSchemePreference, forKey: "colorSchemePreference") }
    }

    /// Legacy-Wert für Free-User (0 = nicht konfiguriert).
    var commuterDistanceKm: Int {
        didSet { UserDefaults.standard.set(commuterDistanceKm, forKey: "commuterDistanceKm") }
    }

    /// Arbeitsstätten-Perioden für Premium-User.
    var workplacePeriods: [WorkplacePeriod] {
        didSet {
            if let data = try? JSONEncoder().encode(workplacePeriods) {
                UserDefaults.standard.set(data, forKey: "workplacePeriods")
            }
        }
    }

    // MARK: - Abend-Reminder (kostenlos)

    /// Täglicher Abend-Reminder aktiviert.
    var reminderEnabled: Bool {
        didSet { UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled") }
    }

    /// Stunde des täglichen Reminders (0–23). Default: 18.
    var reminderHour: Int {
        didSet { UserDefaults.standard.set(reminderHour, forKey: "reminderHour") }
    }

    /// Minute des täglichen Reminders (0–59). Default: 0.
    var reminderMinute: Int {
        didSet { UserDefaults.standard.set(reminderMinute, forKey: "reminderMinute") }
    }

    // MARK: - Feiertagskalender

    /// Bundesland / Land für regionalen Feiertagskalender (FederalState.rawValue).
    var federalState: String {
        didSet { UserDefaults.standard.set(federalState, forKey: "federalState") }
    }

    // MARK: - Init

    init() {
        workingDays = Self.decode(UserDefaults.standard.string(forKey: "workingDays")) ?? [1, 2, 3, 4, 5]
        homefficeDays = Self.decode(UserDefaults.standard.string(forKey: "homefficeDays")) ?? []
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        let storedType = UserDefaults.standard.string(forKey: "employmentType") ?? ""
        employmentType = EmploymentType(rawValue: storedType) ?? .employee
        commuterDistanceKm = UserDefaults.standard.integer(forKey: "commuterDistanceKm")
        colorSchemePreference = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? "system"

        // Reminder — default 18:00
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        reminderHour = UserDefaults.standard.value(forKey: "reminderHour") as? Int ?? 18
        reminderMinute = UserDefaults.standard.value(forKey: "reminderMinute") as? Int ?? 0

        // Feiertagskalender — default NW (größtes Bundesland / geographische Mitte)
        federalState = UserDefaults.standard.string(forKey: "federalState") ?? FederalState.nw.rawValue

        // Lade gespeicherte Perioden — oder migriere einmalig aus Legacy-Einzelwert
        if let data = UserDefaults.standard.data(forKey: "workplacePeriods"),
           let decoded = try? JSONDecoder().decode([WorkplacePeriod].self, from: data) {
            workplacePeriods = decoded
        } else {
            let legacyKm = UserDefaults.standard.integer(forKey: "commuterDistanceKm")
            if legacyKm > 0 {
                let legacyHome = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
                let legacyWork = UserDefaults.standard.string(forKey: "workAddress") ?? ""
                workplacePeriods = [WorkplacePeriod(
                    commuteKm: legacyKm,
                    homeAddress: legacyHome,
                    workAddress: legacyWork
                )]
            } else {
                workplacePeriods = []
            }
        }
    }

    // MARK: - Helpers

    func isWorkingDay(_ date: Date) -> Bool {
        workingDays.contains(Self.isoWeekday(for: date))
    }

    func isDefaultHomeoffice(_ date: Date) -> Bool {
        homefficeDays.contains(Self.isoWeekday(for: date))
    }

    static func isoWeekday(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday + 5) % 7 + 1
    }

    private func encode(_ value: Set<Int>) -> String {
        value.sorted().map(String.init).joined(separator: ",")
    }

    private static func decode(_ raw: String?) -> Set<Int>? {
        guard let raw, !raw.isEmpty else { return nil }
        return Set(raw.split(separator: ",").compactMap { Int($0) })
    }
}

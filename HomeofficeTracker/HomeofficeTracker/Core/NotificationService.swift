// NotificationService.swift
// Verwaltet den täglichen Abend-Reminder zum Erfassen der Homeoffice-Tage.
// Kostenloses Feature — keine Premium-Schranke.

import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let reminderID = "de.homeofficetracker.eveningreminder"

    // MARK: - Berechtigung

    /// Fragt Notification-Berechtigung an. Gibt true zurück wenn granted.
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default: return false
        }
    }

    /// Aktueller Berechtigungsstatus (ohne neue Anfrage).
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Plant täglichen Reminder zur angegebenen Uhrzeit.
    func scheduleReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Homeoffice-Tag eintragen?"
        content.body = "Kurz den heutigen Tag erfassen – dauert 2 Sekunden und sichert deine Steuerpauschale."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)

        center.add(request)
    }

    /// Entfernt alle geplanten Reminder.
    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }

    /// Synchronisiert den Reminder mit den aktuellen Einstellungen.
    /// Wird beim App-Start und nach Einstellungsänderungen aufgerufen.
    func syncWithSettings(enabled: Bool, hour: Int, minute: Int) {
        if enabled {
            scheduleReminder(hour: hour, minute: minute)
        } else {
            cancelReminder()
        }
    }
}

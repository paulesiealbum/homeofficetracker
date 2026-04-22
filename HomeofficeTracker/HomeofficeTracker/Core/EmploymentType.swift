// EmploymentType.swift
// Beschäftigungsstatus des Nutzers — beeinflusst Haftungstext und PDF-Abzugsart.
// Wird im Onboarding-Eligibility-Check gesetzt und in UserDefaults persistiert.

import Foundation

enum EmploymentType: String, CaseIterable, Identifiable {
    case employee       = "employee"       // Arbeitnehmer / Angestellter
    case selfEmployed   = "selfEmployed"   // Selbstständig / Freiberufler
    case civilServant   = "civilServant"   // Beamter / Öffentlicher Dienst
    case unknown        = "unknown"        // Unsicher

    var id: String { rawValue }

    /// Anzeigename im Onboarding und in den Einstellungen
    var displayName: String {
        switch self {
        case .employee:     return "Arbeitnehmer / Angestellter"
        case .selfEmployed: return "Selbstständig / Freiberufler"
        case .civilServant: return "Beamter / Öffentlicher Dienst"
        case .unknown:      return "Ich bin unsicher"
        }
    }

    /// Kurzer Hinweistext für das PDF (Abzugsart)
    var deductionType: String {
        switch self {
        case .employee:     return "Werbungskosten (§ 9 Abs. 5 EStG)"
        case .selfEmployed: return "Betriebsausgaben (§ 4 Abs. 5 Satz 1 Nr. 6c EStG)"
        case .civilServant: return "Werbungskosten (§ 9 Abs. 5 EStG)"
        case .unknown:      return "Werbungskosten — Abzugsart bitte mit Steuerberater bestätigen"
        }
    }

    /// Zeigt einen Hinweis-Banner im Onboarding (nur für Selbstständige und Unsichere)
    var eligibilityHint: String? {
        switch self {
        case .employee, .civilServant:
            return nil
        case .selfEmployed:
            return "Auch als Selbstständiger kannst du die Homeoffice-Pauschale nutzen — als Betriebsausgabe (§ 4 EStG). Hast du ein steuerlich anerkanntes häusliches Arbeitszimmer? Dann kläre mit deinem Steuerberater, welche Variante günstiger ist."
        case .unknown:
            return "Die Pauschale gilt für fast alle, die von zuhause arbeiten — egal ob angestellt oder selbstständig. Im Zweifel einfach tracken und beim Steuerberater nachfragen."
        }
    }

    /// Default: Arbeitnehmer (häufigster Fall)
    static var defaultValue: EmploymentType { .employee }
}

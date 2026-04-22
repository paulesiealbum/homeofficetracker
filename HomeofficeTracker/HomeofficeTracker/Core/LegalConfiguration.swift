// LegalConfiguration.swift
// ⚠️ SINGLE SOURCE OF TRUTH für alle steuerrechtlichen Werte
//
// Bei Gesetzesänderungen: NUR DIESE DATEI + RECHTSLAGE.md bearbeiten.
// Danach App Store-Texte und alle In-App-Hinweistexte prüfen.
// Update-Pflicht: Jedes Jahr bis 31. Januar — siehe RECHTSLAGE.md für Checkliste.

import Foundation

struct LegalConfiguration {

    // MARK: - Year Configuration

    struct YearConfig {
        let year: Int
        let dailyRate: Double       // € pro Homeoffice-Tag
        let maxDays: Int            // Maximale anerkannte Tage pro Jahr
        let maxAmount: Double       // Maximum in € (dailyRate × maxDays)
        let legalBasis: String      // Gesetzliche Grundlage
        let verifiedOn: String      // "YYYY-MM" — wann zuletzt geprüft

        /// Menschenlesbare Formatierung des Tagessatzes
        var dailyRateFormatted: String {
            dailyRate.formatted(.currency(code: "EUR"))
        }

        /// Menschenlesbare Formatierung des Maximalbetrags
        var maxAmountFormatted: String {
            maxAmount.formatted(.currency(code: "EUR"))
        }
    }

    // MARK: - Jährliche Konfigurationen
    // Quelle: RECHTSLAGE.md
    // ⚠️ Jedes Jahr bis 31. Januar neuen Eintrag hinzufügen + verifiedOn aktualisieren

    private static let configs: [Int: YearConfig] = [
        2020: YearConfig(
            year: 2020, dailyRate: 5.00, maxDays: 120, maxAmount: 600.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6b EStG (temporär, COVID-19)",
            verifiedOn: "2025-01"
        ),
        2021: YearConfig(
            year: 2021, dailyRate: 5.00, maxDays: 120, maxAmount: 600.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6b EStG (temporär, COVID-19)",
            verifiedOn: "2025-01"
        ),
        2022: YearConfig(
            year: 2022, dailyRate: 5.00, maxDays: 120, maxAmount: 600.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6b EStG (temporär, COVID-19)",
            verifiedOn: "2025-01"
        ),
        2023: YearConfig(
            year: 2023, dailyRate: 6.00, maxDays: 210, maxAmount: 1260.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6c EStG i.V.m. JStG 2022 (dauerhaft)",
            verifiedOn: "2025-01"
        ),
        2024: YearConfig(
            year: 2024, dailyRate: 6.00, maxDays: 210, maxAmount: 1260.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6c EStG i.V.m. JStG 2022 (dauerhaft)",
            verifiedOn: "2025-01"
        ),
        2025: YearConfig(
            year: 2025, dailyRate: 6.00, maxDays: 210, maxAmount: 1260.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6c EStG i.V.m. JStG 2022 (dauerhaft)",
            verifiedOn: "2026-04"
        ),
        2026: YearConfig(
            year: 2026, dailyRate: 6.00, maxDays: 210, maxAmount: 1260.00,
            legalBasis: "§ 4 Abs. 5 Satz 1 Nr. 6c EStG i.V.m. JStG 2022 (dauerhaft)",
            verifiedOn: "2026-04"  // ⏳ Erneut prüfen: Januar 2027
        ),
        // ── NÄCHSTES JAHR HIER EINTRAGEN ─────────────────────────────────
        // 2027: YearConfig(year: 2027, dailyRate: 6.00, maxDays: 210, maxAmount: 1260.00,
        //                  legalBasis: "...", verifiedOn: "2027-01"),
    ]

    // MARK: - Öffentliche API

    /// Gibt die Konfiguration für ein gegebenes Jahr zurück.
    /// Fällt auf die letzte bekannte Konfiguration zurück (kein Crash bei Zukunftsjahren).
    static func config(for year: Int) -> YearConfig {
        if let exact = configs[year] { return exact }
        let sorted = configs.keys.sorted()
        let fallback = sorted.last(where: { $0 <= year }) ?? sorted.last!
        return configs[fallback]!
    }

    /// Konfiguration für das aktuell laufende Steuerjahr
    static var current: YearConfig {
        config(for: Calendar.current.component(.year, from: Date()))
    }

    /// Berechnet Steuerersparnis für eine Anzahl Tage (gecappt auf maxDays des Jahres)
    static func savings(days: Int, year: Int) -> Double {
        let cfg = config(for: year)
        return Double(min(days, cfg.maxDays)) * cfg.dailyRate
    }

    /// Convenience: Ersparnis für das aktuelle Jahr
    static func savingsCurrentYear(days: Int) -> Double {
        savings(days: days, year: Calendar.current.component(.year, from: Date()))
    }
}

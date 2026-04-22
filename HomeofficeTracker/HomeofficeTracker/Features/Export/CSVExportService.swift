// CSVExportService.swift
// CSV-Export für deutsche Steuerberater und Excel-Kompatibilität (DACH).
// Format: UTF-8 mit BOM, Semikolon-Trenner, Komma als Dezimalzeichen.
// Spec: PDF-EXPORT-SPEC.md → Abschnitt "CSV-Export"

import Foundation

struct CSVExportService {

    // MARK: - Einstiegspunkt

    /// Generiert CSV-Daten für ein gegebenes Jahr.
    /// Enthält alle Arbeitstage (HO und Büro) des Jahres — Steuerberater sehen das Gesamtbild.
    static func generateCSV(
        days: [WorkDay],
        year: Int,
        userName: String,
        employmentType: EmploymentType,
        workplacePeriods: [WorkplacePeriod] = []
    ) -> Data {
        let cfg = LegalConfiguration.config(for: year)
        let calendar = Calendar.current

        // Alle eingetragenen Tage des Jahres, chronologisch (nur bis heute — geplante Zukunftstage ausgenommen)
        let today = calendar.startOfDay(for: Date())
        let yearDays = days
            .filter { calendar.component(.year, from: $0.date) == year && $0.date <= today }
            .sorted { $0.date < $1.date }

        var lines: [String] = []

        // Metadaten-Header (informativ, kein Pflichtfeld für DATEV)
        lines.append("# Homeoffice-Tracker – Steuerjahr \(year)")
        lines.append("# Name: \(userName.isEmpty ? "[nicht angegeben]" : userName)")
        lines.append("# Beschäftigungsstatus: \(employmentType.displayName)")
        lines.append("# Abzugsart: \(employmentType.deductionType)")
        lines.append("# Tagespauschale: \(cfg.dailyRate.germanDecimal) EUR")
        lines.append("# Maximale Tage: \(cfg.maxDays)")
        lines.append("# Rechtsgrundlage: \(cfg.legalBasis)")
        lines.append("# Erstellt am: \(DateFormatter.germanLongCSV.string(from: Date()))")
        lines.append("#")

        // Spaltenüberschriften — immer Deutsch (Datei geht an deutschen Steuerberater)
        lines.append("Datum;Wochentag;Typ;Homeoffice;Betrag (EUR);Notiz")

        var hoIndex = 0
        for day in yearDays {
            let dateStr = DateFormatter.germanDate.string(from: day.date)
            let weekday = DateFormatter.germanWeekday.string(from: day.date)
            let specialType = day.specialType.flatMap { SpecialDayType(rawValue: $0) }
            let typLabel = specialType?.label ?? (day.isHomeoffice ? "Homeoffice" : "Büro")
            let isHO = day.isHomeoffice && specialType == nil ? "Ja" : "Nein"

            var betrag = ""
            if day.isHomeoffice && specialType == nil {
                hoIndex += 1
                if hoIndex <= cfg.maxDays {
                    betrag = cfg.dailyRate.germanDecimal
                } else {
                    betrag = "0" // Über dem Limit
                }
            }

            let note = (day.note ?? "").replacingOccurrences(of: ";", with: ",") // Semikolon im Notizfeld escapen
            lines.append("\(dateStr);\(weekday);\(typLabel);\(isHO);\(betrag);\(note)")
        }

        // Zusammenfassung am Ende
        let totalHO = yearDays.filter { $0.isHomeoffice && $0.specialType == nil }.count
        let cappedHO = min(totalHO, cfg.maxDays)
        let totalAmount = Double(cappedHO) * cfg.dailyRate
        lines.append("#")
        lines.append("# Homeoffice-Tage gesamt: \(totalHO)")
        lines.append("# Für Pauschale anerkannt: \(cappedHO)")
        lines.append("# Absetzbare Summe (§ 4 Abs. 5 Satz 1 Nr. 6c EStG): \(totalAmount.germanDecimal) EUR")

        // Entfernungspauschale je Arbeitsstätte (§ 9 Abs. 1 Satz 3 Nr. 4 EStG)
        let pendlerPeriods = workplacePeriods.filter { $0.commuteKm > 0 }
        if !pendlerPeriods.isEmpty {
            lines.append("#")
            lines.append("# --- Entfernungspauschale (§ 9 Abs. 1 Satz 3 Nr. 4 EStG) ---")
            let details = CommuterConstants.periodDetails(periods: pendlerPeriods, allDays: yearDays, year: year)
            for d in details {
                lines.append("# Arbeitsstätte: \(d.period.displayLabel) (\(d.period.commuteKm) km)")
                lines.append("#   Verkehrsmittel: \(d.transportMode.displayName)")
                lines.append("#   Bürotage: \(d.officeDays) | Pauschale/Tag: \(d.perDay.germanDecimal) EUR")
                lines.append("#   Ungekürzt: \(d.uncappedTotal.germanDecimal) EUR | Absetzbar: \(d.effectiveTotal.germanDecimal) EUR")
                if d.transportMode.capExempt {
                    lines.append("#   ✓ PKW/Motorrad: kein Jahreshöchstbetrag (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG)")
                } else if d.capApplied {
                    lines.append("#   ⚠ Jahreshöchstbetrag 4.500 EUR angewendet (§ 9 Abs. 1 Satz 3 Nr. 4 EStG)")
                }
            }
            let pendlerTotal = details.reduce(0.0) { $0 + $1.effectiveTotal }
            lines.append("# Pendlerpauschale gesamt: \(pendlerTotal.germanDecimal) EUR")
            lines.append("#")
            lines.append("# ⚠ Gegenseitiger Ausschluss: Homeoffice-Tage und Pendlerpauschale")
            lines.append("#   können NICHT für denselben Tag geltend gemacht werden.")
        }

        let csvString = lines.joined(separator: "\r\n") + "\r\n"

        // UTF-8 BOM voranstellen (nötig für korrekte Excel-Erkennung in DACH)
        let bom = Data([0xEF, 0xBB, 0xBF])
        let content = csvString.data(using: .utf8) ?? Data()
        return bom + content
    }

    // MARK: - Dateiname

    static func fileName(year: Int) -> String {
        "Homeoffice_\(year).csv"
    }
}

// MARK: - Formatter

private extension DateFormatter {
    static let germanDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    static let germanWeekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    static let germanLongCSV: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        f.locale = Locale(identifier: "de_DE")
        return f
    }()
}

private extension Double {
    /// Deutsches Dezimalformat: Komma statt Punkt (z. B. „6,00")
    var germanDecimal: String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

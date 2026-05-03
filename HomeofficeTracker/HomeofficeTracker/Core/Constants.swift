import Foundation

enum TaxConstants {
    // ⚠️ Steuerrechtliche Werte werden NICHT hier definiert.
    // Quelle: LegalConfiguration.swift (Single Source of Truth)
    static var ratePerDay: Double { LegalConfiguration.current.dailyRate }
    static var maxDaysPerYear: Int { LegalConfiguration.current.maxDays }
    /// Premium Jahres-Abo: 2,99 €/Jahr — alle Features inklusive.
    static let subscriptionID = "com.Paul.HomeofficeTracker.premium.annual"
}

/// Berechnet Homeoffice-Steuerersparnis für das aktuelle Jahr.
func savings(days: Int) -> Double {
    LegalConfiguration.savingsCurrentYear(days: days)
}

// MARK: - Entfernungspauschale §9 Abs. 1 Satz 3 Nr. 4 EStG

/// Alle Berechnungen zur Entfernungspauschale (Pendlerpauschale).
///
/// Rechtsgrundlage:
/// - §9 Abs. 1 Satz 3 Nr. 4 EStG (Arbeitnehmer)
/// - §4 Abs. 5a EStG (Selbstständige: Begrenzung auf Entfernungspauschale)
/// - §9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG: Jahreshöchstbetrag 4.500 € bei Kfz
///
/// ⚠️ Wechsel der Sätze nach Jahren:
///   - bis 2020: 0,30 €/km einheitlich für alle Kilometer
///   - 2021:     0,30 €/km (1–20 km) + 0,35 €/km (ab 21 km)
///   - 2022–2025: 0,30 €/km (1–20 km) + 0,38 €/km (ab 21 km)
///     Quelle: Steuerentlastungsgesetz 2022 (BGBl. I S. 749)
///   - ab 2026:  0,38 €/km einheitlich für ALLE Kilometer (Flat Rate, kein Schwellenwert mehr)
///     Quelle: Steueränderungsgesetz 2025 (BGBl. I Nr. 363/2025, verkündet 23.12.2025)
enum CommuterConstants {

    // MARK: - Feste Sätze

    /// Einheitssatz für die ersten 20 km — gilt für Steuerjahre bis 2025.
    static let rateTo20km: Double = 0.30

    /// Jahreshöchstbetrag bei Kfz-Nutzung pro Dienstverhältnis
    /// (§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG) — seit 2004 unverändert.
    static let annualCapCar: Double = 4_500.00

    /// Schwellenwert für den erhöhten Satz (gilt nur für Steuerjahre bis 2025).
    static let threshold: Int = 20

    /// Flat-Rate-Satz ab 2026: 0,38 €/km einheitlich für alle Kilometer.
    /// Steueränderungsgesetz 2025, BGBl. I Nr. 363/2025.
    static let flatRateFrom2026: Double = 0.38

    // MARK: - Jahresabhängige Sätze

    /// Ab 2026 gilt ein einheitlicher Flat-Rate — kein Schwellenwert mehr.
    /// Steueränderungsgesetz 2025 (BGBl. I Nr. 363/2025).
    static func isFlatRate(year: Int) -> Bool { year >= 2026 }

    /// Satz ab dem 21. km für ein gegebenes Steuerjahr (nur relevant bis 2025).
    /// Vor 2021: identisch mit `rateTo20km` (einheitlicher Satz für alle km).
    static func rateFrom21km(year: Int) -> Double {
        if year >= 2022 { return 0.38 }
        if year == 2021 { return 0.35 }
        return 0.30  // vor 2021: kein erhöhter Satz
    }

    // MARK: - Berechnungen

    /// Pendlerpauschale pro Bürotag (ungekürzt, ohne Jahrescap).
    /// - Parameter distanceKm: Einfache Entfernung (kürzeste Straßenverbindung, §9 Abs. 1 Nr. 4 EStG)
    /// - Parameter year: Steuerjahr für jahresabhängigen Satz (Default: aktuelles Jahr)
    static func deductionPerDay(distanceKm: Int, year: Int = Calendar.current.component(.year, from: Date())) -> Double {
        guard distanceKm > 0 else { return 0 }
        // Ab 2026: Flat Rate 0,38 €/km für alle Kilometer (Steueränderungsgesetz 2025)
        if isFlatRate(year: year) {
            return Double(distanceKm) * flatRateFrom2026
        }
        let first = Double(min(distanceKm, threshold)) * rateTo20km
        let beyond = Double(max(0, distanceKm - threshold)) * rateFrom21km(year: year)
        return first + beyond
    }

    /// Gesamtabzug pro Arbeitsstätte — UNGEKÜRZT (ohne Jahreshöchstbetrag).
    /// Für den korrekten absetzbaren Betrag `effectiveTotalDeduction` verwenden.
    static func totalDeductionUncapped(distanceKm: Int, officeDays: Int, year: Int) -> Double {
        guard distanceKm > 0, officeDays > 0 else { return 0 }
        return deductionPerDay(distanceKm: distanceKm, year: year) * Double(officeDays)
    }

    /// Tatsächlich absetzbarer Gesamtbetrag unter Berücksichtigung des Jahreshöchstbetrags.
    ///
    /// ⚠️ RECHTSGRUNDLAGE:
    /// - PKW/Motorrad (capExempt = true): KEIN Cap — voller Betrag absetzbar
    ///   (§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG: „ein höherer Betrag als 4.500 €
    ///    ist anzusetzen, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung
    ///    überlassenen Kraftwagen benutzt.")
    /// - ÖPNV / Fahrrad / Fuß (capExempt = false): Cap 4.500 € gilt.
    ///
    /// - Parameters:
    ///   - distanceKm: Einfache Entfernung Wohnung–Büro
    ///   - officeDays: Anzahl Bürotage im Steuerjahr
    ///   - year: Steuerjahr
    ///   - transportMode: Verkehrsmittel (Default .car für maximale Absetzbarkeit)
    static func effectiveTotalDeduction(distanceKm: Int, officeDays: Int, year: Int, transportMode: TransportMode = .car) -> Double {
        let uncapped = totalDeductionUncapped(distanceKm: distanceKm, officeDays: officeDays, year: year)
        if transportMode.capExempt { return uncapped }     // PKW/Motorrad: kein Jahreshöchstbetrag
        return min(uncapped, annualCapCar)                 // ÖPNV/Fahrrad: 4.500 € Cap
    }

    /// True wenn der ungekürzte Betrag den Jahreshöchstbetrag übersteigt.
    static func exceedsCap(distanceKm: Int, officeDays: Int, year: Int) -> Bool {
        totalDeductionUncapped(distanceKm: distanceKm, officeDays: officeDays, year: year) > annualCapCar
    }

    // MARK: - Legacy / Abwärtskompatibilität

    /// Pendlerpauschale für aktuelles Jahr (Free-User / Legacy). Wendet Jahrescap an.
    static func totalDeduction(distanceKm: Int, officeDays: Int) -> Double {
        let year = Calendar.current.component(.year, from: Date())
        return effectiveTotalDeduction(distanceKm: distanceKm, officeDays: officeDays, year: year)
    }

    // MARK: - Premium: Mehrere Perioden

    /// Gesamtabzug über alle Arbeitsstätten-Perioden für ein gegebenes Jahr.
    /// Jede Periode (= Dienstverhältnis) hat ihren eigenen Jahreshöchstbetrag von 4.500 €.
    /// Bürotage werden aus dem Kalender gezählt oder manuell übernommen.
    static func totalDeduction(periods: [WorkplacePeriod], allDays: [WorkDay], year: Int) -> Double {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let yearEnd   = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        return periods.filter { $0.commuteKm > 0 }.reduce(0.0) { sum, period in
            let officeDays: Int
            if let manual = period.manualOfficeDays {
                officeDays = max(0, manual)
            } else {
                let start = (period.startDate ?? yearStart).startOfDay
                let end   = (period.endDate   ?? yearEnd).startOfDay
                officeDays = allDays.filter {
                    !$0.isHomeoffice &&
                    $0.specialType == nil &&
                    $0.date >= start &&
                    $0.date <= end &&
                    calendar.component(.year, from: $0.date) == year
                }.count
            }
            return sum + effectiveTotalDeduction(distanceKm: period.commuteKm, officeDays: officeDays, year: year, transportMode: period.transportMode)
        }
    }

    /// Abwärtskompatible Variante mit aktuellem Jahr.
    static func totalDeduction(periods: [WorkplacePeriod], allDays: [WorkDay]) -> Double {
        totalDeduction(periods: periods, allDays: allDays, year: Calendar.current.component(.year, from: Date()))
    }

    // MARK: - Detailinfo pro Periode (für PDF-Export)

    struct PeriodDetail {
        let period: WorkplacePeriod
        let officeDays: Int
        let perDay: Double
        let uncappedTotal: Double
        let effectiveTotal: Double
        /// True wenn der Jahreshöchstbetrag (4.500 €) tatsächlich angewendet wurde.
        /// Bei PKW/Motorrad immer false — kein Cap möglich (§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG).
        let capApplied: Bool
        let year: Int
        /// Verkehrsmittel dieser Periode — bestimmt ob Cap gilt.
        let transportMode: TransportMode

        var legalReference: String { "§9 Abs. 1 Satz 3 Nr. 4 EStG" }
        var capReference: String { "§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG" }
    }

    /// Berechnet die vollständigen Detailinformationen für jede Periode — für PDF-Export.
    static func periodDetails(periods: [WorkplacePeriod], allDays: [WorkDay], year: Int) -> [PeriodDetail] {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let yearEnd   = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        return periods.filter { $0.commuteKm > 0 }.map { period in
            let officeDays: Int
            if let manual = period.manualOfficeDays {
                officeDays = max(0, manual)
            } else {
                let start = (period.startDate ?? yearStart).startOfDay
                let end   = (period.endDate   ?? yearEnd).startOfDay
                officeDays = allDays.filter {
                    !$0.isHomeoffice &&
                    $0.specialType == nil &&
                    $0.date >= start &&
                    $0.date <= end &&
                    calendar.component(.year, from: $0.date) == year
                }.count
            }
            let perDay   = deductionPerDay(distanceKm: period.commuteKm, year: year)
            let uncapped = perDay * Double(officeDays)
            let effective = effectiveTotalDeduction(distanceKm: period.commuteKm, officeDays: officeDays, year: year, transportMode: period.transportMode)
            // Cap gilt nur wenn Verkehrsmittel NICHT capExempt und Betrag > 4.500 €
            let capApplied = !period.transportMode.capExempt ? uncapped > annualCapCar : false
            return PeriodDetail(
                period: period,
                officeDays: officeDays,
                perDay: perDay,
                uncappedTotal: uncapped,
                effectiveTotal: effective,
                capApplied: capApplied,
                year: year,
                transportMode: period.transportMode
            )
        }
    }
}

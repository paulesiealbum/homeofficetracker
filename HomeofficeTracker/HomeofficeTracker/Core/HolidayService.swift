// HolidayService.swift
// Berechnet gesetzliche Feiertage für DACH-Bundesländer ohne Internetverbindung.
// Algorithmus: Gaußsche Osterformel + länderspezifische Regeln.

import Foundation

struct HolidayService {

    struct Holiday: Identifiable {
        let id = UUID()
        let date: Date
        let name: String
    }

    // MARK: - Öffentliche API

    /// Berechnet alle Feiertage für ein Jahr und Bundesland.
    static func holidays(year: Int, state: FederalState) -> [Holiday] {
        let easter = easterSunday(year: year)
        var h: [Holiday] = []

        // ── Bundesweite Feiertage (Deutschland) ────────────────────────────

        if state.country != "CH" {
            h += [
                Holiday(date: fixed(1, 1, year),           name: "Neujahr"),
                Holiday(date: easter.adding(-2),            name: "Karfreitag"),
                Holiday(date: easter.adding(1),             name: "Ostermontag"),
                Holiday(date: fixed(1, 5, year),            name: "Tag der Arbeit"),
                Holiday(date: easter.adding(39),            name: "Christi Himmelfahrt"),
                Holiday(date: easter.adding(50),            name: "Pfingstmontag"),
                Holiday(date: fixed(25, 12, year),          name: "1. Weihnachtstag"),
                Holiday(date: fixed(26, 12, year),          name: "2. Weihnachtstag"),
            ]
        }

        if state.country == "DE" {
            h.append(Holiday(date: fixed(3, 10, year), name: "Tag der Deutschen Einheit"))
        }

        // ── Länderspezifische Feiertage Deutschland ─────────────────────────

        // Heilige Drei Könige (6. Jan) — BW, BY, ST (katholisch geprägt)
        if [.bw, .by, .st].contains(state) {
            h.append(Holiday(date: fixed(6, 1, year), name: "Heilige Drei Könige"))
        }

        // Internationaler Frauentag (8. März)
        if [.be, .mv, .bb, .th, .hb, .hh].contains(state) {
            h.append(Holiday(date: fixed(8, 3, year), name: "Internationaler Frauentag"))
        }

        // Gründonnerstag — thüringische Gemeinden (kein offizieller Landesfeiertag, entfernt)

        // Fronleichnam (Donnerstag nach Pfingstsonntag + 11 Tage = Pfingsten + 11)
        // easter + 60 = Fronleichnam
        if [.bw, .by, .he, .nw, .rp, .sl, .sn, .th].contains(state) {
            h.append(Holiday(date: easter.adding(60), name: "Fronleichnam"))
        }

        // Mariä Himmelfahrt (15. Aug) — BY (kath. Gemeinden), SL
        if [.by, .sl].contains(state) {
            h.append(Holiday(date: fixed(15, 8, year), name: "Mariä Himmelfahrt"))
        }

        // Weltkindertag (20. Sep) — Thüringen
        if state == .th {
            h.append(Holiday(date: fixed(20, 9, year), name: "Weltkindertag"))
        }

        // Reformationstag (31. Okt) — evangelisch geprägte Bundesländer
        if [.bb, .hb, .hh, .mv, .ni, .sn, .st, .sh, .th].contains(state) {
            h.append(Holiday(date: fixed(31, 10, year), name: "Reformationstag"))
        }

        // Allerheiligen (1. Nov) — katholisch geprägte Bundesländer
        if [.bw, .by, .nw, .rp, .sl].contains(state) {
            h.append(Holiday(date: fixed(1, 11, year), name: "Allerheiligen"))
        }

        // Buß- und Bettag — nur Sachsen (Mittwoch vor dem 23. November)
        if state == .sn {
            h.append(Holiday(date: bussUndBettag(year: year), name: "Buß- und Bettag"))
        }

        // ── Österreich ───────────────────────────────────────────────────────

        if state == .at {
            h += [
                Holiday(date: fixed(1, 1, year),   name: "Neujahr"),
                Holiday(date: fixed(6, 1, year),   name: "Heilige Drei Könige"),
                Holiday(date: easter.adding(-2),   name: "Karfreitag"),  // nur evang.
                Holiday(date: easter.adding(1),    name: "Ostermontag"),
                Holiday(date: fixed(1, 5, year),   name: "Staatsfeiertag"),
                Holiday(date: easter.adding(39),   name: "Christi Himmelfahrt"),
                Holiday(date: easter.adding(50),   name: "Pfingstmontag"),
                Holiday(date: easter.adding(60),   name: "Fronleichnam"),
                Holiday(date: fixed(15, 8, year),  name: "Mariä Himmelfahrt"),
                Holiday(date: fixed(26, 10, year), name: "Nationalfeiertag"),
                Holiday(date: fixed(1, 11, year),  name: "Allerheiligen"),
                Holiday(date: fixed(8, 12, year),  name: "Mariä Empfängnis"),
                Holiday(date: fixed(25, 12, year), name: "1. Weihnachtstag"),
                Holiday(date: fixed(26, 12, year), name: "Stefanitag"),
            ]
        }

        // ── Schweiz (nationale Feiertage) ────────────────────────────────────
        // Kantonale Feiertage werden hier nicht abgebildet (zu viele Variationen).

        if state == .ch {
            h += [
                Holiday(date: fixed(1, 1, year),   name: "Neujahr"),
                Holiday(date: fixed(2, 1, year),   name: "Berchtoldstag"),  // meiste Kantone
                Holiday(date: easter.adding(-2),   name: "Karfreitag"),
                Holiday(date: easter.adding(1),    name: "Ostermontag"),
                Holiday(date: fixed(1, 5, year),   name: "Tag der Arbeit"),  // nicht alle Kt.
                Holiday(date: easter.adding(39),   name: "Auffahrt"),
                Holiday(date: easter.adding(50),   name: "Pfingstmontag"),
                Holiday(date: fixed(1, 8, year),   name: "Bundesfeiertag"),
                Holiday(date: fixed(25, 12, year), name: "1. Weihnachtstag"),
                Holiday(date: fixed(26, 12, year), name: "2. Weihnachtstag"),
            ]
        }

        return h
            .uniqued(by: { Calendar.current.isDate($0.date, inSameDayAs: $1.date) })
            .sorted { $0.date < $1.date }
    }

    /// Gibt ein Dictionary [Date: HolidayName] für einen bestimmten Monat zurück.
    static func holidayMap(month: Date, state: FederalState) -> [Date: String] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let targetMonth = calendar.component(.month, from: month)

        var result: [Date: String] = [:]
        for holiday in holidays(year: year, state: state) {
            if calendar.component(.month, from: holiday.date) == targetMonth {
                result[holiday.date.startOfDay] = holiday.name
            }
        }
        return result
    }

    // MARK: - Gaußsche Osterformel (Gregorianischer Kalender)

    static func easterSunday(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return fixed(day, month, year)
    }

    // MARK: - Hilfsmethoden

    private static func fixed(_ day: Int, _ month: Int, _ year: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return Calendar.current.date(from: comps) ?? Date()
    }

    /// Buß- und Bettag: letzter Mittwoch vor dem 23. November
    private static func bussUndBettag(year: Int) -> Date {
        let nov23 = fixed(23, 11, year)
        // Apple weekday: 1=Sun,2=Mon,...,4=Wed,...,7=Sat
        let weekday = Calendar.current.component(.weekday, from: nov23)
        // Tage zurück bis zum Mittwoch vor Nov 23 (inkl. wenn Nov 23 selbst ein Mi ist → 7 zurück)
        let daysBack = (weekday == 4) ? 7 : (weekday + 3) % 7
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: nov23) ?? nov23
    }
}

// MARK: - Hilfserweiterungen

private extension Date {
    func adding(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

private extension Array {
    func uniqued(by equality: (Element, Element) -> Bool) -> [Element] {
        reduce(into: [Element]()) { result, element in
            if !result.contains(where: { equality($0, element) }) {
                result.append(element)
            }
        }
    }
}

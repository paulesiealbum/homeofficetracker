// PDFExportService.swift
// Finanzamtstauglicher PDF-Nachweis für Homeoffice-Pauschale und Entfernungspauschale.
// Alle steuerlichen Werte kommen aus LegalConfiguration / CommuterConstants — nie hardcoded.

import UIKit
import Foundation

struct PDFExportService {

    // MARK: - Öffentliche API

    static func generatePDF(
        days: [WorkDay],
        year: Int,
        userName: String,
        employmentType: EmploymentType,
        homeAddress: String = "",
        workplacePeriods: [WorkplacePeriod] = []
    ) -> Data {
        let cfg = LegalConfiguration.config(for: year)
        let today = Calendar.current.startOfDay(for: Date())
        // Nur vergangene/heutige Tage — Selbstauskunft gilt nur für Tatsachen, nicht für Planungen
        let pastDays = days.filter { $0.date <= today }

        let hoDays = pastDays
            .filter { $0.isHomeoffice && $0.specialType == nil
                       && Calendar.current.component(.year, from: $0.date) == year }
            .sorted { $0.date < $1.date }

        let pendlerDetails = CommuterConstants.periodDetails(
            periods: workplacePeriods,
            allDays: pastDays,   // ebenfalls nur vergangene Tage — kein Vorgriff auf geplante Bürotage
            year: year
        )

        let html = buildHTML(
            hoDays: hoDays,
            year: year,
            cfg: cfg,
            userName: userName,
            employmentType: employmentType,
            homeAddress: homeAddress,
            pendlerDetails: pendlerDetails
        )
        return renderHTMLtoPDF(html: html)
    }

    // MARK: - HTML-Hauptdokument

    private static func buildHTML(
        hoDays: [WorkDay],
        year: Int,
        cfg: LegalConfiguration.YearConfig,
        userName: String,
        employmentType: EmploymentType,
        homeAddress: String,
        pendlerDetails: [CommuterConstants.PeriodDetail]
    ) -> String {
        let hoCapped     = min(hoDays.count, cfg.maxDays)
        let hoTotal      = Double(hoCapped) * cfg.dailyRate
        let pendlerTotal = pendlerDetails.reduce(0.0) { $0 + $1.effectiveTotal }
        let gesamtTotal  = hoTotal + pendlerTotal

        let nameDisplay = userName.isEmpty ? "[Name nicht angegeben]" : userName
        let createdOn   = DateFormatter.germanLong.string(from: Date())

        let hasPendler = !pendlerDetails.isEmpty

        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
        <meta charset="UTF-8">
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif;
                 font-size: 10pt; color: #1a1a1a; line-height: 1.4; }
          .app-label { font-size: 8pt; color: #999; margin-bottom: 12px; }
          h1 { font-size: 18pt; font-weight: 700; text-align: center; margin-bottom: 4px; }
          h2 { font-size: 12pt; font-weight: 700; margin: 20px 0 10px 0;
               padding-bottom: 4px; border-bottom: 2px solid #1a7f37; color: #1a7f37; }
          h2.pendler { border-bottom-color: #1a5fa0; color: #1a5fa0; }
          h2.gesamt  { border-bottom-color: #444; color: #444; }
          .subtitle { font-size: 11pt; color: #555; text-align: center; margin-bottom: 20px; }
          hr { border: none; border-top: 1px solid #ddd; margin: 16px 0; }
          .info-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
          .info-table td { padding: 3px 0; vertical-align: top; width: 50%; }
          .info-label { font-size: 7.5pt; color: #999; text-transform: uppercase;
                        letter-spacing: 0.3px; display: block; margin-bottom: 1px; }
          .info-value { font-size: 10pt; font-weight: 600; }
          .summary-box { border-radius: 8px; padding: 14px 16px; margin-bottom: 16px;
                         border: 1px solid #e8eaed; }
          .summary-box.ho      { background: #f4faf4; border-color: #c8dfc8; }
          .summary-box.pendler { background: #f0f6fc; border-color: #b8d0e8; }
          .summary-box.gesamt  { background: #f5f5f5; border-color: #ddd; }
          .summary-title { font-size: 7.5pt; color: #999; text-transform: uppercase;
                           letter-spacing: 0.3px; margin-bottom: 10px; }
          .summary-row { display: table; width: 100%; padding: 3px 0; }
          .summary-row .label { display: table-cell; color: #555; }
          .summary-row .value { display: table-cell; text-align: right; font-weight: 500; }
          .summary-divider { border: none; border-top: 1px solid #d0d5db; margin: 10px 0; }
          .summary-total-row { display: table; width: 100%; padding: 4px 0; }
          .summary-total-row .label { display: table-cell; font-size: 11pt; font-weight: 700; }
          .summary-total-row .value { display: table-cell; text-align: right;
                                      font-size: 13pt; font-weight: 700; }
          .ho-total-value   { color: #1a7f37; }
          .pendler-total-value { color: #1a5fa0; }
          .gesamt-total-value  { color: #333; }
          .summary-max { font-size: 8pt; color: #888; margin-top: 6px; }
          .cap-warning { font-size: 8pt; color: #b85c00; margin-top: 6px;
                         background: #fff8f0; padding: 6px 8px; border-radius: 4px;
                         border-left: 3px solid #e07000; }
          table.day-table { width: 100%; border-collapse: collapse;
                            font-size: 9.5pt; margin-top: 4px; }
          table.day-table thead th { background: #f0f2f4; padding: 6px 8px;
                                     text-align: left; font-size: 8pt;
                                     text-transform: uppercase; letter-spacing: 0.3px;
                                     color: #666; border-bottom: 2px solid #ccc; }
          table.day-table thead th.right { text-align: right; }
          table.day-table tbody td { padding: 5px 8px; border-bottom: 1px solid #efefef;
                                     vertical-align: middle; }
          table.day-table tbody td.right { text-align: right; }
          table.day-table tbody td.note  { color: #777; font-size: 8.5pt; }
          tr.month-header td { background: #eaedf0; font-weight: 700; font-size: 9pt;
                               padding: 7px 8px; border-bottom: 1px solid #ccc;
                               border-top: 2px solid #ccc; }
          tr.subtotal td { background: #f8f9fa; font-weight: 600; font-size: 9pt;
                           padding: 5px 8px; border-top: 1px solid #ddd;
                           border-bottom: 2px solid #ccc; color: #444; }
          tr.subtotal td.right { text-align: right; }
          tr.grand-total td { background: #edf7ef; font-weight: 700; font-size: 10pt;
                              padding: 8px 8px; border-top: 2px solid #1a7f37; color: #1a7f37; }
          tr.grand-total td.right { text-align: right; }
          .pendler-period-box { background: #f0f6fc; border: 1px solid #c0d8f0;
                                border-radius: 8px; padding: 12px 14px; margin-bottom: 12px; }
          .pendler-period-title { font-size: 10pt; font-weight: 700; margin-bottom: 8px;
                                  color: #1a5fa0; }
          .selbstauskunft { margin-top: 20px; padding: 12px 14px; border: 1px solid #c8dfc8;
                            border-radius: 6px; background: #f4faf4; }
          .selbstauskunft-title { font-size: 8.5pt; font-weight: 600; color: #1a5c1a;
                                  margin-bottom: 6px; }
          .selbstauskunft-text { font-size: 8.5pt; color: #2a2a2a; line-height: 1.5; }
          .disclaimer { font-size: 7.5pt; color: #888; margin-top: 20px; padding-top: 12px;
                        border-top: 1px solid #e0e0e0; line-height: 1.55; }
          .disclaimer p { margin-bottom: 5px; }
          .disclaimer strong { color: #555; }
        </style>
        </head>
        <body>
          <p class="app-label">Homeoffice-Tracker · Steuerjahr \(year)</p>
          <h1>Steuernachweis Homeoffice &amp; Pendler</h1>
          <p class="subtitle">Steuerjahr \(year) · Erstellt am \(createdOn)</p>
          <hr>

          \(buildInfoTable(nameDisplay: nameDisplay, employmentType: employmentType, homeAddress: homeAddress))

          <!-- ═══════════════════════════════════════════════════════════ -->
          <!-- SECTION 1: HOMEOFFICE-PAUSCHALE                            -->
          <!-- ═══════════════════════════════════════════════════════════ -->
          <h2>1. Homeoffice-Pauschale</h2>
          \(buildHOSummary(hoDays: hoDays, hoCapped: hoCapped, hoTotal: hoTotal, cfg: cfg))
          \(buildHOTable(hoDays: hoDays, cfg: cfg))

          <!-- ═══════════════════════════════════════════════════════════ -->
          <!-- SECTION 2: ENTFERNUNGSPAUSCHALE                            -->
          <!-- ═══════════════════════════════════════════════════════════ -->
          \(hasPendler ? buildPendlerSection(details: pendlerDetails, pendlerTotal: pendlerTotal, year: year) : "")

          <!-- ═══════════════════════════════════════════════════════════ -->
          <!-- GESAMTÜBERSICHT                                            -->
          <!-- ═══════════════════════════════════════════════════════════ -->
          \(hasPendler ? buildGesamtSection(hoTotal: hoTotal, pendlerTotal: pendlerTotal, gesamtTotal: gesamtTotal) : "")

          \(buildSelbstauskunft())
          \(buildDisclaimer(cfg: cfg, employmentType: employmentType, hasPendler: hasPendler, pendlerDetails: pendlerDetails))
        </body>
        </html>
        """
    }

    // MARK: - Info-Tabelle (Kopfzeile)

    private static func buildInfoTable(
        nameDisplay: String,
        employmentType: EmploymentType,
        homeAddress: String
    ) -> String {
        let adressRow = homeAddress.isEmpty ? "" : """
        <tr>
          <td colspan="2">
            <span class="info-label">Wohnanschrift (häuslicher Arbeitsplatz)</span>
            <span class="info-value">\(homeAddress)</span>
          </td>
        </tr>
        """
        return """
        <table class="info-table">
          <tr>
            <td><span class="info-label">Name</span>
                <span class="info-value">\(nameDisplay)</span></td>
            <td><span class="info-label">Beschäftigungsstatus</span>
                <span class="info-value">\(employmentType.displayName)</span></td>
          </tr>
          <tr>
            <td><span class="info-label">Abzugsart</span>
                <span class="info-value">\(employmentType.deductionType)</span></td>
            <td></td>
          </tr>
          \(adressRow)
        </table>
        """
    }

    // MARK: - Section 1: Homeoffice-Zusammenfassung

    private static func buildHOSummary(
        hoDays: [WorkDay],
        hoCapped: Int,
        hoTotal: Double,
        cfg: LegalConfiguration.YearConfig
    ) -> String {
        """
        <div class="summary-box ho">
          <p class="summary-title">Zusammenfassung · §\(cfg.legalBasis.components(separatedBy: "§").last?.trimmingCharacters(in: .whitespaces) ?? cfg.legalBasis)</p>
          <div class="summary-row">
            <span class="label">Homeoffice-Tage (eingetragen)</span>
            <span class="value">\(hoDays.count) Tage</span>
          </div>
          <div class="summary-row">
            <span class="label">Anerkannte Tage (max. \(cfg.maxDays) gemäß Gesetz)</span>
            <span class="value">\(hoCapped) Tage</span>
          </div>
          <div class="summary-row">
            <span class="label">Pauschale pro Tag</span>
            <span class="value">\(cfg.dailyRateFormatted)</span>
          </div>
          <hr class="summary-divider">
          <div class="summary-total-row">
            <span class="label">Abzugsbetrag Homeoffice-Pauschale</span>
            <span class="value ho-total-value">\(hoTotal.eur)</span>
          </div>
          <p class="summary-max">Gesetzliches Maximum: \(cfg.maxDays) Tage · \(cfg.maxAmountFormatted)</p>
        </div>
        """
    }

    // MARK: - Section 1: Homeoffice-Tagesliste

    private static func buildHOTable(hoDays: [WorkDay], cfg: LegalConfiguration.YearConfig) -> String {
        guard !hoDays.isEmpty else {
            return "<p style=\"color:#999;font-size:9pt;margin:8px 0 16px\">Keine Homeoffice-Tage eingetragen.</p>"
        }

        let calendar = Calendar.current
        var html = ""
        var currentMonth = -1
        var monthCount = 0
        var monthTotal = 0.0
        var globalIndex = 0

        html += """
        <table class="day-table">
        <thead><tr>
          <th style="width:30px">Nr.</th><th>Datum</th>
          <th class="right" style="width:70px">Betrag</th><th>Notiz</th>
        </tr></thead><tbody>
        """

        for day in hoDays {
            let month = calendar.component(.month, from: day.date)
            if month != currentMonth {
                if currentMonth != -1 {
                    html += subtotalRow(month: currentMonth, count: monthCount, total: monthTotal)
                }
                currentMonth = month
                monthCount = 0; monthTotal = 0.0
                html += monthHeaderRow(date: day.date)
            }
            globalIndex += 1
            monthCount  += 1
            let rate     = globalIndex <= cfg.maxDays ? cfg.dailyRate : 0.0
            monthTotal  += rate
            let amountStr = globalIndex <= cfg.maxDays ? cfg.dailyRateFormatted : "–"
            let rowStyle  = globalIndex > cfg.maxDays ? " style=\"color:#bbb\"" : ""
            let note      = day.note?.isEmpty == false ? (day.note ?? "") : ""
            html += "<tr\(rowStyle)><td>\(globalIndex)</td><td>\(DateFormatter.germanFull.string(from: day.date))</td><td class=\"right\">\(amountStr)</td><td class=\"note\">\(note)</td></tr>\n"
        }
        if currentMonth != -1 {
            html += subtotalRow(month: currentMonth, count: monthCount, total: monthTotal)
        }
        let cappedTotal = Double(min(hoDays.count, cfg.maxDays)) * cfg.dailyRate
        html += """
        <tr class="grand-total">
          <td colspan="2">Gesamt Homeoffice-Pauschale</td>
          <td class="right">\(cappedTotal.eur)</td>
          <td>\(min(hoDays.count, cfg.maxDays)) Tage</td>
        </tr>
        """
        html += "</tbody></table>"
        return html
    }

    // MARK: - Section 2: Entfernungspauschale

    private static func buildPendlerSection(
        details: [CommuterConstants.PeriodDetail],
        pendlerTotal: Double,
        year: Int
    ) -> String {
        var html = "<h2 class=\"pendler\">2. Entfernungspauschale</h2>"
        html += "<p style=\"font-size:8.5pt;color:#555;margin-bottom:12px\">Rechtsgrundlage: §9 Abs. 1 Satz 3 Nr. 4 EStG (Arbeitnehmer) / §4 Abs. 5a EStG (Selbstständige). Nur einfache Entfernung (kürzeste Straßenverbindung).</p>"

        for (i, detail) in details.enumerated() {
            let p = detail.period
            let mode = detail.transportMode
            html += """
            <div class="pendler-period-box">
              <p class="pendler-period-title">\(details.count > 1 ? "Arbeitsstätte \(i+1): " : "")\(p.displayLabel)</p>
            """

            // Adresse
            if !p.workAddress.isEmpty {
                html += "<div class=\"summary-row\"><span class=\"label\">Arbeitsadresse</span><span class=\"value\">\(p.workAddress)</span></div>"
            }
            // Zeitraum
            if let desc = p.periodDescription {
                html += "<div class=\"summary-row\"><span class=\"label\">Zeitraum</span><span class=\"value\">\(desc)</span></div>"
            }
            // Verkehrsmittel
            html += "<div class=\"summary-row\"><span class=\"label\">Verkehrsmittel</span><span class=\"value\">\(mode.displayName)\(mode.capExempt ? " — kein Jahreshöchstbetrag (§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG)" : " — Jahreshöchstbetrag 4.500 € gilt")</span></div>"

            // Rate-Aufschlüsselung
            let km = p.commuteKm
            let threshold = CommuterConstants.threshold
            let rate21 = CommuterConstants.rateFrom21km(year: year)
            let rateBreakdown: String
            if km <= threshold {
                rateBreakdown = "\(km) km × 0,30 €/km = \(detail.perDay.eur)/Tag"
            } else {
                rateBreakdown = "\(threshold) km × 0,30 €/km + \(km - threshold) km × \(String(format: "%.2f", rate21).replacingOccurrences(of: ".", with: ",")) €/km = \(detail.perDay.eur)/Tag"
            }

            html += """
              <div class="summary-row"><span class="label">Einfache Entfernung</span><span class="value">\(km) km</span></div>
              <div class="summary-row"><span class="label">Tagessatz (\(year))</span><span class="value">\(rateBreakdown)</span></div>
              <div class="summary-row"><span class="label">Bürotage \(p.manualOfficeDays != nil ? "(manuell)" : "(aus Kalender)")</span><span class="value">\(detail.officeDays) Tage</span></div>
              <hr class="summary-divider">
            """

            if detail.capApplied {
                // Nur ÖPNV/Fahrrad können den Cap erreichen
                html += """
                <div class="summary-row"><span class="label">Ungekürzte Pauschale</span><span class="value">\(detail.uncappedTotal.eur)</span></div>
                """
                html += """
                <div class="cap-warning">
                  ⚠️ Jahreshöchstbetrag angewendet: Der ungekürzte Betrag (\(detail.uncappedTotal.eur)) übersteigt den gesetzlichen Höchstbetrag von \(CommuterConstants.annualCapCar.eur) für \(mode.displayName) (§ 9 Abs. 1 Satz 3 Nr. 4 EStG). Alternativ können tatsächliche Ticketkosten angesetzt werden, falls diese höher sind (§ 9 Abs. 1 Satz 3 Nr. 4a EStG) — bitte mit Steuerberater prüfen.
                </div>
                """
            }

            html += """
              <div class="summary-total-row">
                <span class="label">Abzugsbetrag Entfernungspauschale\(detail.capApplied ? " (auf 4.500 € begrenzt)" : "")</span>
                <span class="value pendler-total-value">\(detail.effectiveTotal.eur)</span>
              </div>
            </div>
            """
        }

        // Pendler-Gesamtzeile (nur bei mehreren Perioden)
        if details.count > 1 {
            html += """
            <div class="summary-box pendler">
              <div class="summary-total-row">
                <span class="label">Summe Entfernungspauschale (alle Arbeitsstätten)</span>
                <span class="value pendler-total-value">\(pendlerTotal.eur)</span>
              </div>
            </div>
            """
        }
        return html
    }

    // MARK: - Gesamtübersicht (wenn Pendler vorhanden)

    private static func buildGesamtSection(
        hoTotal: Double,
        pendlerTotal: Double,
        gesamtTotal: Double
    ) -> String {
        """
        <h2 class="gesamt">3. Gesamtübersicht</h2>
        <div class="summary-box gesamt">
          <p class="summary-title">Summe aller steuerlich relevanten Abzüge</p>
          <div class="summary-row">
            <span class="label">Homeoffice-Pauschale</span>
            <span class="value">\(hoTotal.eur)</span>
          </div>
          <div class="summary-row">
            <span class="label">Entfernungspauschale</span>
            <span class="value">\(pendlerTotal.eur)</span>
          </div>
          <hr class="summary-divider">
          <div class="summary-total-row">
            <span class="label">Gesamtabzug</span>
            <span class="value gesamt-total-value">\(gesamtTotal.eur)</span>
          </div>
          <p class="summary-max" style="color:#b85c00">
            ⚠️ Homeoffice-Pauschale und Entfernungspauschale schließen sich pro Tag gegenseitig aus.
            An Homeoffice-Tagen entfällt die Entfernungspauschale und umgekehrt.
            Die App erfasst und zählt beide Tagestypen getrennt.
          </p>
        </div>
        """
    }

    // MARK: - Selbstauskunft

    private static func buildSelbstauskunft() -> String {
        """
        <div class="selbstauskunft">
          <p class="selbstauskunft-title">Selbstauskunft des Steuerpflichtigen</p>
          <p class="selbstauskunft-text">
            Ich versichere, dass ich an den oben aufgeführten Homeoffice-Tagen meine berufliche Tätigkeit
            überwiegend in meiner häuslichen Wohnung ausgeübt habe und an diesen Tagen keine
            außerhalb der häuslichen Wohnung belegene erste Tätigkeitsstätte aufgesucht wurde
            (§ 4 Abs. 5 Satz 1 Nr. 6c EStG).
            An den erfassten Bürotagen habe ich die angegebene erste Tätigkeitsstätte tatsächlich aufgesucht.
            Die Angaben sind vollständig und nach bestem Wissen und Gewissen zutreffend.
          </p>
        </div>
        """
    }

    // MARK: - Arbeitnehmer-Pauschbetrag (§ 9a Satz 1 Nr. 1 Buchst. a EStG)

    /// Jahresabhängiger Werbungskosten-Pauschbetrag für Arbeitnehmer.
    /// Quelle: RECHTSLAGE.md — § 9a Satz 1 Nr. 1 Buchst. a EStG
    private static func arbeitnehmerPauschbetrag(year: Int) -> Double {
        if year >= 2023 { return 1_230.00 }  // JStG 2022, BGBl. I 2022 S. 2294
        if year == 2022 { return 1_200.00 }  // Steuerentlastungsgesetz 2022, BGBl. I 2022 S. 749
        return 1_000.00                       // bis 2021: unveränderter Grundbetrag
    }

    // MARK: - Disclaimer

    private static func buildDisclaimer(
        cfg: LegalConfiguration.YearConfig,
        employmentType: EmploymentType,
        hasPendler: Bool,
        pendlerDetails: [CommuterConstants.PeriodDetail]
    ) -> String {
        let capAnyApplied = pendlerDetails.contains { $0.capApplied }

        var notes = """
        <p><strong>Rechtsgrundlage Homeoffice-Pauschale:</strong> \(cfg.legalBasis). Stand: \(cfg.verifiedOn). Abzugsart: \(employmentType.deductionType).</p>
        """

        if hasPendler {
            notes += """
            <p><strong>Rechtsgrundlage Entfernungspauschale:</strong> §9 Abs. 1 Satz 3 Nr. 4 EStG. Nur einfache Entfernung (kürzeste Straßenverbindung). Gilt für Fahrten zur ersten Tätigkeitsstätte.</p>
            <p><strong>Gegenseitiger Ausschluss:</strong> Homeoffice-Pauschale (\(cfg.legalBasis)) und Entfernungspauschale (§ 9 Abs. 1 Satz 3 Nr. 4 EStG) können für denselben Kalendertag nicht gleichzeitig geltend gemacht werden. Die App erfasst beide Tagestypen getrennt und weist sie separat aus.</p>
            <p><strong>Jahreshöchstbetrag Entfernungspauschale:</strong> PKW und Motorrad: kein Höchstbetrag — voller Pauschalbetrag ist absetzbar (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG: „ein höherer Betrag als 4.500 Euro ist anzusetzen, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung überlassenen Kraftwagen benutzt"). ÖPNV und Fahrrad/Fuß: Jahreshöchstbetrag \(CommuterConstants.annualCapCar.eur) je Dienstverhältnis (§ 9 Abs. 1 Satz 3 Nr. 4 EStG); bei ÖPNV alternativ tatsächliche Ticketkosten, wenn höher (§ 9 Abs. 1 Satz 3 Nr. 4a EStG). \(capAnyApplied ? "In diesem Dokument wurde der Jahreshöchstbetrag auf mindestens eine Arbeitsstätte angewendet." : "")</p>
            """
        }

        if employmentType == .employee {
            let pauschbetrag = arbeitnehmerPauschbetrag(year: cfg.year)
            notes += """
            <p><strong>Arbeitnehmer-Pauschbetrag:</strong> Für das Steuerjahr \(cfg.year) gilt ein Werbungskosten-Pauschbetrag von \(pauschbetrag.eur) (§ 9a Satz 1 Nr. 1 Buchst. a EStG). Ein steuerlicher Mehrwert aus den ausgewiesenen Werbungskosten entsteht erst bei Überschreitung dieses Betrags.</p>
            """
        }

        notes += """
        <p><strong>Geltungsbereich:</strong> Diese Berechnung basiert ausschließlich auf dem deutschen Einkommensteuergesetz (EStG). Für Steuerpflichtige in Österreich, der Schweiz oder anderen Ländern gelten abweichende Regelungen — bitte einen Steuerberater hinzuziehen.</p>
        <p><strong>Haftungsausschluss:</strong> Dieses Dokument wurde durch die App Homeoffice-Tracker auf Basis der Nutzereingaben erstellt. Es ersetzt keine individuelle Steuerberatung. Die steuerliche Anerkennung obliegt dem zuständigen Finanzamt.</p>
        """

        return "<div class=\"disclaimer\">\(notes)</div>"
    }

    // MARK: - Hilfsmethoden Tabellenbau

    private static func monthHeaderRow(date: Date) -> String {
        let year  = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        return "<tr class=\"month-header\"><td colspan=\"4\">\(DateFormatter.monthYear(month: month, year: year))</td></tr>\n"
    }

    private static func subtotalRow(month: Int, count: Int, total: Double) -> String {
        """
        <tr class="subtotal">
          <td colspan="2">\(DateFormatter.monthName(for: month)): \(count) Tage</td>
          <td class="right">\(total.eur)</td><td></td>
        </tr>
        """
    }

    // MARK: - HTML → PDF

    private static func renderHTMLtoPDF(html: String) -> Data {
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer  = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let pageSize      = CGSize(width: 595.28, height: 841.89)
        let margin: CGFloat = 40
        let pageRect      = CGRect(origin: .zero, size: pageSize)
        let printableRect = CGRect(x: margin, y: margin,
                                   width: pageSize.width  - 2 * margin,
                                   height: pageSize.height - 2 * margin)
        renderer.setValue(NSValue(cgRect: pageRect),      forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: pageRect)
        }
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

// MARK: - DateFormatter Hilfsmethoden

private extension DateFormatter {
    static let germanFull: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE, dd. MMMM yyyy"
        f.locale = Locale(identifier: "de_DE"); return f
    }()
    static let germanLong: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .none
        f.locale = Locale(identifier: "de_DE"); return f
    }()
    static func monthName(for month: Int) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_DE")
        return f.monthSymbols[month - 1]
    }
    static func monthYear(month: Int, year: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "de_DE")
        var c = DateComponents(); c.year = year; c.month = month; c.day = 1
        return f.string(from: Calendar.current.date(from: c) ?? Date())
    }
}

// MARK: - Formatierungshelfer

private extension Double {
    var eur: String {
        self.formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
    }
}

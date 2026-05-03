# PDF-EXPORT-SPEC.md — Anforderungen an den PDF-Export

> Adressiert: **Case 1 (Sandra – Steuerberaterin)** — Dokument muss finanzamtstauglich sein  
> Referenz: RECHTSLAGE.md (für Beträge und Rechtsgrundlage), UX-Audit-UserUsecases.md

---

## Kernprinzip

Das exportierte PDF ist das **primäre Wertversprechen der App** und das einzige Dokument, das ein Nutzer gegenüber dem Finanzamt oder seinem Steuerberater vorlegen kann. Ein PDF das nur eine Gesamtzahl zeigt (z.B. „187 Tage, 1.122€") ist für das Finanzamt **wertlos**. Das Finanzamt oder der Steuerberater braucht eine **tagesgenaue, nachvollziehbare Aufstellung**.

Jedes generierte PDF muss **sofort und ohne Rückfragen** von einem Steuerberater akzeptiert werden können.

---

## Pflichtinhalt — Mindestanforderungen (Finanzamtstauglichkeit)

### Header-Bereich (oben)

| Feld | Inhalt | Pflicht |
|------|--------|---------|
| Dokumenttitel | „Nachweis Homeoffice-Tage" | ✅ |
| Veranlagungszeitraum | „Steuerjahr 2025" | ✅ |
| Name des Nutzers | Eingetragen in Einstellungen, default „[Name eintragen]" | ✅ |
| Erstellungsdatum | Automatisch, „Erstellt am: 12. April 2026" | ✅ |
| App-Version + Rechtsgrundlage | „Homeoffice-Tracker v1.0 · § 4 Abs. 5 Nr. 6c EStG" | ✅ |
| Beschäftigungsstatus | „Arbeitnehmer" oder „Selbstständig" (aus Onboarding-Auswahl) | ✅ |

---

### Zusammenfassungs-Block (prominent, oben nach Header)

```
┌─────────────────────────────────────────────────────────┐
│  Steuerjahr 2025                                        │
│                                                         │
│  Homeoffice-Tage gesamt:        187 Tage               │
│  Pauschale pro Tag:              6,00 €                 │
│  Absetzbare Summe:           1.122,00 €                 │
│                                                         │
│  Gesetzliches Maximum:      210 Tage / 1.260,00 €      │
│  Abzugsart:                 Werbungskosten (§ 9 EStG)  │
└─────────────────────────────────────────────────────────┘
```

Alle Beträge aus `LegalConfiguration.config(for: year)` — niemals hardcoded.  
Abzugsart dynamisch nach gespeichertem Beschäftigungsstatus:
- Arbeitnehmer → „Werbungskosten (§ 9 Abs. 5 EStG)"
- Selbstständig → „Betriebsausgaben (§ 4 Abs. 5 Nr. 6c EStG)"

---

### Tagesgenaue Auflistung (Kernanforderung — keine Abkürzung möglich)

**Format:** Tabelle mit einer Zeile pro Homeoffice-Tag, sortiert chronologisch (älteste zuerst).

| Spalten (Pflicht) | Beispielinhalt |
|---|---|
| Nr. | 1, 2, 3, … |
| Datum | Montag, 06. Januar 2025 |
| Wochentag | (bereits in Datum enthalten) |
| Betrag | 6,00 € |
| Notiz (optional) | „Kundenprojekt XY" oder leer |

**Seitenumbruch:** Tabelle bricht automatisch auf neue Seiten um, Header wiederholt sich auf jeder Seite (PDFKit: Kein manuelles Paging nötig, aber Tabellen-Header wiederholen).

**Kein Grouping:** Keine „Zusammenfassung pro Monat" als Ersatz für die Einzelliste. Monatliche Zwischensummen können zusätzlich angezeigt werden (optional, nach Einzelliste), ersetzen sie aber nicht.

**Beispiel-Struktur der Einzelliste:**

```
Januar 2025
──────────────────────────────────────────────────────
 1 │ Mo, 06. Januar 2025   │  6,00 €  │
 2 │ Di, 07. Januar 2025   │  6,00 €  │
 3 │ Do, 09. Januar 2025   │  6,00 €  │  Teammeeting remote
 4 │ Fr, 10. Januar 2025   │  6,00 €  │
──────────────────────────────────────────────────────
                  Januar:  4 Tage   │ 24,00 €

Februar 2025
──────────────────────────────────────────────────────
 5 │ Mo, 03. Februar 2025  │  6,00 €  │
...
```

---

### Footer (jede Seite)

```
Seite X von Y  |  Homeoffice-Tracker  |  Alle Angaben ohne Gewähr  |  § 4 Abs. 5 Nr. 6c EStG
```

Haftungshinweis (letzte Seite, vollständiger Text):

> „Diese Aufstellung wurde durch die App Homeoffice-Tracker erstellt und basiert auf den Angaben des Nutzers. Sie ersetzt keine individuelle Steuerberatung. Die steuerliche Anerkennung der angegebenen Tage obliegt dem Nutzer und ggf. dem zuständigen Finanzamt. Rechtsgrundlage: § 4 Abs. 5 Satz 1 Nr. 6c EStG i.V.m. § 9 Abs. 5 EStG. Stand der Rechtslage: [LegalConfiguration.verifiedOn]."

---

## Optionale Felder (konfigurierbar in Einstellungen)

| Feld | Default | Zweck |
|------|---------|-------|
| Name des Arbeitgebers | Leer | Für Nutzer mit mehreren Arbeitgebern |
| Steuer-ID des Nutzers | Leer | Manche Steuerberater wünschen das |
| Notizen-Spalte anzeigen | AN | Für Monika: sie nutzt keine Notizen, Spalte soll nicht verwirren |
| Monatliche Zwischensummen | AN | Hilft Steuerberatern bei der Prüfung |

---

## Export-UX — Der Moment der Conversion (Paywall-Gestaltung)

Das ist der **wichtigste Monetarisierungsmoment** der App. Der Nutzer tippt zum ersten Mal auf „Exportieren" — und trifft die Kaufentscheidung.

### Paywall-Screen beim ersten Export-Versuch

**Inhalt:**
- Vorschau des PDFs: als unscharf geblurrte Darstellung (Thumbnail mit Overlay)
- Kurze Wertargumentation: „Einmalig 2,99 € — alle Exporte, für immer."
- **Reframing des Preises** (muss sichtbar sein): „Du sparst bis zu 1.260 € im Jahr. Der Nachweis kostet 2,99 €."
- Kaufbutton: „Jetzt freischalten" (prominent)
- „Vielleicht später" (sichtbar, kein Dark Pattern)

**Nach dem Kauf:** Sofortige PDF-Generierung ohne weiteren Klick. Share Sheet erscheint automatisch.

### Share Sheet — direkt nach PDF-Generierung

Nach dem Generieren des PDFs wird **sofort** der iOS Share Sheet geöffnet. Das PDF wird nicht wortlos im Files-App abgelegt. Monika würde es nie finden.

Empfohlene Share-Optionen (durch iOS automatisch angeboten):
- Mail (die häufigste Wahl für Steuerberater-Übermittlung)
- AirDrop
- Dateien (als Fallback)
- WhatsApp / Messenger (falls installiert)

---

## CSV-Export (ergänzend, ebenfalls Premium)

Format: UTF-8 mit BOM (für Excel-Kompatibilität in der DACH-Region zwingend)  
Trennzeichen: Semikolon (nicht Komma — deutsches Excel-Standard)  
Dezimaltrennzeichen: Komma (nicht Punkt)

```csv
Datum;Wochentag;Homeoffice;Betrag (€);Notiz
06.01.2025;Montag;Ja;6,00;
07.01.2025;Dienstag;Ja;6,00;
08.01.2025;Mittwoch;Nein;;
```

Header-Zeile immer in Deutsch, auch wenn das Gerät auf Englisch eingestellt ist (die Datei geht an deutsche Steuerberater).

---

## Jahresauswahl im Export

Der Nutzer kann beim Export das Jahr wählen:
- Aktuelles Jahr (default)
- Vergangene Jahre (aus SwiftData)

Wenn kein Jahr auswählbar ist (nur aktuelles Jahr implementiert in v1.0): Klar kommunizieren. Keine stille Beschränkung.

---

## Fehlerbehandlung

| Situation | Verhalten |
|-----------|-----------|
| Keine Homeoffice-Tage eingetragen | Export-Button deaktiviert + Hinweis: „Noch keine Tage eingetragen." |
| 0 Tage im gewählten Jahr | Export möglich, aber Hinweis: „Für 2025 sind keine Homeoffice-Tage eingetragen." |
| PDF-Generierung schlägt fehl | Fehler-Alert mit klarem Text: „PDF konnte nicht erstellt werden. Bitte versuche es erneut." (kein technischer Stack Trace) |
| Nutzername nicht eingetragen | PDF wird generiert, Name-Feld zeigt „[Name nicht angegeben]" — kein Abbruch |

---

## Acceptance Criteria

PDF-Export ist abgenommen wenn:

- [ ] PDF enthält tagesgenaue Einzelauflistung (jeder Homeoffice-Tag als eigene Zeile)
- [ ] Header zeigt: Name, Steuerjahr, Erstellungsdatum, Beschäftigungsstatus, Rechtsgrundlage
- [ ] Zusammenfassungsblock zeigt: Gesamttage, €/Tag, Gesamtbetrag, Maximum — alle Werte aus `LegalConfiguration`
- [ ] Monatliche Zwischensummen sind vorhanden
- [ ] Abzugsart korrekt nach Beschäftigungsstatus (Werbungskosten / Betriebsausgaben)
- [ ] Footer auf jeder Seite, Haftungshinweis auf letzter Seite
- [ ] Share Sheet erscheint sofort nach Generierung (kein manuelles Suchen im Files-App)
- [ ] CSV: UTF-8 mit BOM, Semikolon-Trennzeichen, deutsche Dezimalzahlen
- [ ] Paywall-Screen: Preis-Reframing sichtbar, kein Dark Pattern
- [ ] Fehlerfall „keine Tage eingetragen": Button deaktiviert, verständlicher Hinweis
- [ ] Jahresauswahl: Mindestens aktuelles Jahr wählbar, vergangene Jahre in v1.1

---

*Kanonischer Pfad: `Docs/PDF-EXPORT-SPEC.md` | Verknüpft mit: RECHTSLAGE.md, ONBOARDING-SPEC.md, UX-Audit-UserUsecases.md*

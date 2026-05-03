# RECHTSLAGE.md — Steuerrechtliche Grundlage des Homeoffice-Trackers

> **⚠️ Oberste Priorität:** Diese Datei ist die **einzige kanonische Rechtsquelle** für alle steuerrechtlichen Zahlen und Regeln in der App. Kein Wert darf im Code, in App-Store-Texten oder in der UI hardcoded sein, ohne auf diese Datei zurückzuführen zu sein. Jede Jahresänderung beginnt hier.

---

## 1. Gesetzliche Grundlage

**Rechtsgrundlage:** § 4 Abs. 5 Satz 1 Nr. 6c EStG (Betriebsausgaben, Selbstständige) sowie § 9 Abs. 5 Satz 1 EStG i.V.m. § 4 Abs. 5 Satz 1 Nr. 6c EStG (Werbungskosten, Arbeitnehmer)

**Einführung:** Erstmals als temporäre Corona-Maßnahme für VZ 2020/2021. Dauerhaft ins EStG überführt durch das **Jahressteuergesetz 2022** (JStG 2022, BGBl. I 2022 S. 2294, verkündet 16.12.2022). Gilt seitdem unbefristet und mit verbesserten Konditionen ab VZ 2023.

**Zuständige Behörde:** Bundesministerium der Finanzen (BMF), www.bundesfinanzministerium.de

---

## 2. Jährliche Werte — Single Source of Truth

Diese Tabelle ist der Ursprung aller Zahlen, die in der App erscheinen. **`LegalConfiguration.swift` leitet alle Werte ausschließlich von hier ab.**

| Veranlagungszeitraum | €/Tag | Max. Tage | Max. Betrag | Status           | Zuletzt geprüft |
|----------------------|-------|-----------|-------------|------------------|-----------------|
| 2020                 | 5,00 € | 120      | 600,00 €    | ✅ Abgeschlossen | Jan 2025        |
| 2021                 | 5,00 € | 120      | 600,00 €    | ✅ Abgeschlossen | Jan 2025        |
| 2022                 | 5,00 € | 120      | 600,00 €    | ✅ Abgeschlossen | Jan 2025        |
| 2023                 | 6,00 € | 210      | 1.260,00 €  | ✅ Abgeschlossen | Jan 2025        |
| 2024                 | 6,00 € | 210      | 1.260,00 €  | ✅ Abgeschlossen | Jan 2025        |
| 2025                 | 6,00 € | 210      | 1.260,00 €  | ✅ Bestätigt     | Apr 2026        |
| 2026                 | 6,00 € | 210      | 1.260,00 €  | ✅ Bestätigt     | Mai 2026        |

> **Hinweis:** Werte für 2026 durch wöchentliche Steuerrechts-Prüfung (KW 18, 03.05.2026) bestätigt — keine Änderung der Homeoffice-Pauschale. Nächste Pflichtbestätigung: Januar 2027.

---

## 3. Wer hat Anspruch? (Eligibility)

### Anspruchsberechtigt ✅
- **Arbeitnehmer** (§ 9 EStG) mit Homeoffice-Tagen — Abzug als Werbungskosten
- **Selbstständige und Freiberufler** (§ 4 EStG) — Abzug als Betriebsausgaben
- **Beamte** mit Homeoffice-Tagen
- Personen in **mehreren Arbeitsverhältnissen**: je Arbeitsverhältnis nutzbar, aber Gesamtlimit 210 Tage/Jahr gilt pro Person, nicht pro Arbeitgeber

### Nicht anspruchsberechtigt / Einschränkungen ❌
- Tage, an denen **auch das Büro/der reguläre Arbeitsplatz genutzt wurde**, können je nach Auslegung nicht zählen — die App loggt Nutzer-Intention, nicht automatisch
- Tage mit **Dienstreise** (kein Büro, aber auch kein Homeoffice): zählen nicht
- Tage mit **Urlaub oder Krankenstand**: zählen nicht
- **Nicht kombinierbar** mit Arbeitszimmer-Abzug für dieselben Tage: Wer ein steuerlich anerkanntes häusliches Arbeitszimmer hat (Mittelpunkt der Tätigkeit), wählt zwischen Arbeitszimmer-Pauschale (max. 1.260 € pauschal ODER tatsächliche Kosten) und Homeoffice-Pauschale (6 €/Tag). Kein Doppelabzug.

### Wichtige Nuance für Selbstständige
Die Homeoffice-Pauschale ist **auch für Selbstständige nutzbar** — entgegen einem verbreiteten Missverständnis. Sie ist besonders attraktiv wenn kein separates Arbeitszimmer vorhanden ist oder dessen steuerliche Anerkennung nicht möglich ist. Die App ist also für Selbstständige relevant, die **kein anerkanntes Arbeitszimmer** haben.

---

## 4. Was zählt als Homeoffice-Tag?

Seit VZ 2023 (JStG 2022) gilt: Ein Tag zählt, wenn der Arbeitnehmer oder Selbstständige **die Tätigkeit ausschließlich in der häuslichen Wohnung** ausübt. Es genügt, wenn der überwiegende Teil der Tagesarbeit von zuhause erledigt wird.

**Zählt:** Vollständiger Arbeitstag von zuhause, auch mit kurzen Unterbrechungen (Einkauf, Spaziergang)  
**Zählt nicht:** Tag mit Bürobesuch, auch nur stundenweise  
**Strittig / Nutzerpflicht:** Gemischte Tage (morgens Büro, nachmittags Homeoffice) — der Nutzer ist selbst verantwortlich für korrekte Eintragung  
**App-Hinweis:** Die App protokolliert die Angaben des Nutzers. Die steuerliche Richtigkeit liegt beim Nutzer und ggf. beim Steuerberater.

---

## 5. Haftungsausschluss — Pflichttext in der App

Folgender Text (oder sinngemäß) muss in der App sichtbar sein — empfohlen im Onboarding und im Export-Footer:

> *„Diese App dient der persönlichen Erfassung und Berechnung. Sie ersetzt keine Steuerberatung. Die steuerliche Anerkennung der eingetragenen Tage obliegt dem Nutzer und ggf. einem Steuerberater. Gesetzliche Werte werden bei Änderungen durch App-Updates angepasst."*

**Verpflichtende Platzierungen:**
- [ ] Onboarding, Screen 1 oder 2 (kurze Version, 1 Satz)
- [ ] Einstellungen / Über die App (vollständige Version)
- [ ] PDF-Export Footer (kompakte Version)

---

## 6. Swift-Implementierung — LegalConfiguration.swift

Der folgende Code ist der **einzige Ort im gesamten Xcode-Projekt**, an dem Homeoffice-Pauschale-Werte definiert werden. Alle Views, Export-Funktionen und Berechnungen greifen ausschließlich über `LegalConfiguration.config(for:)` auf Werte zu. Keine Zahl wie `6.0`, `210` oder `1260` darf anderswo hartcodiert sein.

Für die Entfernungspauschale gilt `CommuterConstants` in `Constants.swift` als Single Source of Truth — siehe Abschnitt 8.

```swift
// LegalConfiguration.swift
// ⚠️ SINGLE SOURCE OF TRUTH für Homeoffice-Pauschale-Werte
// Bei Gesetzesänderungen: NUR DIESE DATEI + Docs/RECHTSLAGE.md bearbeiten.
// Danach App Store-Texte und alle In-App-Hinweistexte prüfen.
// Update-Pflicht: Jedes Jahr bis 31. Januar — siehe RECHTSLAGE.md für Checkliste.
```

---

## 7. Jährliches Update-Protokoll

**Termin:** Jedes Jahr bis **31. Januar** — vor Beginn der Hauptsteuersaison.

### Checkliste für den Jahreswechsel

```
RECHTSLAGE-Update [Jahr XXXX]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ 1. BMF-Website prüfen: bundesfinanzministerium.de → Steuern → Einkommensteuer
      Suchbegriff: "Homeoffice-Pauschale [XXXX]" / "Jahressteuergesetz [XXXX]"

□ 2. Änderungen im JStG / Steuerfortentwicklungsgesetz prüfen:
      - Hat sich der Tagessatz geändert? (aktuell: 6,00 €)
      - Hat sich die maximale Tageszahl geändert? (aktuell: 210)
      - Neue Einschränkungen oder Erweiterungen des Anspruchs?
      - Hat sich die Entfernungspauschale geändert? (aktuell: 0,38 €/km Flat Rate ab 2026)

□ 3. Docs/RECHTSLAGE.md aktualisieren:
      - Tabelle Abschnitt 2: neues Jahr eintragen, Status setzen
      - "Zuletzt geprüft" auf aktuellen Monat setzen
      - Entfernungspauschale-Tabelle (Abschnitt 8) prüfen

□ 4. LegalConfiguration.swift aktualisieren:
      - Neuen YearConfig-Eintrag hinzufügen
      - verifiedOn auf aktuellen Monat setzen
      - Compile + Unit Test ausführen

□ 5. Constants.swift (CommuterConstants) prüfen:
      - Flat Rate 2026 weiterhin korrekt?
      - rateFrom21km() für neue Jahre korrekt?

□ 6. App Store-Texte prüfen:
      - Titel und Beschreibung: korrekte Jahresangabe, korrekte Beträge
      - Screenshots: Jahreszahl in der UI korrekt?
      - Keywords aktuell?

□ 7. In-App-Texte prüfen:
      - Onboarding Screen 1: Zahlen korrekt?
      - SettingsView Footer (Pendlerpauschale): Raten korrekt?
      - Haftungsausschluss aktuell?
      - Info-Tooltips: keine veralteten Zahlen?

□ 8. App Update veröffentlichen (vor dem 15. Februar)

□ 9. Erinnerung für nächstes Jahr setzen (1. Januar)
```

---

## 8. Entfernungspauschale — Rechtsgrundlage & Werte

**Rechtsgrundlage:** § 9 Abs. 1 Satz 3 Nr. 4 EStG (Arbeitnehmer) / § 4 Abs. 5a EStG (Selbstständige)

| Veranlagungszeitraum | km 1–20       | ab km 21      | Regelung |
|----------------------|---------------|---------------|----------|
| bis 2020             | 0,30 €/km     | 0,30 €/km     | Einheitssatz |
| 2021                 | 0,30 €/km     | 0,35 €/km     | Gestaffelt |
| 2022–2025            | 0,30 €/km     | 0,38 €/km     | Steuerentlastungsgesetz 2022, BGBl. I S. 749 |
| **ab 2026**          | **0,38 €/km** | **0,38 €/km** | **Flat Rate — Steueränderungsgesetz 2025, BGBl. I Nr. 363/2025** |

**Änderung ab 2026:** Das Steueränderungsgesetz 2025 schafft die Staffelung ab. Ab dem 1. Januar 2026 gilt einheitlich **0,38 €/km ab dem ersten Kilometer**. Verabschiedet 04.12.2025, Bundesrat 19.12.2025, verkündet 23.12.2025.

**Jahreshöchstbetrag:** 4.500 € — gilt für ÖPNV und Fahrrad/Fuß. PKW/Motorrad: kein Höchstbetrag (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG). Unverändert.

**Implementierung:** `CommuterConstants` in `HomeofficeTracker/Core/Constants.swift` — Single Source of Truth für alle Entfernungspauschale-Werte. Die Funktion `isFlatRate(year:)` steuert das jahresabhängige Verhalten.

---

## 9. Quellen & Referenzen

- **Gesetzestext Homeoffice:** https://www.gesetze-im-internet.de/estg/__4.html (§ 4 Abs. 5 Nr. 6c)
- **Gesetzestext Entfernungspauschale:** https://www.gesetze-im-internet.de/estg/__9.html (§ 9 Abs. 1 Nr. 4)
- **BMF-Schreiben Homeoffice (15.08.2023):** IV C 6 – S 2145/19/10006:026
- **JStG 2022:** BGBl. I 2022 Nr. 51, S. 2294, verkündet 16.12.2022
- **Steuerentlastungsgesetz 2022:** BGBl. I 2022 S. 749
- **Steueränderungsgesetz 2025:** BGBl. I Nr. 363/2025, verkündet 23.12.2025
- **Lohnsteuer kompakt:** https://www.lohnsteuer-kompakt.de/homeoffice-pauschale
- **Steuerberater-Kammer:** https://www.bstbk.de (bei Interpretationsfragen)

---

## 10. Änderungshistorie

| Datum    | Änderung                                                                 | Autor       |
|----------|--------------------------------------------------------------------------|-------------|
| Apr 2026 | Initiale Erstellung, alle Werte bis 2026 erfasst                        | Claude/Paul |
| Mai 2026 | 2026 bestätigt (KW 18): Homeoffice-Pauschale unverändert. Entfernungspauschale: Flat Rate 0,38 €/km ab 2026 (Steueränderungsgesetz 2025) — Code in Constants.swift, PDFExportService.swift, SettingsView.swift aktualisiert. Abschnitt 8 hinzugefügt. In Docs/ verschoben, Jahres-Checkliste um Entfernungspauschale erweitert. | Claude/Paul |

---

*Kanonischer Pfad: `Docs/RECHTSLAGE.md` im Xcode-Projektordner. Nächste Pflichtprüfung: **Januar 2027**.*

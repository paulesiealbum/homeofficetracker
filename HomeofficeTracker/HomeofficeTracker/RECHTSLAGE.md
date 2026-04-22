# RECHTSLAGE — Steuerliche Kernfunktionen

> **Pflichtdokument für Entwicklung und Review.**  
> Nur Gesetzesgrundlagen — keine Interpretation, keine Annahmen, keine Vereinfachungen.  
> Jede Änderung an Berechnungslogik muss gegen dieses Dokument geprüft werden.

---

## 1. Homeoffice-Pauschale

### § 4 Abs. 5 Satz 1 Nr. 6c EStG (ab 2023)

**Wortlaut (amtlich):**  
„Aufwendungen für ein häusliches Arbeitszimmer sowie die Kosten der Ausstattung. Dies gilt nicht, wenn für die betriebliche oder berufliche Tätigkeit kein anderer Arbeitsplatz zur Verfügung steht. [...] Aufwendungen für jeden Kalendertag, an dem die Tätigkeit überwiegend in der häuslichen Wohnung ausgeübt wird und keine außerhalb der häuslichen Wohnung belegene erste Tätigkeitsstätte aufgesucht wird, in Höhe von 6 Euro, höchstens 1.260 Euro im Wirtschaftsjahr."

**Maßgebliche Werte ab 2023:**
| Parameter | Wert | Quelle |
|---|---|---|
| Tagespauschale | **6,00 EUR** | § 4 Abs. 5 Satz 1 Nr. 6c EStG |
| Maximale Tage/Jahr | **210** | § 4 Abs. 5 Satz 1 Nr. 6c EStG |
| Jahreshöchstbetrag | **1.260,00 EUR** | § 4 Abs. 5 Satz 1 Nr. 6c EStG |

---

### § 4 Abs. 5 Satz 1 Nr. 6b EStG (2020–2022, COVID-Regelung)

**Maßgebliche Werte 2020–2022:**
| Parameter | Wert | Quelle |
|---|---|---|
| Tagespauschale | **5,00 EUR** | § 4 Abs. 5 Satz 1 Nr. 6b EStG |
| Maximale Tage/Jahr | **120** | § 4 Abs. 5 Satz 1 Nr. 6b EStG |
| Jahreshöchstbetrag | **600,00 EUR** | § 4 Abs. 5 Satz 1 Nr. 6b EStG |

**Vor 2020:** Keine Homeoffice-Pauschale.

---

## 2. Entfernungspauschale (Pendlerpauschale)

### § 9 Abs. 1 Satz 3 Nr. 4 EStG

**Wortlaut (amtlich, Auszug):**  
„Aufwendungen des Arbeitnehmers für Wege zwischen Wohnung und erster Tätigkeitsstätte im Sinne des Absatzes 4; zur Bestimmung der Entfernung ist die kürzeste Straßenverbindung zwischen Wohnung und erster Tätigkeitsstätte maßgebend; [...] für jeden Arbeitstag, an dem der Arbeitnehmer die erste Tätigkeitsstätte aufsucht eine Entfernungspauschale für jeden vollen Kilometer der Entfernung von 0,30 Euro, höchstens jedoch 4.500 Euro im Kalenderjahr; ein höherer Betrag als 4.500 Euro ist anzusetzen, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung überlassenen Kraftwagen benutzt."

#### Jahresabhängige Kilometersätze

| Jahr | 1–20 km | ab 21 km | Rechtsgrundlage |
|---|---|---|---|
| bis 2020 | 0,30 EUR/km | 0,30 EUR/km | § 9 Abs. 1 Satz 3 Nr. 4 EStG |
| 2021 | 0,30 EUR/km | **0,35 EUR/km** | Gesetz zur Umsetzung des Klimaschutzprogramms 2030 (BGBl. I 2019 S. 2886) |
| ab 2022 | 0,30 EUR/km | **0,38 EUR/km** | Steuerentlastungsgesetz 2022 (BGBl. I 2022 S. 749) |

**Berechnung pro Bürotag (einfache Strecke — nicht Hin- und Rückfahrt):**
```
Entfernung ≤ 20 km:  Entfernung × 0,30 EUR
Entfernung > 20 km:  20 × 0,30 EUR + (Entfernung − 20) × Satz_ab_21km(Jahr)
```

---

### § 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG — Jahreshöchstbetrag

**Wortlaut (amtlich):**  
„Ein höherer Betrag als 4.500 Euro ist anzusetzen, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung überlassenen Kraftwagen benutzt."

| Verkehrsmittel | Jahreshöchstbetrag | Rechtsgrundlage |
|---|---|---|
| **PKW / Motorrad** | **kein Cap** — voller Betrag absetzbar | § 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG |
| ÖPNV (Bus, Bahn, U-Bahn) | **4.500,00 EUR** je Dienstverhältnis, alternativ tatsächliche Ticketkosten (§ 9 Abs. 1 Satz 3 Nr. 4a) | § 9 Abs. 1 Satz 3 Nr. 4 EStG |
| Fahrrad / zu Fuß | **4.500,00 EUR** je Dienstverhältnis | § 9 Abs. 1 Satz 3 Nr. 4 EStG |

> ⚠️ **KRITISCH — Korrekte Auslegung:**  
> Das Gesetz sagt: „**ein höherer Betrag als 4.500 Euro IST ANZUSETZEN**, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung überlassenen **Kraftwagen** benutzt."  
> → PKW/Motorrad: KEIN Jahreshöchstbetrag — der volle Pauschalbetrag ist anzusetzen.  
> → ÖPNV, Fahrrad, zu Fuß: Jahreshöchstbetrag 4.500 € gilt.

> **App-Verhalten:** Die App fragt das Verkehrsmittel je Arbeitsstätte ab (`TransportMode` enum).  
> Bei `.car` (capExempt = true): kein Cap — `effectiveTotalDeduction` gibt ungekürzten Betrag zurück.  
> Bei `.transit` / `.bicycle` (capExempt = false): Cap 4.500 € angewendet.

---

## 3. Gegenseitiger Ausschluss (Mutual Exclusion)

**Gesetzliche Grundlage: § 9 Abs. 1 Satz 3 Nr. 4 EStG i.V.m. § 4 Abs. 5 Satz 1 Nr. 6c EStG**

Ein Steuertag kann **nur einer** der beiden Pauschalen zugeordnet werden:

| Tag-Typ | Homeoffice-Pauschale | Entfernungspauschale |
|---|---|---|
| Homeoffice-Tag | ✅ | ❌ |
| Bürotag (Fahrt zur Tätigkeitsstätte) | ❌ | ✅ |

Dies ist keine Interpretation — es ergibt sich zwingend aus dem Gesetzeswortlaut: Die Homeoffice-Pauschale setzt voraus, dass „keine außerhalb der häuslichen Wohnung belegene erste Tätigkeitsstätte aufgesucht wird" (Nr. 6c). Die Entfernungspauschale setzt genau das Aufsuchen voraus (Nr. 4).

---

## 4. Arbeitnehmer-Pauschbetrag

### § 9a Satz 1 Nr. 1 Buchst. a EStG

| Jahr | Pauschbetrag | Rechtsquelle |
|---|---|---|
| ab 2023 | **1.230,00 EUR** | JStG 2022, BGBl. I 2022 S. 2294 |
| 2022 | 1.200,00 EUR | Steuerentlastungsgesetz 2022, BGBl. I 2022 S. 749 |
| bis 2021 | 1.000,00 EUR | § 9a Satz 1 Nr. 1 Buchst. a EStG (Grundbetrag) |

> **Hinweis für die App:** Der Pauschbetrag mindert die steuerlichen Werbungskosten pauschal. Er ist **nicht** direkt in die Berechnung der Homeoffice- oder Pendlerpauschale einzubeziehen — er wirkt auf Ebene der Gesamtwerbungskosten. Die App berechnet nur die Pauschalen, nicht die Gesamtsteuerersparnis nach Pauschbetrag. Dies muss in Disclaimern klar kommuniziert werden.

---

## 5. Selbstständige

### § 4 Abs. 5a EStG

Selbstständige (Gewerbetreibende, Freiberufler) können die Entfernungspauschale **nicht** unbegrenzt als Betriebsausgabe absetzen. § 4 Abs. 5a EStG begrenzt den Abzug auf den Betrag, der als Entfernungspauschale nach § 9 Abs. 1 Satz 3 Nr. 4 und 4a EStG anzusetzen wäre.

> **App-Verhalten:** Die Berechnung ist für Arbeitnehmer und Selbstständige identisch, da § 4 Abs. 5a EStG dieselben Werte (Sätze, Cap) wie § 9 Abs. 1 Satz 3 Nr. 4 EStG verwendet.

---

## 6. Mehrere Dienstverhältnisse

### § 9 Abs. 4 Satz 5 EStG

**Wortlaut (amtlich, Auszug):**  
„Je Dienstverhältnis kann nur eine erste Tätigkeitsstätte bestimmt werden."

**Konsequenz:** Der Jahreshöchstbetrag von 4.500 EUR gilt **je Dienstverhältnis** — nicht als Gesamtlimit für alle Arbeitsstätten zusammen. Ein Arbeitnehmer mit zwei gleichzeitigen Arbeitsverhältnissen kann für jedes Dienstverhältnis bis zu 4.500 EUR Pendlerpauschale absetzen.

---

## 7. Implementierungs-Checkliste (Pflicht)

Diese Punkte müssen bei jeder Änderung der Berechnungslogik geprüft werden:

- [ ] Tagespauschale wird aus `LegalConfiguration.config(for: year).dailyRate` gelesen — **nie hardcoded**
- [ ] Maximaltage werden aus `LegalConfiguration.config(for: year).maxDays` gelesen — **nie hardcoded**
- [ ] Entfernungspauschale Satz ab km 21 ist **jahresabhängig** via `CommuterConstants.rateFrom21km(year:)`
- [ ] Jahreshöchstbetrag 4.500 EUR wird **je Dienstverhältnis** angewendet, nicht global
- [ ] PKW/Motorrad: `transportMode.capExempt == true` → **kein Cap** (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2)
- [ ] ÖPNV/Fahrrad/Fuß: `capExempt == false` → Cap 4.500 € gilt
- [ ] Homeoffice-Tage und Bürotage werden für dieselbe Periode **nie addiert**
- [ ] PDF und CSV weisen den gegenseitigen Ausschluss explizit aus
- [ ] PDF zeigt Verkehrsmittel je Arbeitsstätte und korrektes Cap-Verhalten
- [ ] Arbeitnehmer-Pauschbetrag erscheint **nur als Hinweis**, wird nicht in Pauschalen-Summe eingerechnet
- [ ] Rechtsgrundlagen im Export immer mit „Satz 1" in Nr. 6b/6c (korrekte Zitierung)

---

*Letzte Prüfung der Rechtslage: April 2026. Quelle: EStG in der Fassung des Steuerentlastungsgesetzes 2022 (BGBl. I 2022 S. 749) und des JStG 2022 (BGBl. I 2022 S. 2294).*

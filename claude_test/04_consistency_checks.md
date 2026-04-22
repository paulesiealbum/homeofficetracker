# 04 — Konsistenzprüfung

Systematische Checks: Verhält sich die App überall gleich und erwartungskonform?

---

## K-01: Farbkodierung

### Regel
| Status | Farbe | Icon |
|---|---|---|
| Homeoffice | Grün | house.fill |
| Büro (Arbeitstag, kein HO) | Grau | building.2 |
| Urlaub | Orange | — |
| Krank | Rot | — |
| Feiertag | Lila | star |
| Kein Arbeitstag (WE) | Leer/weiß | — |

### Checks
- [ ] **HomeView Toggle** zeigt grün/grau korrekt?
- [ ] **Kalender-Zellen** verwenden dieselben Farben?
- [ ] **Day Detail Sheet** zeigt aktuellen Status in korrekter Farbe?
- [ ] **Wochentags-Header** (Mo–So) — Nicht-Arbeitstage erkennbar abgesetzt?
- [ ] **Heute-Zelle** im Kalender hat visuellen Distinction (z.B. Rahmen)?

### Bekannte Inkonsistenz
Die Kalender-Zellen verwenden `opacity(0.25)` für HO-Grün — aber der Toggle-Button wahrscheinlich volle Sättigung. Konsistente Opazität ist wichtig für Lese-Klarheit.

---

## K-02: Counter-Konsistenz

### Regel: Counter = Anzahl HO-Tage im aktuellen Steuerjahr

### Checks
- [ ] Counter nach Toggle-Tap sofort aktualisiert (kein Delay)?
- [ ] Counter nach Detail-Sheet-Save sofort aktualisiert?
- [ ] Counter nach Monats-Navigation korrekt (zählt Gesamtjahr, nicht Monat)?
- [ ] Counter zeigt korrekte Jahres-Grenze (1. Jan – 31. Dez)?
- [ ] Counter ist 0 bei frischer Installation?
- [ ] Counter deckt sich mit manuell gezählten grünen Zellen?

### Grenzfall-Checks
- [ ] Urlaubs-Tage gehen NICHT in Counter → korrekt?
- [ ] Feiertags-Tage gehen NICHT in Counter → korrekt?
- [ ] Krank-Tage gehen NICHT in Counter → korrekt?
- [ ] Zukünftige geplante Tage: gehen sie IN Counter? (Verhalten undokumentiert)

---

## K-03: Datumslogik

### Regel: Alle Daten normalisiert auf Mitternacht (UTC)

### Checks
- [ ] Toggle für "Heute" speichert korrektes Datum (nicht gestern wegen Zeitzonen)?
- [ ] App bei Mitternachts-Wechsel: Aktualisiert "Heute" ohne App-Neustart?
- [ ] Kalendar-Navigation zeigt korrekten Monat nach Jahreswechsel?
- [ ] 29. Februar in Schaltjahr korrekt behandelt?
- [ ] Wochentags-Zuordnung korrekt? (Mo = 2 in Swift, aber Kalender zeigt Mo als erste Spalte)

### Bekannte Implementierungs-Details
```swift
// Normalisierung auf Mitternacht
var normalized: Date {
    Calendar.current.startOfDay(for: date)
}
```
→ Dieser Pattern muss konsistent in ALLEN Queries verwendet werden.

---

## K-04: Settings ↔ Kalender ↔ Toggle Konsistenz

### Regel: Konfigurierte Nicht-Arbeitstage sind überall inaktiv

**Szenario:** Nutzer konfiguriert Mo–Do als Arbeitstage (kein Freitag)

### Checks
- [ ] Freitag im Kalender: Visuell als Nicht-Arbeitstag erkennbar?
- [ ] Freitag antippen → kein HO-Toggle möglich?
- [ ] HomeView an einem Freitag: Toggle deaktiviert oder ausgeblendet?
- [ ] Ändert Nutzer Settings nachträglich (Freitag hinzufügen): Vergangene Freitage bleiben unberührt?
- [ ] Standard-HO-Einstellungen: Automatisch deaktiviert wenn Arbeitstag entfernt wird?

---

## K-05: Planning Mode Ein/Aus Konsistenz

### Checks
- [ ] Planning Mode Icon deutlich sichtbar als "aktiv" markiert (Farbe/Fill)?
- [ ] Planning Mode-Status nach Monatswechsel: Bleibt aktiv?
- [ ] Planning Mode-Status nach App-Neustart: Zurückgesetzt (kein persistenter Zustand)?
- [ ] Im Planning Mode: Vergangene Tage weiterhin bearbeitbar?
- [ ] Ohne Planning Mode: Zukunftstage vollständig blockiert (kein Sheet)?

---

## K-06: Detail-Sheet Konsistenz

### Checks
- [ ] Sheet für vergangene HO-Tage: Toggle EIN
- [ ] Sheet für vergangene Büro-Tage: Toggle AUS
- [ ] Sheet für heutigen Tag: Zeigt aktuellen Status
- [ ] Sheet für Zukunftstage (nur Planning Mode): Alle Felder aktiv
- [ ] Sheet für Wochenend-Tage (nicht Arbeitstag): HO-Toggle deaktiviert?
- [ ] Notiz-Feld: Tastatur klappt ein → Sheet scrollt mit?
- [ ] Save-Button: Deaktiviert wenn keine Änderung? Oder immer aktiv?
- [ ] Cancel-Button: Verwirft Änderungen ohne Bestätigung?

---

## K-07: Paywall-Konsistenz

### Checks
- [ ] Export-Button in Settings zeigt Schloss-Icon wenn nicht Premium
- [ ] Nach Kauf: Schloss-Icon verschwindet sofort?
- [ ] Nach App-Neustart: Premium-Status bleibt erhalten?
- [ ] "Kauf wiederherstellen": Funktioniert nach Geräte-Wechsel?
- [ ] Paywall zeigt Features, die tatsächlich implementiert sind (Widget!)?

### Kritisch: Widget-Versprechen
Der Paywall bewirbt "Widget" — aber das Widget ist **nicht implementiert**.  
→ Apple könnte App ablehnen (Irreführung)  
→ Nutzer könnten eine Rückerstattung beantragen

**Empfehlung:** Widget aus Paywall entfernen bis implementiert, oder als "Demnächst" markieren.

---

## K-08: Navigation & Gesten Konsistenz

### Checks
- [ ] Swipe-zurück (NavigationView): Funktioniert überall?
- [ ] Monat zurück/vor: Buttons? Swipe-Geste?
- [ ] Kalender scroll: Vertikal durch Monate oder nur Buttons?
- [ ] Pull-to-Refresh: Vorhanden? (SwiftData — sollte nicht nötig sein)
- [ ] Tab-Bar: Wie viele Tabs? HomeView + Settings? Kein Calendar-Tab?

### Bekannte Inkonsistenz
Code enthält `CalendarView.swift` aber diese View ist **nicht im TabView** eingebunden.  
→ Dead code oder unfertige Navigation?

---

## K-09: Fehlerzustände

### Checks
- [ ] StoreKit nicht verfügbar (Flugmodus): Paywall zeigt sinnvolle Fehlermeldung?
- [ ] Kauf fehlgeschlagen: Benutzer informiert?
- [ ] SwiftData Fehler beim Speichern: Benutzer informiert?
- [ ] App im Hintergrund, Datum wechselt: "Heute"-Toggle aktuell?

---

## K-10: Barrierefreiheit

### Checks
- [ ] Dynamic Type: Schrift vergrößert → Layout bricht nicht?
- [ ] VoiceOver: Toggle hat sinnvolles Label ("Homeoffice aktiv / inaktiv")?
- [ ] Kalender-Zellen: VoiceOver nennt Datum + Status?
- [ ] Farbkodierung allein reicht nicht: Icons als zweiter Kanal?
  - **BUG-RISIKO:** Farbenblinde Nutzer können grün/grau evtl. nicht unterscheiden

---

## Konsistenz-Scorecard

| Bereich | Bewertung | Hauptrisiko |
|---|---|---|
| Farbkodierung | 🟡 Mittel | Opazität-Inkonsistenz |
| Counter-Logik | 🟡 Mittel | Zukünftige Tage-Zählung unklar |
| Datumslogik | 🟢 Gut | Normalisierung vorhanden |
| Settings ↔ UI | 🟡 Mittel | Standard-HO-Tage wirken nicht |
| Planning Mode | 🟡 Mittel | Verhalten nicht vollständig spezifiziert |
| Detail-Sheet | 🟢 Gut | Wenige Grenzfälle |
| Paywall | 🔴 Kritisch | Widget nicht implementiert |
| Navigation | 🟡 Mittel | CalendarView dead code |
| Fehlerzustände | 🔴 Kritisch | Kaum implementiert |
| Barrierefreiheit | 🔴 Kritisch | Farbenblind-Problem |

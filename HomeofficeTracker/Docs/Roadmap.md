# Homeoffice-Tracker — App Konzept & Roadmap

Passives Einkommens-Projekt | iOS App (SwiftUI) | Stand: April 2025

---

## 1. Produkt-Vision

Die Homeoffice-Pauschale erlaubt deutschen Arbeitnehmern, 6 € pro Homeoffice-Tag steuerlich abzusetzen – maximal 210 Tage pro Jahr, also bis zu 1.260 € Steuerersparnis. Das Problem: Die meisten Menschen tracken ihre Tage nicht konsequent, weil kein dediziertes, einfaches Tool dafür existiert.

**Core Value Proposition:** *"Ein Tap pro Tag. Export für den Steuerberater. Fertig."*

| | |
|---|---|
| **Zielmarkt** | Arbeitnehmer in D/A/CH mit Homeoffice-Anteil (ca. 30% der Erwerbstätigen, ~12 Mio. Personen) |
| **Problem** | Keine einfache, Deutsche-Steuerrecht-konforme App zum Tracken von Homeoffice-Tagen |
| **Lösung** | Minimale iOS-App: 1 Tap = 1 Tag geloggt, Steuerersparnis-Preview, Export für Steuerberater |
| **Monetarisierung** | Kostenlos + Jahres-Abo 2,99 €/Jahr (Export, Widget, Mehrere Arbeitgeber) |

---

## 2. Use Cases

### UC-01 | Tägliches Tracking

| Attribut | Beschreibung |
|---|---|
| Nutzer | Arbeitnehmer im Homeoffice |
| Auslöser | Nutzer arbeitet von Zuhause und möchte den Tag loggen |
| Ablauf | App öffnen → Großen Toggle antippen → Tag wird als HO-Tag gespeichert |
| Ergebnis | Tag ist grün markiert, Counter +1, Steuerersparnis aktualisiert |
| Happy Path | Unter 3 Sekunden, keine Anmeldung, kein Formular |

### UC-02 | Jahresübersicht & Steuer-Preview

| Attribut | Beschreibung |
|---|---|
| Nutzer | Arbeitnehmer vor der Steuererklärung |
| Auslöser | Nutzer möchte wissen, wie viel er absetzen kann |
| Ablauf | Jahres-Tab öffnen → Kalender-View mit allen HO-Tagen → Preview: X Tage × 6 € = Y € |
| Ergebnis | Sofortige Übersicht über absetzbare Summe |
| Mehrwert | Motiviert zum konsequenten Tracken (Gamification durch Ersparnis-Anzeige) |

### UC-03 | Export für Steuerberater (Premium)

| Attribut | Beschreibung |
|---|---|
| Nutzer | Arbeitnehmer mit Steuerberater oder selbst einreichend |
| Auslöser | Steuererklärung muss eingereicht werden |
| Ablauf | Export-Button → PDF/CSV wird generiert → Teilen via iOS Share Sheet |
| Inhalt | Name, Steuerjahr, Datum-Liste aller HO-Tage, Gesamtsumme in €, Entfernungspauschale |
| Ergebnis | Druckfertiges Dokument für Steuerberater oder Finanzamt |

### UC-04 | Home Screen Widget (Premium)

| Attribut | Beschreibung |
|---|---|
| Nutzer | Vielnutzer, der täglich trackt |
| Auslöser | Nutzer sieht Widget auf Homescreen |
| Ablauf | 1×1 Widget zeigt aktuellen Tages-Status + Tap zum Togglen ohne App öffnen |
| Ergebnis | Maximale Convenience, erhöht tägliche Nutzungsrate |
| Technisch | WidgetKit + App Intent für interaktives Widget (iOS 17+) |

---

## 3. Feature Scope

### MVP (v1.0) – Must-Have

| Feature | Beschreibung | Verfügbarkeit |
|---|---|---|
| Tages-Toggle | Heute HO / Nicht HO | ✅ Free |
| Monatskalender | Übersicht aller Tage im Monat (grün/grau) | ✅ Free |
| Jahres-Counter | "X von 210 Tagen – Ersparnis: Y €" | ✅ Free |
| Notizen pro Tag | Optionale kurze Notiz (z.B. Grund, Projekt) | ✅ Free |
| CSV/PDF Export | Für Steuerberater, mit Steuerjahr-Header + Entfernungspauschale | 🔒 Paid |

### v1.1 – Nice-to-Have

| Feature | Beschreibung | Verfügbarkeit |
|---|---|---|
| Home Screen Widget | 1×1, interaktiv (iOS 17+) | 🔒 Paid |
| Abend-Reminder | Push: 'Hast du heute von zuhause gearbeitet?' | ✅ Free |
| Mehrere Profile | Für Freelancer mit mehreren Arbeitgebern | 🔒 Paid |
| iCloud Sync | Daten über mehrere Geräte synchronisieren | 🔒 Paid |
| Jahres-Wechsel | Archiv vergangener Steuerjahre | ✅ Free |

### Bewusst ausgeschlossen
- GPS/WiFi-basierte automatische Erkennung → Datenschutz-Risiko, zu komplex
- Steuerformular-Integration → regulatorisch zu heikel
- Web-App / Android → Fokus auf iOS-Qualität
- Soziale Features → kein Mehrwert, unnötige Komplexität

---

## 4. Technischer Stack

| Komponente | Technologie | Begründung |
|---|---|---|
| UI Framework | SwiftUI | Deklarativ, modern, schnell entwickelbar |
| Datenpersistenz | SwiftData (@Model) | Native, kein CoreData-Boilerplate |
| Widget | WidgetKit + App Intents | Interaktives iOS 17 Widget |
| Monetarisierung | StoreKit 2 | Jahres-Abo, einfache API |
| Notifications | UNUserNotificationCenter | Lokale Abend-Erinnerung |
| Export PDF | PDFKit | Native, kein 3rd-Party-Framework |
| Sync | CloudKit / iCloud | Aktiv ab v1.0 |

### Datenmodell (SwiftData)

```swift
@Model class WorkDay {
    var date: Date
    var isHomeoffice: Bool
    var note: String?
    var specialType: String?
}
```

Pendler-Daten werden nicht im WorkDay-Model, sondern in `WorkScheduleSettings` als `[WorkplacePeriod]` gespeichert (UserDefaults + JSONEncoder).

---

## 5. Entwicklungs-Roadmap

| Zeitraum | Phase | Aufgaben |
|---|---|---|
| Woche 1 | Foundation | SwiftData Model, Tages-Toggle UI, Kalender-View, Jahres-Counter-Logik |
| Woche 2 | Monetarisierung | StoreKit 2 Paywall, PDF/CSV Export (PDFKit), App-Icon, Screenshots |
| Woche 3 | Polish & Launch | WidgetKit Integration, Push Notifications, TestFlight, App Store Submission |
| Woche 4–5 | Buffer | App Review, Feedback einarbeiten, ASO-Optimierung |
| v1.1 (Monat 2) | Erweiterung | Mehrere Profile, iCloud Sync, verbesserter Export, iPad Layout |

---

## 6. Monetarisierungs-Strategie

### Preismodell: Free + Jahres-Abo

2,99 €/Jahr für alle Premium-Features.

| Szenario | Downloads/Monat | Conversion | Revenue/Monat |
|---|---|---|---|
| Konservativ | 200 | 15% | ~90 € |
| Realistisch | 600 | 20% | ~360 € |
| Stark | 2.000 | 25% | ~1.500 € |

⚡ Steuersaison (Januar–Mai) generiert 3–4× normalen Traffic. Das ist der natürliche Launch-Zeitpunkt.

---

## 7. Go-to-Market

### App Store Optimierung (ASO)
- Keywords: Homeoffice Steuer, Arbeitstage Tracker, Homeoffice Pauschale 2026, Steuererklärung App
- Titel: 'Homeoffice Tracker – Steuer' (max. 30 Zeichen)
- Screenshots auf Deutsch mit konkreten Zahlen (z.B. '210 Tage = 1.260 €')
- Lokalisierung: Deutsch, Österreichisches Deutsch, Schweizer Deutsch

### Launch-Kanäle

| Kanal | Taktik | Ziel |
|---|---|---|
| Reddit | r/Finanzen, r/Steuern, r/de | Organisch, hohe Kaufbereitschaft |
| LinkedIn/XING | Post über HO-Pauschale + App-Link | B2B-Reichweite, Arbeitnehmer |
| Steuerberater-Blogs | Erwähnung / Gastpost | Vertrauen & Long-Tail-SEO |
| ProductHunt | Launch auf Englisch | Internationale Sichtbarkeit |
| App Store Feature | Review Request nach 3. Nutzung | Rating erhöht organische Reichweite |

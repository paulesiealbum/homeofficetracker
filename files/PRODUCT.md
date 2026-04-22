# PRODUCT.md — Homeoffice-Tracker

## Vision

> **"Ein Tap pro Tag. Export für den Steuerberater. Fertig."**

Die Homeoffice-Pauschale erlaubt deutschen Arbeitnehmern, **6 € pro Homeoffice-Tag** steuerlich abzusetzen – maximal 210 Tage pro Jahr, also bis zu **1.260 € Steuerersparnis**. Das Problem: Die meisten Menschen tracken ihre Tage nicht konsequent, weil kein dediziertes, einfaches Tool dafür existiert.

| | |
|---|---|
| **Zielmarkt** | Arbeitnehmer in D/A/CH mit Homeoffice-Anteil (~12 Mio. Personen) |
| **Problem** | Keine einfache, deutsches-Steuerrecht-konforme App zum Tracken von Homeoffice-Tagen |
| **Lösung** | Minimale App: 1 Tap = 1 Tag geloggt, Steuerersparnis-Preview, Export für Steuerberater |
| **Monetarisierung** | Kostenlos + One-Time Unlock für 2,99 € (Export, Widget, Mehrere Profile) |

---

## Use Cases

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

### UC-03 | Export für Steuerberater (Paywall)

| Attribut | Beschreibung |
|---|---|
| Nutzer | Arbeitnehmer mit Steuerberater oder selbst einreichend |
| Auslöser | Steuererklärung muss eingereicht werden |
| Ablauf | Export-Button → PDF/CSV wird generiert → Teilen via Share Sheet |
| Inhalt | Name, Steuerjahr, Datum-Liste aller HO-Tage, Gesamtsumme in € |
| Ergebnis | Druckfertiges Dokument für Steuerberater oder Finanzamt |

### UC-04 | Home Screen Widget (Paywall)

| Attribut | Beschreibung |
|---|---|
| Nutzer | Vielnutzer, der täglich trackt |
| Auslöser | Nutzer sieht Widget auf Homescreen |
| Ablauf | Widget zeigt aktuellen Tages-Status + Tap zum Togglen ohne App öffnen |
| Technisch | Flutter `home_widget` Package + native Widget Extension (iOS) / AppWidget (Android) |

---

## Feature Scope

### MVP (v1.0) — Must-Have

| Feature | Beschreibung | Verfügbarkeit |
|---|---|---|
| Tages-Toggle | Heute HO / Nicht HO | ✅ Free |
| Monatskalender | Übersicht aller Tage im Monat (grün/grau) | ✅ Free |
| Jahres-Counter | "X von 210 Tagen – Ersparnis: Y €" | ✅ Free |
| Notizen pro Tag | Optionale kurze Notiz (z.B. Grund, Projekt) | ✅ Free |
| CSV/PDF Export | Für Steuerberater, mit Steuerjahr-Header | 🔒 Paid |

### v1.1 — Nice-to-Have

| Feature | Beschreibung | Verfügbarkeit |
|---|---|---|
| Home Screen Widget | Interaktiv, iOS + Android | 🔒 Paid |
| Abend-Reminder | Push: "Hast du heute von zuhause gearbeitet?" | ✅ Free |
| Mehrere Profile | Für Freelancer mit mehreren Arbeitgebern | 🔒 Paid |
| Jahres-Wechsel | Archiv vergangener Steuerjahre | ✅ Free |

### Bewusst ausgeschlossen

- GPS/WiFi-basierte automatische Erkennung → Datenschutz-Risiko, zu komplex
- Backend / Cloud-Sync → Unnötige Komplexität für Solo-Entwickler (v1.0)
- Steuerformular-Integration → Regulatorisch zu heikel
- Soziale Features → Kein Mehrwert

---

## Saisonalität

> ⚡ Steuersaison (Januar–Mai) generiert 3–4× normalen Traffic. Das ist der natürliche Launch-Zeitpunkt.

---

## ASO (App Store Optimierung)

- **Keywords:** Homeoffice Steuer, Arbeitstage Tracker, Homeoffice Pauschale, Steuererklärung App
- **Titel:** "Homeoffice Tracker – Steuer" (max. 30 Zeichen)
- **Screenshots:** Auf Deutsch mit konkreten Zahlen (z.B. "210 Tage = 1.260 €")
- **Lokalisierung:** Deutsch, Österreichisches Deutsch, Schweizer Deutsch

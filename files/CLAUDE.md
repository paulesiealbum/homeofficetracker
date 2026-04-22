# CLAUDE.md — Homeoffice-Tracker

> Dieses File wird von Claude Code bei jedem Session-Start automatisch gelesen.
> Alle wichtigen Entscheidungen, Konventionen und Befehle sind hier zusammengefasst.

---

## Projekt-Überblick

**App:** Homeoffice-Tracker
**Plattform:** iOS only (ab iOS 17)
**Zielmarkt:** DACH (Deutschland, Österreich, Schweiz)
**Zweck:** Deutsche Arbeitnehmer beim Tracken ihrer Homeoffice-Tage für die Steuererklärung unterstützen (Homeoffice-Pauschale: 6 €/Tag, max. 210 Tage/Jahr = bis zu 1.260 € Steuerersparnis)

---

## Tech Stack

| Komponente       | Technologie              | Begründung                              |
|------------------|--------------------------|-----------------------------------------|
| UI Framework     | SwiftUI                  | Native iOS, deklarativ, modern          |
| Sprache          | Swift 5.9+               | Typsicher, Xcode-native                 |
| Datenbank        | SwiftData (`@Model`)     | Native, kein CoreData-Boilerplate       |
| IAP / Paywall    | StoreKit 2               | Native iOS, kein 3rd-Party nötig        |
| Widget           | WidgetKit + App Intents  | Interaktives iOS 17 Widget              |
| Notifications    | UNUserNotificationCenter | Lokale Abend-Erinnerung                 |
| Export PDF       | PDFKit                   | Native, kein 3rd-Party-Framework        |
| Sync (v1.1)      | CloudKit / iCloud        | Optional, erst in v1.1                  |

**Kein Backend. Kein Login. Alle Daten lokal (SwiftData).**

---

## Projektstruktur

```
HomeofficeTracker/
├── HomeofficeTrackerApp.swift      # @main, ModelContainer Setup
├── Core/
│   ├── Constants.swift             # TaxConstants, ProductIDs
│   └── Theme.swift                 # Colors, Fonts
├── Data/
│   └── WorkDay.swift               # SwiftData @Model
├── Features/
│   ├── Tracking/
│   │   ├── HomeView.swift          # Tages-Toggle + Counter
│   │   └── CalendarView.swift      # Monatskalender
│   ├── Export/
│   │   └── ExportView.swift        # CSV/PDF Export (Paywall)
│   └── Paywall/
│       └── PaywallView.swift       # StoreKit 2 Paywall
├── Shared/
│   └── Views/                      # Wiederverwendbare UI-Komponenten
└── HomeofficeTrackerWidget/        # WidgetKit Extension Target
    └── HomeofficeWidget.swift
```

---

## Datenmodell

```swift
// Data/WorkDay.swift
import SwiftData
import Foundation

@Model
final class WorkDay {
    @Attribute(.unique) var date: Date   // Immer auf Mitternacht normalisiert
    var isHomeoffice: Bool
    var note: String?

    init(date: Date, isHomeoffice: Bool = false, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isHomeoffice = isHomeoffice
        self.note = note
    }
}
```

> **Invariante:** `date` wird **immer** via `Calendar.current.startOfDay(for:)` normalisiert.
> Niemals `Date()` direkt speichern.

---

## Business-Logik

```swift
// Core/Constants.swift
enum TaxConstants {
    static let ratePerDay: Double = 6.0
    static let maxDaysPerYear: Int = 210
    static let productID = "de.DEINNAME.homeofficetracker.unlock"
}

func savings(days: Int) -> Double {
    Double(min(days, TaxConstants.maxDaysPerYear)) * TaxConstants.ratePerDay
}
```

---

## Monetarisierung

- **Preis:** 2,99 € (One-Time Purchase, kein Abo)
- **Paywall-Features:** CSV/PDF Export, Home Screen Widget, Mehrere Profile
- **Free-Features:** Tages-Toggle, Kalender, Jahres-Counter, Abend-Reminder
- **StoreKit 2 Product-ID:** `de.DEINNAME.homeofficetracker.unlock` (in App Store Connect anlegen)

---

## Free/Premium — Drei-Ebenen-Architektur

### Ebene 1: Compile-Time (Build Configuration)

Im Xcode-Projekt existieren vier Build-Konfigurationen:
- **Debug** — Entwicklung, `DEBUG=1`
- **Release** — App Store Release (Premium-App)
- **Free** — App Store Release Free-Tier (`FREE_TIER=1` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS`)
- **Premium** — identisch mit Release, eigenes Scheme

```swift
// Code nur im Free-Tier kompilieren:
#if FREE_TIER
// Free-only Logik
#endif
```

### Ebene 2: Xcode Schemes (einmalig in Xcode anlegen)

```
Xcode Toolbar → Scheme → Edit Scheme → Manage Schemes → +
→ "HomeofficeTracker Free"    → Build Configuration: Free
→ "HomeofficeTracker Premium" → Build Configuration: Premium
```

Als Entwickler: Scheme wechseln → sofort andere UI, kein Code-Umbau nötig.

### Ebene 3: Runtime-Check (SwiftUI)

```swift
// Core/AppConfiguration.swift
AppConfig.shared.isPremium  // → true/false

// In Views:
if AppConfig.shared.isPremium {
    PremiumView()
} else {
    FreeView()
}
```

`AppConfig.shared.isPremium`:
- Im **Free-Build** → immer `false` (compile-time)
- Im **Premium/Release-Build** → `StoreKitService.shared.isPurchased`

### Paywall-Check Pattern

```swift
// Neu (zentral, bevorzugt):
AppConfig.shared.isPremium

// Alternativ über Environment:
@Environment(StoreKitService.self) private var store
store.isPremium  // delegiert an AppConfig.shared.isPremium
```

---

## Xcode-Befehle (Terminal)

```bash
# Projekt öffnen
open HomeofficeTracker.xcodeproj

# Simulator starten
open -a Simulator

# Tests via xcodebuild
xcodebuild test \
  -scheme HomeofficeTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Archivieren für App Store
xcodebuild archive \
  -scheme HomeofficeTracker \
  -archivePath build/HomeofficeTracker.xcarchive
```

---

## Coding-Konventionen

- **Sprache im Code:** Englisch (Variablen, Kommentare, Commits)
- **UI-Texte:** Deutsch (`Localizable.xcstrings`)
- **SwiftData:** `@Query` Macro in Views; `ModelContext` nur in ViewModels/Services
- **Keine GPS/Location-Permissions:** Manuelle Eingabe only
- **Keine Netzwerk-Calls** (außer StoreKit 2 intern)
- **Concurrency:** Swift Concurrency (`async/await`, `@MainActor`)
- **Minimum Deployment Target:** iOS 17.0

---

## Export-Format (wichtig für DACH-Kompatibilität)

```swift
// CSV: UTF-8 BOM für Excel-Kompatibilität
let bom = "\u{FEFF}"
// Datum: dd.MM.yyyy | Dezimaltrennzeichen: Komma
let formatter = DateFormatter()
formatter.dateFormat = "dd.MM.yyyy"
formatter.locale = Locale(identifier: "de_DE")
```

---

## Aktueller Entwicklungsstand

Siehe `ARCHITECTURE.md` für alle Entscheidungen, `PRODUCT.md` für Feature-Scope.

**Phase:** → Aktiv entwickeln nach Roadmap in `ARCHITECTURE.md`

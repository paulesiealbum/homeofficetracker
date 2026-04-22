# ARCHITECTURE.md — Homeoffice-Tracker

## Tech Stack

| Komponente | Technologie | Begründung |
|---|---|---|
| UI Framework | SwiftUI | Native iOS, deklarativ, schnell entwickelbar |
| Sprache | Swift 5.9+ | Typsicher, Xcode-native, kein Extra-Setup |
| Datenbank | SwiftData (`@Model`) | Native, kein CoreData-Boilerplate, iOS 17+ |
| IAP / Paywall | StoreKit 2 | Native iOS, kein 3rd-Party nötig |
| Widget | WidgetKit + App Intents | Interaktives iOS 17 Widget |
| Notifications | UNUserNotificationCenter | Lokale Abend-Erinnerung |
| Export PDF | PDFKit | Native, kein 3rd-Party-Framework |
| Sync (v1.1) | CloudKit / iCloud | Optional, erst in v1.1 |

**Kein Backend. Kein Login. Alle Daten lokal (SwiftData).**

---

## Datenmodell

```swift
// Data/WorkDay.swift
import SwiftData

@Model
final class WorkDay {
    @Attribute(.unique) var date: Date   // Immer Mitternacht: Calendar.current.startOfDay(for:)
    var isHomeoffice: Bool
    var note: String?                    // Optional, max. 200 Zeichen

    init(date: Date, isHomeoffice: Bool = false, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isHomeoffice = isHomeoffice
        self.note = note
    }
}
```

> **Invariante:** `date` wird **immer** auf Mitternacht normalisiert (`startOfDay`).
> Niemals `Date()` direkt speichern.

---

## App Entry Point

```swift
// HomeofficeTrackerApp.swift
import SwiftUI
import SwiftData

@main
struct HomeofficeTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: WorkDay.self)
        }
    }
}
```

---

## View-Struktur

```
ContentView (TabView)
├── Tab 1: HomeView
│     ├── Tages-Toggle (groß, zentriert)
│     ├── "X von 210 Tagen"
│     ├── "Ersparnis: Y €"
│     └── Tap auf vergangenen Tag → DayDetailSheet
│
├── Tab 2: CalendarView
│     ├── Monatsnavigation (< >)
│     ├── Kalender-Grid (grün = HO / grau = kein HO / leer = kein Eintrag)
│     └── Tap auf Tag → DayDetailSheet
│
└── Tab 3: ExportView
      ├── [Paywall-Check via StoreKit 2]
      ├── Jahres-Auswahl Picker
      ├── "X Tage – Y € absetzbar"
      ├── [Als CSV exportieren] → ShareSheet
      └── [Als PDF exportieren] → ShareSheet
```

---

## StoreKit 2 Service

```swift
// Features/Paywall/StoreKitService.swift
import StoreKit

@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var isPurchased = false

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == TaxConstants.productID {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    func purchase() async throws {
        let products = try await Product.products(for: [TaxConstants.productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified = verification {
            isPurchased = true
        }
    }
}
```

---

## Entwicklungs-Roadmap

### Phase 1 — Xcode Projekt Setup

- [ ] Neues Xcode-Projekt anlegen: **App**, SwiftUI, SwiftData aktivieren
- [ ] Bundle Identifier setzen: `de.DEINNAME.homeofficetracker`
- [ ] Deployment Target: **iOS 17.0**
- [ ] Ordnerstruktur anlegen: `Core/`, `Data/`, `Features/`, `Shared/`
- [ ] `WorkDay.swift` SwiftData Model anlegen
- [ ] `Constants.swift` mit `TaxConstants`
- [ ] App Entry Point: `modelContainer(for: WorkDay.self)` in `HomeofficeTrackerApp`

### Phase 2 — Core Screens

- [ ] **HomeView** — Großer Toggle (heute HO / kein HO), Jahres-Counter, Ersparnis-Anzeige
- [ ] **CalendarView** — Monatskalender mit `LazyVGrid`, grün/grau/weiß
- [ ] **DayDetailSheet** — Notiz hinzufügen/bearbeiten (`.sheet` Modifier)
- [ ] **ContentView** — `TabView` mit 3 Tabs + Tab-Icons

### Phase 3 — Monetarisierung & Export

- [ ] `StoreKitService` implementieren (siehe oben)
- [ ] **PaywallView** — Produktinfos via `Product.products(for:)`, Kauf-Button, Restore
- [ ] **ExportView** — Jahres-Auswahl, CSV generieren, PDF via PDFKit generieren
- [ ] `UIActivityViewController` für ShareSheet (CSV + PDF)
- [ ] Paywall-Check in ExportView und WidgetKit-Entry

### Phase 4 — Widget & Notifications

- [ ] WidgetKit Extension Target in Xcode hinzufügen
- [ ] `HomeofficeWidget` — 1×1, zeigt heutigen Status + `AppIntent` zum Togglen
- [ ] `UNUserNotificationCenter` — Abend-Reminder 18:00 Uhr (lokale Notification)
- [ ] Widget hinter Paywall-Check

### Phase 5 — Simulator-Tests & App Store

- [ ] iOS Simulator: Grundfunktionen, SwiftData-Persistenz
- [ ] Jahresübergang Dez → Jan testen
- [ ] Export-Dateien in Numbers/Excel öffnen (UTF-8 BOM Check)
- [ ] StoreKit Testing: `.storekit` Configuration File in Xcode anlegen
- [ ] App Icon + Screenshots erstellen
- [ ] TestFlight Beta
- [ ] App Store Submission

---

## Entscheidungslog

Alle Architecture Decision Records sind in `DECISIONS.md` dokumentiert.

| ADR | Entscheidung |
|---|---|
| ADR-001 | SwiftUI statt UIKit |
| ADR-002 | SwiftData statt CoreData / SQLite |
| ADR-003 | StoreKit 2 direkt statt RevenueCat |
| ADR-004 | iOS only statt Cross-Platform |
| ADR-005 | One-Time Purchase statt Abo |
| ADR-006 | Kein GPS / keine automatische Erkennung |
| ADR-007 | Kein Backend / kein Login |

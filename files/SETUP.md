# SETUP.md — Projekt-Setup in Xcode

> Schritt-für-Schritt Anleitung für Claude Code.
> Xcode-UI-Aktionen (markiert mit 🖱️) müssen manuell ausgeführt werden.

---

## Schritt 1 — Xcode Projekt anlegen 🖱️

1. Xcode öffnen → **Create New Project**
2. Template: **iOS → App**
3. Einstellungen:
   - **Product Name:** `HomeofficeTracker`
   - **Bundle Identifier:** `de.DEINNAME.homeofficetracker`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData ✅
4. Speicherort wählen → **Create**

---

## Schritt 2 — Xcode Projekt konfigurieren 🖱️

1. Target `HomeofficeTracker` auswählen → **General**
2. **Deployment Info → Minimum Deployments:** iOS 17.0
3. **Signing & Capabilities → Team:** Eigenes Developer Team wählen
4. **Capabilities hinzufügen:**
   - `+ Capability` → **Push Notifications** (für Abend-Reminder)

---

## Schritt 3 — Ordnerstruktur anlegen

```bash
# Im Projektverzeichnis ausführen (neben HomeofficeTracker.xcodeproj)
mkdir -p HomeofficeTracker/Core
mkdir -p HomeofficeTracker/Data
mkdir -p HomeofficeTracker/Features/Tracking
mkdir -p HomeofficeTracker/Features/Export
mkdir -p HomeofficeTracker/Features/Paywall
mkdir -p HomeofficeTracker/Shared/Views
```

> Danach in Xcode: Rechtsklick auf `HomeofficeTracker` Group → **Add Files** → die neuen Ordner als Groups hinzufügen (oder direkt in Xcode mit New Group anlegen).

---

## Schritt 4 — Constants.swift anlegen

`HomeofficeTracker/Core/Constants.swift`:

```swift
import Foundation

enum TaxConstants {
    static let ratePerDay: Double = 6.0
    static let maxDaysPerYear: Int = 210
    static let productID = "de.DEINNAME.homeofficetracker.unlock"
}
```

---

## Schritt 5 — SwiftData Model anlegen

`HomeofficeTracker/Data/WorkDay.swift`:

```swift
import SwiftData
import Foundation

@Model
final class WorkDay {
    @Attribute(.unique) var date: Date
    var isHomeoffice: Bool
    var note: String?

    init(date: Date, isHomeoffice: Bool = false, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isHomeoffice = isHomeoffice
        self.note = note
    }
}

// Hilfsfunktion: Datum normalisieren
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
```

---

## Schritt 6 — App Entry Point anpassen

`HomeofficeTracker/HomeofficeTrackerApp.swift`:

```swift
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

## Schritt 7 — ContentView mit TabView

`HomeofficeTracker/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "house")
                }

            CalendarView()
                .tabItem {
                    Label("Kalender", systemImage: "calendar")
                }

            ExportView()
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
        }
    }
}
```

---

## Schritt 8 — HomeView (Tages-Toggle + Counter)

`HomeofficeTracker/Features/Tracking/HomeView.swift`:

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkDay> { _ in true })
    private var allDays: [WorkDay]

    private var today: WorkDay? {
        allDays.first { Calendar.current.isDateInToday($0.date) }
    }

    private var isHomeofficeToday: Bool {
        today?.isHomeoffice ?? false
    }

    private var hoCount: Int {
        let year = Calendar.current.component(.year, from: Date())
        return allDays.filter {
            $0.isHomeoffice &&
            Calendar.current.component(.year, from: $0.date) == year
        }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Großer Toggle
                Button {
                    toggleToday()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: isHomeofficeToday ? "house.fill" : "building.2")
                            .font(.system(size: 64))
                            .foregroundStyle(isHomeofficeToday ? .green : .secondary)
                        Text(isHomeofficeToday ? "Homeoffice" : "Kein Homeoffice")
                            .font(.title2.bold())
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.3), value: isHomeofficeToday)

                // Counter
                VStack(spacing: 8) {
                    Text("\(hoCount) von \(TaxConstants.maxDaysPerYear) Tagen")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    let savings = Double(min(hoCount, TaxConstants.maxDaysPerYear)) * TaxConstants.ratePerDay
                    Text("Ersparnis: \(savings, format: .currency(code: "EUR"))")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }

                Spacer()
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func toggleToday() {
        if let existing = today {
            existing.isHomeoffice.toggle()
        } else {
            let newDay = WorkDay(date: Date(), isHomeoffice: true)
            modelContext.insert(newDay)
        }
    }
}
```

---

## Schritt 9 — StoreKit Configuration File anlegen 🖱️

1. Xcode → File → New → File → **StoreKit Configuration File**
2. Name: `Products.storekit`, zum Projekt hinzufügen
3. `+` → **Add Non-Consumable Product**
   - Reference Name: `Premium Unlock`
   - Product ID: `de.DEINNAME.homeofficetracker.unlock`
   - Price: 2.99
4. Schema → Edit Scheme → Run → Options → **StoreKit Configuration** → `Products.storekit`

---

## Schritt 10 — StoreKitService anlegen

`HomeofficeTracker/Features/Paywall/StoreKitService.swift`:

```swift
import StoreKit

@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var isPurchased = false
    @Published var product: Product?

    func load() async {
        do {
            let products = try await Product.products(for: [TaxConstants.productID])
            product = products.first
        } catch {
            print("StoreKit load error: \(error)")
        }
        await checkStatus()
    }

    func checkStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == TaxConstants.productID {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    func purchase() async throws {
        guard let product else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            isPurchased = true
            await tx.finish()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await checkStatus()
    }
}
```

---

## Schritt 11 — Lokalisierung

`HomeofficeTracker/` → New File → **String Catalog** → `Localizable.xcstrings`

Dann im Code:
```swift
Text("Heute")                          // wird automatisch in Catalog aufgenommen
Text(String(localized: "Heute"))       // explizit
```

> Xcode extrahiert String-Literale automatisch in den String Catalog.

---

## Schritt 12 — Widget Extension Target 🖱️

1. Xcode → File → New → Target → **Widget Extension**
2. Name: `HomeofficeTrackerWidget`
3. **Include Configuration App Intent:** ✅
4. App Group für geteilte SwiftData-Daten: Beide Targets → Capabilities → **App Groups** → `group.de.DEINNAME.homeofficetracker`

---

## Nützliche Terminal-Befehle

```bash
# Projekt öffnen
open HomeofficeTracker.xcodeproj

# iOS Simulator starten
open -a Simulator

# Tests ausführen
xcodebuild test \
  -scheme HomeofficeTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Build für Simulator
xcodebuild build \
  -scheme HomeofficeTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Archiv für App Store
xcodebuild archive \
  -scheme HomeofficeTracker \
  -archivePath build/HomeofficeTracker.xcarchive \
  CODE_SIGN_STYLE=Automatic
```

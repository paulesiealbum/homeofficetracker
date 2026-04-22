import SwiftUI
import SwiftData

@main
struct HomeofficeTrackerApp: App {
    @State private var schedule = WorkScheduleSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environment(StoreKitService.shared)
                .environment(schedule)
                .task {
                    // Transaction-Listener sofort starten (Renewals, Rückerstattungen, Cross-Device-Käufe)
                    StoreKitService.shared.startTransactionListener()
                    // Premium-Status sofort prüfen (kein kurzes "Schloss"-Flackern für Käufer)
                    await StoreKitService.shared.load()
                    // Reminder beim Start synchronisieren (z.B. nach Neuinstall)
                    NotificationService.shared.syncWithSettings(
                        enabled: schedule.reminderEnabled,
                        hour: schedule.reminderHour,
                        minute: schedule.reminderMinute
                    )
                }
        }
    }
}

// MARK: - ModelContainer (iCloud Sync via CloudKit + App Group für Widget)

/// App Group Identifier — muss mit HomeofficeTracker.entitlements und
/// HomeofficeWidgetExtension.entitlements übereinstimmen.
let kAppGroupID = "group.com.paulweigt.homeofficetracker"

/// SQLite-Datei im App Group Container, die sowohl Haupt-App als auch Widget lesen können.
/// Gibt nil zurück wenn der App Group Container nicht erreichbar ist (Simulator ohne Entitlements).
private func appGroupStoreURL() -> URL? {
    FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: kAppGroupID)?
        .appendingPathComponent("homeoffice.sqlite")
}

/// Versucht einen CloudKit-fähigen Container zu erstellen.
/// Fallback-Kette:
///   1. CloudKit + App Group URL  (Widget-sharing ✅ + iCloud-Sync ✅)
///   2. Nur App Group URL         (Widget-sharing ✅, kein iCloud-Account)
///   3. Lokaler persistenter Container (kein Widget-sharing)
///   4. Lokaler Container nach Store-Reset (altes inkompatibles Schema)
///   5. In-Memory-Container als letzte Rettung
///
/// ✅ Entitlements in HomeofficeTracker.entitlements:
///    - com.apple.developer.icloud-services: [CloudKit]
///    - com.apple.developer.icloud-container-identifiers: [iCloud.com.Paul.HomeofficeTracker]
///    - com.apple.security.application-groups: [group.com.paulweigt.homeofficetracker]
///
/// ⚠️ CloudKit-Regeln im `@Model`:
///    - Alle non-optional Properties MÜSSEN einen Default haben.
///    - Keine `@Attribute(.unique)`-Constraints — CloudKit unterstützt das nicht.
private let sharedModelContainer: ModelContainer = {
    // Stufe 1: CloudKit + App Group URL (bestes Szenario: Sync + Widget-sharing).
    if let url = appGroupStoreURL(),
       let container = try? ModelContainer(
           for: WorkDay.self,
           configurations: ModelConfiguration(
               url: url,
               cloudKitDatabase: .private("iCloud.com.Paul.HomeofficeTracker")
           )
       ) {
        return container
    }

    // Stufe 2: App Group URL ohne CloudKit (kein iCloud-Account / Simulator).
    if let url = appGroupStoreURL(),
       let container = try? ModelContainer(
           for: WorkDay.self,
           configurations: ModelConfiguration(url: url)
       ) {
        return container
    }

    // Stufe 3: Lokaler persistenter Container ohne CloudKit-Sync.
    // Widget kann diesen Store NICHT lesen (kein App Group).
    if let container = try? ModelContainer(
        for: WorkDay.self,
        configurations: ModelConfiguration()
    ) {
        return container
    }

    // Stufe 4: Lokaler Load ist auch gescheitert — typisch ist ein altes Store-File
    // mit inkompatiblem Schema (z. B. nach Umbau auf CloudKit-taugliche Defaults).
    // Wir löschen die Default-Store-Dateien einmalig und versuchen es erneut.
    // ⚠️ Das verwirft lokale Dev-Daten. Für Production stattdessen SchemaMigrationPlan nutzen.
    deleteDefaultSwiftDataStoreFiles()

    if let container = try? ModelContainer(
        for: WorkDay.self,
        configurations: ModelConfiguration()
    ) {
        return container
    }

    // Stufe 5: In-Memory — Daten nicht persistent, aber App startet ohne Absturz.
    do {
        return try ModelContainer(
            for: WorkDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
    }
}()

/// Löscht die Default-SwiftData-Store-Dateien im Application-Support-Verzeichnis.
/// Nur aufrufen, wenn der reguläre Load bereits fehlgeschlagen ist.
private func deleteDefaultSwiftDataStoreFiles() {
    let fm = FileManager.default
    guard let appSupport = try? fm.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ) else { return }

    // SwiftData legt den Default-Store als "default.store" (+ -shm/-wal) im App-Support ab.
    for name in ["default.store", "default.store-shm", "default.store-wal"] {
        let url = appSupport.appendingPathComponent(name)
        try? fm.removeItem(at: url)
    }
    #if DEBUG
    print("ℹ️ SwiftData: alter Store wurde zurückgesetzt (inkompatibles Schema).")
    #endif
}

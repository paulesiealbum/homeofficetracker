# WIDGET-SETUP.md — Xcode-Konfiguration

> Diese Anleitung beschreibt alle manuellen Schritte, die in Xcode durchgeführt werden müssen,
> damit die neu erstellten Widget-Dateien funktionieren.

---

## Schritt 1 — App Group ID festlegen

In `WidgetDataBridge.swift` die Zeile:
```swift
static let appGroupID = "group.de.DEINNAME.homeofficetracker"
```
mit dem echten Bundle-Identifier ersetzen. Der App-Bundle-ID ist z. B. `de.paulweigt.homeofficetracker`, dann lautet die Group-ID:
```
group.de.paulweigt.homeofficetracker
```

---

## Schritt 2 — Widget Extension Target hinzufügen

1. Xcode → **File → New → Target…**
2. Kategorie **Application Extension** → **Widget Extension** wählen
3. Product Name: `HomeofficeWidget`
4. ✅ **Include Configuration Intent**: NEIN (kein Intent UI, wir nutzen AppIntents)
5. **Finish** → bei der Frage "Activate scheme?" → **Activate**

---

## Schritt 3 — App Group in BEIDEN Targets aktivieren

**Für das Haupt-Target (HomeofficeTracker):**
1. Project Navigator → Haupt-App-Target klicken
2. Tab **Signing & Capabilities**
3. **+ Capability** → **App Groups**
4. **+** → Group-ID eingeben: `group.de.DEINNAME.homeofficetracker`

**Für das Widget-Target (HomeofficeWidget):**
1. Project Navigator → Widget-Target klicken
2. Tab **Signing & Capabilities**
3. **+ Capability** → **App Groups**
4. Dieselbe Group-ID aus der Liste wählen

> ⚠️ Beide Targets müssen exakt dieselbe Group-ID verwenden.

---

## Schritt 4 — Dateien zum Widget-Target hinzufügen

Folgende Dateien müssen im **Widget-Target** als Member eingetragen sein.
Datei selektieren → rechts im **File Inspector** → **Target Membership**:

| Datei | HomeofficeTracker | HomeofficeWidget |
|---|---|---|
| `WorkDay.swift` | ✅ | ✅ |
| `LegalConfiguration.swift` | ✅ | ✅ |
| `Widget/WidgetDataBridge.swift` | ✅ | ✅ |
| `Widget/ToggleTodayIntent.swift` | ✅ | ✅ |
| `HomeofficeWidget/HomeofficeWidget.swift` | ❌ | ✅ |

---

## Schritt 5 — Widget-Datei in Xcode anlegen (falls nötig)

Wenn die Datei `HomeofficeWidget/HomeofficeWidget.swift` noch nicht im Xcode-Projekt erscheint:

1. Rechtsklick auf den Ordner `HomeofficeWidget` im Project Navigator
2. **Add Files to "HomeofficeTracker"…**
3. `HomeofficeWidget.swift` auswählen
4. Target Membership: nur **HomeofficeWidget** ✅

---

## Schritt 6 — Vorhandene Widget-Vorlage entfernen

Beim Erstellen des Widget Extension Targets generiert Xcode eine Vorlage.
Diese muss ersetzt werden durch unsere Datei:

1. Die generierte Datei (z. B. `HomeofficeWidget.swift` im Xcode-Template) löschen
2. Unsere Datei `HomeofficeWidget/HomeofficeWidget.swift` ist der Ersatz

---

## Schritt 7 — Build & Test

1. Schema auf **HomeofficeWidget** umstellen
2. **Cmd + B** — sollte ohne Fehler durchlaufen
3. Schema zurück auf **HomeofficeTracker**
4. App auf Simulator/Gerät starten
5. Langer Druck auf Homescreen → Widget hinzufügen → "Homeoffice Tracker" suchen

---

## Fehlerbehebung

### "App Group nicht gefunden" Crash
→ `appGroupID` in `WidgetDataBridge.swift` stimmt nicht mit Xcode überein. Bundle-ID prüfen.

### Widget zeigt immer "0 Tage"
→ Die App und das Widget lesen verschiedene SQLite-Dateien.
→ Prüfen: Beide Targets haben dieselbe App Group ID in Xcode eingetragen.
→ App einmal starten, damit die Daten in den App Group Container migriert werden.

### Interaktiver Button reagiert nicht
→ `ToggleTodayIntent.swift` ist nicht im Widget-Target eingetragen (Target Membership prüfen).

### Build Error: "Cannot find type 'WorkDay' in scope"
→ `WorkDay.swift` ist nicht im Widget-Target. File Inspector → Target Membership: HomeofficeWidget ✅

---

## Datenmigration beim ersten Start

Beim ersten Start nach der Änderung (`HomeofficeTrackerApp.swift` → `sharedContainer`) wird eine
**neue SQLite-Datei** im App Group Container erstellt. Bestehende Daten aus dem alten
Default-Container werden **nicht automatisch migriert**.

Wenn echte Nutzerdaten vorhanden sind, muss eine einmalige Migration implementiert werden:

```swift
// Einmalig in HomeofficeTrackerApp.swift oder einem MigrationService
// Alte URL (Default-Container):
let oldURL = URL.applicationSupportDirectory.appendingPathComponent("default.store")
// Neue URL:
let newURL = WidgetDataBridge.sharedStoreURL
// → Datei kopieren mit FileManager.default.copyItem(at:to:)
```

Für die Entwicklungsphase (noch keine echten Nutzer) ist keine Migration nötig.

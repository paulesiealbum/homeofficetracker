# DECISIONS.md — Architecture Decision Records

## ADR-001 | SwiftUI statt UIKit

**Status:** Akzeptiert

**Kontext:**
Solo-Entwickler, iOS-only App. UIKit wäre stabiler und kompatibel bis iOS 13, aber deutlich mehr Boilerplate.

**Entscheidung:**
SwiftUI als UI Framework.

**Begründung:**
- Deklaratives UI = weniger Code, schnellere Iteration
- `@Query` Macro integriert direkt mit SwiftData
- Previews beschleunigen Solo-Entwicklung erheblich
- iOS 17+ Zielgruppe macht SwiftUI-Einschränkungen irrelevant
- Kein `UIViewController`-Boilerplate

**Konsequenz:**
Minimum Deployment Target iOS 17.0. Ältere Geräte werden nicht unterstützt — für die Zielgruppe (Arbeitnehmer mit aktuellem iPhone) kein nennenswerter Verlust.

---

## ADR-002 | SwiftData statt CoreData / SQLite / UserDefaults

**Status:** Akzeptiert

**Kontext:**
Lokale Datenpersistenz für `WorkDay`-Objekte. Alternativen: CoreData (zu viel Boilerplate), SQLite (zu low-level), UserDefaults (zu simpel für Datumslisten).

**Entscheidung:**
SwiftData mit `@Model` Macro.

**Begründung:**
- Native iOS 17+ Lösung, kein Extra-Framework
- `@Model` Macro ersetzt CoreData-Entity-Editor komplett
- `@Query` in Views ist eine Zeile statt ViewModel + FetchRequest
- ACID-konform, automatische Migration
- Xcode-Debugger zeigt SwiftData-Store direkt an

**Konsequenz:**
iOS 17 Mindestanforderung ist dadurch fest gesetzt. `@Attribute(.unique)` auf `date` stellt sicher, dass kein Datum doppelt gespeichert wird.

---

## ADR-003 | StoreKit 2 direkt statt RevenueCat

**Status:** Akzeptiert

**Kontext:**
IAP-Implementierung für One-Time Purchase. RevenueCat würde Cross-Platform (iOS + Android) vereinfachen, aber wir sind iOS-only.

**Entscheidung:**
StoreKit 2 direkt (kein 3rd-Party-SDK).

**Begründung:**
- iOS-only: Kein Cross-Platform-Vorteil durch RevenueCat
- StoreKit 2 API (async/await) ist deutlich einfacher als StoreKit 1
- Keine SDK-Dependency, kein SDK-Update-Risiko
- Keine Drittanbieter-Daten (RevenueCat sieht Transaktionsdaten)
- Kostenfrei, kein MRR-Limit

**Konsequenz:**
Revenue-Tracking muss manuell über App Store Connect erfolgen (kein RevenueCat Dashboard). Für Solo-Projekt ausreichend. Falls Android-Launch geplant wird, kann RevenueCat nachträglich hinzugefügt werden.

---

## ADR-004 | iOS only statt Cross-Platform (Flutter / React Native)

**Status:** Akzeptiert

**Kontext:**
DACH-Zielgruppe, passives Einkommensprojekt. Cross-Platform würde Android-Markt öffnen.

**Entscheidung:**
iOS only für v1.0.

**Begründung:**
- Entwickler hat SwiftUI-Erfahrung — nativer Stack ohne Lernkurve
- iOS-Nutzer in DACH haben höhere App-Kaufbereitschaft
- Ein Codebase = weniger Bugs, schnellere Iteration für Solo-Entwickler
- Native Stack (SwiftData, WidgetKit, StoreKit 2) ohne Bridging-Layer
- Android kann in v2.0 mit Flutter als separatem Projekt nachgeholt werden

**Konsequenz:**
Android-Markt (~40% der DACH-Smartphones) wird in v1.0 nicht adressiert. Bewusste Entscheidung zugunsten von Qualität und Geschwindigkeit.

---

## ADR-005 | Jahres-Abo statt Einmalkauf

**Status:** Akzeptiert

**Kontext:**
Monetarisierungsstrategie. Einmalkauf wäre einfacher, aber Abo ermöglicht wiederkehrenden Umsatz und kein Support-Aufwand bei Gerätewechsel (Abo-Restore ist automatisch via Apple ID).

**Entscheidung:**
Jahres-Abo für 2,99 €/Jahr (Auto-Renewable Subscription).

**Begründung:**
- Kein konfuses Kaufmodell für Nutzer: ein klarer Preis/Jahr, kein Nachdenken über "was habe ich eigentlich gekauft"
- Apple handhabt Restore automatisch über Apple ID — kein "Kauf wiederherstellen"-Support-Aufwand
- Jährlicher Steuerkontext passt ideal zum Jahres-Abo: Nutzer erneuern bewusst zur Steuersaison
- 2,99 €/Jahr liegt klar im Impulskauf-Bereich — niedrigste Einstiegsschwelle
- Kündigung jederzeit möglich → kein Lock-in-Gefühl, kein negativer App-Store-Review-Grund

**Konsequenz:**
Revenue pro Nutzer ist 2,99 €/Jahr (wiederkehrend, solange aktiv). Churn-Rate minimal da Preis sehr niedrig. Wachstum über neue Downloads + Retention durch jährliche Feature-Updates.

---

## ADR-006 | Kein GPS / keine automatische HO-Erkennung

**Status:** Akzeptiert

**Kontext:**
Automatische Erkennung via GPS oder WiFi-SSID wäre Convenience-Mehrwert.

**Entscheidung:**
Manuelle Eingabe only. Keine Location-Permissions.

**Begründung:**
- Datenschutz: Keine standortbezogenen Daten = kein Risiko
- App Store Review: Weniger Permissions = weniger Friction, bessere Privacy-Nutrition-Label
- DSGVO-Konformität ohne Aufwand
- False Positives (Home-WiFi von Café?) wären problematisch für ein Steuerdokument

**Konsequenz:**
Nutzer muss täglich aktiv einchecken. Abend-Reminder (lokale Push Notification) kompensiert dies.

---

## ADR-007 | Kein Backend / kein Login

**Status:** Akzeptiert

**Kontext:**
Cloud-Sync wäre ein Mehrwert-Feature. Backend würde Geräte-übergreifendes Sync ermöglichen.

**Entscheidung:**
Keine Server-Infrastruktur, kein Nutzer-Account. Alle Daten lokal (SwiftData).

**Begründung:**
- Solo-Entwickler: Kein Ops-Overhead, keine Server-Kosten
- Datenschutz-Argument für Marketing ("Deine Daten bleiben auf deinem iPhone")
- App Store Privacy Nutrition Label: Maximale Privatsphäre-Einstufung
- Steuerdaten sind sensitiv — kein Cloud-Upload bevorzugt von der Zielgruppe

**Konsequenz:**
Kein Geräte-übergreifendes Sync in v1.0. iCloud-Sync via CloudKit ist als v1.1-Feature vorgesehen — bewusst aufgeschoben, da Apple die Infrastruktur bereitstellt und kein eigener Server nötig ist.

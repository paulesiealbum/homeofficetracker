# WIDGET-ANALYSE — HomeofficeTracker

> **Leitfrage:** Welche Widget-Art bringt dem Nutzer echten Mehrwert und lädt zur täglichen Interaktion ein?

---

## 1. Ausgangslage & Designprinzip

Die App hat eine klare Vision: **„Ein Tap pro Tag."** Das Widget muss genau dieses Versprechen auf den Homescreen verlängern — es sollte also *noch* schneller sein als die App selbst: kein Öffnen, kein Navigieren, nur tippen und fertig.

Technisch stehen mit iOS 17+ **interaktive Widgets** zur Verfügung (`Button` via `AppIntent`). Das ist ein entscheidender Vorteil gegenüber älteren WidgetKit-Generationen, weil der Nutzer heute direkt im Widget tippen kann, ohne die App öffnen zu müssen.

---

## 2. Die drei Widget-Varianten im Vergleich

### Variante A — Small Widget „Today Toggle" ⭐ Empfehlung

**Größe:** `systemSmall` (2×2 Einheiten, die am häufigsten verwendete Widget-Größe)

**Was der Nutzer sieht:**
```
┌─────────────────┐
│  🏠  Heute      │
│                 │
│  [ HOMEOFFICE ] │   ← interaktiver Button (iOS 17 AppIntent)
│                 │
│  47 / 210 Tage  │
│    282 €        │
└─────────────────┘
```

**Was der Nutzer tun kann:**
- Einmal tippen → Tag wird als Homeoffice geloggt (ohne App zu öffnen)
- Nochmals tippen → Eintrag wird zurückgenommen
- Widget zeigt sofort den aktualisierten Status

**Warum das funktioniert:**
- Spiegelt exakt die App-Philosophie: 1 Tap = 1 Tag
- Small ist die am häufigsten platzierte Widget-Größe → höchste Nutzungsfrequenz
- Der Jahres-Counter darunter schafft Motivation (Gamification durch €-Ersparnis)
- Keine kognitiven Kosten: Der Nutzer sieht auf einen Blick, ob er den Tag schon getrackt hat

**Technisch:**
- `WidgetKit` + `AppIntent` für den Toggle-Button
- `App Group` (UserDefaults Shared) für Datenaustausch zwischen App und Widget
- Timeline-Reload nach jedem Toggle via `WidgetCenter.shared.reloadAllTimelines()`

---

### Variante B — Medium Widget „Status + Wochenstreifen"

**Größe:** `systemMedium` (4×2 Einheiten)

**Was der Nutzer sieht:**
```
┌───────────────────────────────────────┐
│  Heute: 🏠 Homeoffice   [ TOGGLE ]    │
│                                       │
│  Mo  Di  Mi  Do  Fr  Sa  So           │
│  🟢  🔵  🟢  ⚪  heute ─  ─           │  ← letzte 7 Tage
│                                       │
│  47 / 210 Tage · 282 € Ersparnis      │
└───────────────────────────────────────┘
```

**Was der Nutzer tun kann:**
- Toggle für heute (wie Variante A)
- Lücken der letzten Woche auf einen Blick erkennen (war Donnerstag Homeoffice?)
- Tippen auf vergangenen Tag → öffnet App an diesem Tag

**Warum das funktioniert:**
- Nützlich für Nutzer, die gelegentlich vergessen zu tracken und nachholen wollen
- Wochenstreifen schafft visuellen Anreiz: "Nur noch Freitag fehlt"
- Höherer Informationsgehalt ohne Overload

**Nachteil:**
- Belegt mehr Homescreen-Fläche → weniger Nutzer werden es platzieren
- Vergangene Tage im Widget anklickbar zu machen (Deep Link in App) ist kein echter Widget-Mehrwert

---

### Variante C — Lock Screen Widget (Accessory)

**Größen:** `accessoryCircular` + `accessoryRectangular`

**Was der Nutzer sieht (Circular):**
```
   ╭──────╮
  │  🏠   │   oder   │  47 T  │
  │  ✓   │          │ 282 €  │
   ╰──────╯
```

**Was der Nutzer tun kann:**
- Antippen → öffnet App (kein direkter Toggle möglich bei Lock Screen Widgets)
- Immer sichtbar ohne zu entsperren

**Warum es trotzdem sinnvoll ist:**
- Sehr geringe Entwicklungskosten (gleiche Timeline-Logik wie Variante A)
- Zeigt permanente Erinnerung: "Noch nicht getrackt"
- Differenzierungsmerkmal im App Store Screenshot

**Nachteil:**
- Kein direkter Toggle → weniger Mehrwert als Variante A
- Nutzungsdaten zeigen, dass Lock Screen Widgets selten platziert werden

---

## 3. Empfehlung: Prioritäten & Umsetzungsreihenfolge

| Priorität | Variante | Aufwand | Mehrwert |
|---|---|---|---|
| **1 (Must-have)** | Small „Today Toggle" | ~2–3 Tage | Sehr hoch |
| **2 (Optional)** | Lock Screen Circular | ~0,5 Tage (Basis liegt schon vor) | Mittel |
| **3 (v1.2)** | Medium „Wochenstreifen" | ~2 Tage | Mittel |

**Der Kern ist eindeutig Variante A.** Das Small Widget ist das einzige, das die Kern-Interaktion der App (1 Tap = 1 Tag) vollständig auf den Homescreen verlagert. Alles andere ist Erweiterung.

---

## 4. Technische Umsetzung: Datenstrategie

Das größte technische Problem bei iOS-Widgets mit SwiftData: **Widgets können nicht direkt auf den SwiftData-ModelContainer der Haupt-App zugreifen.**

**Lösung: App Group + UserDefaults als Bridge**

```swift
// Im App Group UserDefaults schreiben (Haupt-App):
let defaults = UserDefaults(suiteName: "group.de.yourname.homeofficetracker")
defaults?.set(isHomeoffice, forKey: "todayIsHomeoffice")
defaults?.set(homeofficeDaysCount, forKey: "annualCount")
defaults?.set(savings, forKey: "annualSavings")

// Im Widget lesen:
let defaults = UserDefaults(suiteName: "group.de.yourname.homeofficetracker")
let isHomeoffice = defaults?.bool(forKey: "todayIsHomeoffice") ?? false
```

**AppIntent für Toggle:**
```swift
struct ToggleTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Heute umschalten"

    func perform() async throws -> some IntentResult {
        // Shared UserDefaults toggling
        // + WidgetCenter reload
        return .result()
    }
}
```

> ⚠️ Wichtig: Der AppIntent kann SwiftData nicht direkt nutzen. Die App muss nach dem nächsten Öffnen die UserDefaults-Werte in das SwiftData-Modell synchronisieren (oder der Toggle schreibt direkt in eine shared SQLite-Datei).

---

## 5. Was das Widget kommunizieren muss (UI-Inhalt)

Unabhängig von der Größe braucht das Widget immer diese **drei Informationen**:

1. **Heutiger Status** — HO oder Büro (visuell dominant, klar grün/grau)
2. **Jahres-Counter** — X / 210 Tage (Motivation durch Fortschrittsanzeige)
3. **€-Ersparnis** — Y € (der emotionale Anker, der zum Tracken motiviert)

Optional (Medium):
4. **Letzte 7 Tage** — als Mini-Kalenderstreifen

---

## 6. Paywall-Strategie für das Widget

Das Widget ist als Paid-Feature konzipiert (2,99 € One-Time Unlock). Das funktioniert gut, weil:

- Das Widget ist **sichtbar funktional** — der Nutzer muss es ausprobieren wollen
- Der beste Moment für die Paywall ist: **Nutzer tippen auf das Widget, sind noch nicht Premium**
  → Deep Link in App → Paywall mit Hinweis „Widget freischalten für 2,99 €"
- Alternativ: Widget zeigt im Free-Tier nur den Status (kein Toggle) → Anreiz zum Kauf bleibt

**Empfehlung:** Free-Tier zeigt Widget als Read-Only (Status + Counter), Premium schaltet den interaktiven Toggle frei. Das ist weniger frustrierend als ein gesperrtes Widget-Slot.

---

## Fazit

Das **Small Interactive Widget** ist die einzig richtige Wahl als primäres Widget. Es verlängert das Kern-Versprechen der App auf den Homescreen, lässt sich in 2–3 Entwicklungstagen umsetzen und wird am häufigsten von Nutzern platziert werden. Das Lock Screen Widget ist ein kostenloser Bonus. Das Medium Widget kann warten.

# App Store Submission – Homeoffice Tracker

## App Store Connect Metadaten

### Name
Homeoffice Tracker

### Untertitel (max. 30 Zeichen)
Steuerersparnis im Blick

### Beschreibung

Homeoffice Tracker hilft dir, deine Homeoffice-Tage rechtssicher zu dokumentieren und deine Steuerersparnis automatisch zu berechnen.

In Deutschland kannst du bis zu 210 Homeoffice-Tage pro Jahr steuerlich geltend machen – mit 6 € pro Tag macht das bis zu 1.260 € Steuervorteil. Homeoffice Tracker rechnet das automatisch für dich aus.

**Kostenlos:**
• Tage mit einem Tippen eintragen oder entfernen
• Kalender-Übersicht mit farblicher Markierung
• Steuerersparnis wird live berechnet (§4 Abs. 5 EStG)
• iCloud-Sync auf all deinen Apple-Geräten
• Tägliche Erinnerungen zur Nacherfassung
• Gesetzliche Grundlagen stets aktuell

**Premium (2,99 €/Jahr):**
• PDF- und CSV-Export (steuerkonform, für Steuerberater)
• Pendelkostenrechner (Entfernungspauschale §9 Abs. 1 Nr. 4 EStG)
• Mehrere Arbeitsstätten anlegen
• Automatische Wochenmuster-Befüllung

Die App speichert keine Daten auf externen Servern. Alle Daten bleiben auf deinem Gerät und in deiner privaten iCloud.

Premium ist ein automatisch verlängerbares Jahres-Abo für 2,99 €/Jahr. Kündigung jederzeit über die iOS-Einstellungen → Apple ID → Abonnements.

### Suchbegriffe (max. 100 Zeichen)
homeoffice,steuer,finanzamt,arbeitszimmer,home office,steuererklärung,tracker

### Support URL
https://github.com/paulweigt/homeofficetracker (oder eigene Support-Seite)

### Datenschutz-URL
→ Muss eine öffentlich erreichbare Datenschutzerklärung sein (z.B. über eine einfache Webseite oder GitHub Pages)

Mindestinhalt:
- Welche Daten gespeichert werden (WorkDay-Einträge lokal + iCloud)
- Kein Tracking, keine Werbung, keine Weitergabe an Dritte
- Kontaktmöglichkeit

### Altersfreigabe
4+ (keine problematischen Inhalte)

### Kategorie
Primär: Finanzen
Sekundär: Produktivität

---

## Screenshots

Pflicht: **6,7" Display** (iPhone 16 Pro Max / 15 Pro Max)
Optional aber empfohlen: **5,5"** (iPhone 8 Plus, ältere Geräte)

Reihenfolge empfohlen:

| # | Screen | Beschreibung |
|---|--------|--------------|
| 1 | HomeView – heute Homeoffice | Status-Card grün + Jahresfortschrittsbalken |
| 2 | Kalender mit eingetragenen Tagen | Mehrere grüne Tage, Ersparnis sichtbar |
| 3 | Steuerersparnis-Detail | Betrag prominent, "210 Tage × 6 €" |
| 4 | Paywall / Premium-Features | Auflistung der Features + Preis 2,99 €/Jahr |
| 5 | Export-Ansicht | PDF- oder CSV-Vorschau |

**Maße:** 1290 × 2796 px (6,7")
**Tipp:** Xcode Simulator "iPhone 16 Pro Max" → Screenshot mit ⌘S

⚠️ **Pflicht für Abo-Apps:** Screenshot 4 (Paywall) muss den Preis und „Kündigung jederzeit" sichtbar zeigen — Apple Review prüft dies explizit.

---

## In App Store Connect konfigurieren

### Schritt 1: Abo-Gruppe anlegen

1. App Store Connect → deine App → linke Leiste **„In-App-Käufe"** → Tab **„Abonnements"**
2. **„+"** → neue Abonnementgruppe
3. Referenzname der Gruppe: `Premium`
4. **„Erstellen"** klicken

### Schritt 2: Jahres-Abo anlegen

1. Innerhalb der neuen Gruppe: **„+"** → neues Abonnement
2. Felder ausfüllen:
   - Referenzname: `Premium Jahres-Abo`
   - Produkt-ID: `com.Paul.HomeofficeTracker.premium.annual` ← **exakt so!**
3. **„Erstellen"** klicken
4. Auf der nächsten Seite:
   - **Abonnementlaufzeit:** 1 Jahr
   - **Preis:** Suche nach „2.99" → Zeile mit **EUR 2,99** wählen
   - **Lokalisierungen** → **„+"** → Deutsch
     - Anzeigename: `Premium Jahres-Abo`
     - Beschreibung: `Schaltet alle Premium-Features frei: PDF/CSV-Export, Pendelkostenrechner, mehrere Arbeitsstätten und Wochenmuster Auto-Fill. Kündigung jederzeit möglich.`
   - **Lokalisierungen** → **„+"** → Englisch (USA)
     - Anzeigename: `Premium Annual`
     - Beschreibung: `Unlocks all premium features: PDF/CSV export, commuter deduction, multiple workplaces, weekly auto-fill. Cancel anytime.`
   - **„Sichern"** klicken
5. Scrolle hoch → **„Zur Prüfung einreichen"** (wird zusammen mit der App geprüft)

### Schritt 3: .storekit Testdatei in Xcode aktivieren

In Xcode: Edit Scheme → Run → Options → StoreKit Configuration → `HomeofficeTracker.storekit` auswählen

### Apple-Pflichtangaben für Abo-Apps

Apple verlangt für automatisch verlängerbare Abonnements folgende Elemente — alle sind bereits in der App vorhanden:

| Anforderung | Umsetzung in der App |
|---|---|
| Preis + Laufzeit klar sichtbar | Preisbox in PaywallView: „2,99 €/Jahr" |
| „Kündigung jederzeit möglich" | Preisbox-Subtitle in PaywallView |
| Restore-Button | „Kauf wiederherstellen" in PaywallView |
| Abo-Bedingungen in App Store-Beschreibung | Letzter Absatz der Beschreibung (s.o.) |
| Verlinkung Aboverwaltung | iOS-Einstellungen → Apple ID (automatisch via Apple) |

---

## CloudKit Schema in Production deployen

1. Öffne [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Container: `iCloud.com.Paul.HomeofficeTracker`
3. Oben rechts: **"Deploy Schema to Production"**
4. Bestätigen

⚠️ Nur einmal nötig. Danach können echte User Daten speichern.

---

## App Icon Dark/Tinted

Aktuelle Platzhalter in `Assets.xcassets/AppIcon.appiconset/`:
- `AppIcon-Dark.png` → ersetzen mit dunkler Variante (dunkler Hintergrund, helles Icon)
- `AppIcon-Tinted.png` → ersetzen mit monochromer Variante (reines Schwarz-Weiß / Graustufen, iOS 18 färbt es automatisch ein)

Größe jeweils: **1024 × 1024 px**, PNG ohne Transparenz.

---

## Checkliste vor Submit

**App Store Connect:**
- [ ] Abo-Gruppe `Homeoffice Tracker Premium` angelegt
- [ ] Jahres-Abo `com.Paul.HomeofficeTracker.premium.annual` angelegt und genehmigt
- [ ] Abo-Beschreibung auf Deutsch und Englisch hinterlegt
- [ ] Paywall-Screenshot für Abo-Review hochgeladen (zeigt Preis + „Kündigung jederzeit")
- [ ] App Store-Beschreibung enthält Abo-Hinweis (Preis, Laufzeit, Kündigung)
- [ ] Screenshots hochgeladen (mind. 6,7")
- [ ] Datenschutz-URL hinterlegt

**Xcode / Technisch:**
- [ ] CloudKit Schema in Production deployed
- [ ] App mit Release-Config archiviert (nicht Free/Premium Build-Flag)
- [ ] StoreKit Sandbox-Test erfolgreich (Kauf + Restore + Ablauf)
- [ ] App Icon Dark/Tinted Varianten finalisiert
- [ ] Keine offenen kritischen Crashes in Xcode Organizer

**TestFlight:**
- [ ] Beta-Test durchgeführt (mind. Kauf-Flow + Restore getestet)
- [ ] Abo-Renewal im Sandbox-Modus verifiziert (Sandbox = 5 Min. statt 1 Jahr)

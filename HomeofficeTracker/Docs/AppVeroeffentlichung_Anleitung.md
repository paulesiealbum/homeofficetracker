# Homeoffice Tracker – App Store Veröffentlichung
## Schritt-für-Schritt Anleitung (für Erstveröffentlicher)

---

## Vorbereitung: Was du brauchst

- [ ] Mac mit Xcode
- [ ] Apple Developer Account (99 €/Jahr) → https://developer.apple.com/programs/
- [ ] iPhone zum Testen
- [ ] Ca. 2–3 Stunden Zeit

---

## SCHRITT 1: Apple Developer Account einrichten

1. Gehe zu https://developer.apple.com/account/
2. Melde dich mit deiner Apple ID an
3. Falls noch kein Developer Account: "Enroll" klicken → Einzelperson → 99 €/Jahr bezahlen
4. Warte auf Bestätigungs-E-Mail (meist sofort, manchmal 24h)

---

## SCHRITT 2: App Store Connect öffnen

1. Gehe zu https://appstoreconnect.apple.com
2. Melde dich mit deiner Apple ID an
3. Klicke auf **"My Apps"**
4. Klicke auf das **"+"** oben links → **"New App"**

**Felder ausfüllen:**
- Platforms: **iOS**
- Name: **Homeoffice Tracker**
- Primary Language: **German**
- Bundle ID: **com.Paul.HomeofficeTracker** (vorher in Xcode Signing & Capabilities gesehen)
- SKU: **homeofficetracker2024** (beliebiger einzigartiger String, intern)
- User Access: Full Access

→ Klicke **"Create"**

---

## SCHRITT 3: In-App Käufe anlegen

### 3a. Abo-Gruppe anlegen

1. In App Store Connect: linke Leiste → **"Subscriptions"** (unter deiner App)
2. Klicke **"+"** → neue Abo-Gruppe erstellen
3. Group Name: `Homeoffice Tracker Premium`
4. Reference Name: `Premium`
5. **"Create"** klicken

### 3b. Jahres-Abo anlegen (das einzige IAP-Produkt)

1. Innerhalb der neuen Abo-Gruppe: **"+"** → neues Abonnement
2. Felder ausfüllen:
   - Reference Name: `Premium Jahres-Abo`
   - Product ID: `com.Paul.HomeofficeTracker.premium.annual` ← **exakt so, keine Änderung!**
3. **"Create"** klicken
4. Auf der nächsten Seite:
   - **Subscription Duration:** 1 Year
   - **Price**: Suche nach "2.99" → wähle die Zeile mit **EUR 2,99/Jahr**
   - Scrolle zu **"Localizations"** → klicke **"+"** → **German**
   - Display Name: `Premium Jahres-Abo`
   - Description: `Schaltet alle Premium-Features frei: PDF/CSV-Export, Pendelkostenrechner, mehrere Arbeitsstätten und Wochenmuster Auto-Fill. Kündigung jederzeit möglich.`
   - Klicke **"Save"**
5. Scrolle hoch → **"Submit for Review"** (wird zusammen mit der App geprüft)

⚠️ **Wichtig:** Kein Non-Consumable anlegen. Es gibt nur dieses eine Abo-Produkt.

---

## SCHRITT 4: CloudKit Schema in Production deployen

*(Nur einmalig nötig — damit echte User ihre Daten in iCloud speichern können)*

1. Gehe zu https://icloud.developer.apple.com/dashboard/
2. Wähle Container: **iCloud.com.Paul.HomeofficeTracker**
3. Oben links: stelle sicher du bist im Tab **"Development"**
4. Klicke oben rechts auf **"Deploy Schema to Production"**
5. Bestätige den Dialog

⚠️ Falls der Button grau ist: du hast noch keine Daten in Development gespeichert. Starte die App einmal auf deinem iPhone (mit deinem iCloud-Account), trage einen Homeoffice-Tag ein, dann erscheint der Button.

---

## SCHRITT 5: Datenschutzerklärung erstellen

Apple fordert eine öffentlich erreichbare Datenschutz-URL. Einfachste Lösung:

### Option A: GitHub Pages (kostenlos, 10 Minuten)
1. Erstelle einen GitHub Account (falls nicht vorhanden): https://github.com
2. Neues Repository: `homeofficetracker-privacy` (öffentlich)
3. Neue Datei: `index.md`
4. Inhalt (kopieren und anpassen):

```
# Datenschutzerklärung – Homeoffice Tracker

Letzte Aktualisierung: April 2026

## Datenerhebung und -verwendung

Homeoffice Tracker speichert ausschließlich deine eingetragenen Homeoffice-Tage,
Arbeitsstätten und Einstellungen. Diese Daten werden lokal auf deinem Gerät und
optional in deiner privaten iCloud gespeichert.

## Was wir NICHT tun

- Keine Weitergabe an Dritte
- Kein Tracking
- Keine Werbung
- Keine Analyse deines Verhaltens

## iCloud Sync

Falls du iCloud aktivierst, werden deine Daten über Apples CloudKit synchronisiert.
Dabei gilt Apples Datenschutzrichtlinie: https://www.apple.com/de/legal/privacy/

## Kontakt

Bei Fragen: pweigt@gmail.com
```

5. Repository Settings → Pages → Source: main branch → Save
6. Deine URL lautet: `https://[dein-username].github.io/homeofficetracker-privacy`

### Option B: Simplesite / Notion / jede öffentliche Webseite
Irgendeine öffentliche URL mit dem Datenschutztext reicht.

---

## SCHRITT 6: Screenshots erstellen

1. In Xcode: Scheme auf **"iPhone 16 Pro Max"** Simulator stellen
2. App starten (▶)
3. Navigiere zu den Screens (HomeView mit eingetragenen Tagen, Kalender, Ersparnis-Detail, Paywall, Widget-Vorschau)
4. Screenshot: **⌘S** im Simulator (speichert auf Desktop)
5. Du brauchst mindestens **5 Screenshots** im Format 1290 × 2796 px

**Empfohlene Screens (in dieser Reihenfolge):**
1. HomeView — heute ist Homeoffice, Jahresfortschritt sichtbar
2. Kalenderansicht — mehrere grüne Homeoffice-Tage eingetragen
3. Jahresersparnis mit Betrag (möglichst 210 Tage eingetragen für den vollen Betrag)
4. Paywall-Screen (Premium-Features Übersicht)
5. Widget auf Home Screen (Screenshot vom echten iPhone mit Widget)

---

## SCHRITT 7: App in Xcode archivieren

1. In Xcode oben: Scheme auf dein iPhone stellen (NICHT Simulator)
2. Menü: **Product → Archive** (dauert 1–2 Minuten)
3. Es öffnet sich der **Organizer** mit dem fertigen Archiv
4. Klicke **"Distribute App"**
5. Wähle **"App Store Connect"** → **"Next"**
6. **"Upload"** → Alle Häkchen lassen wie sie sind → **"Next"**
7. Signing: **"Automatically manage signing"** → **"Next"**
8. **"Upload"** klicken
9. Warte bis "Upload Successful" erscheint (1–5 Minuten)

⚠️ Stelle sicher: Build Configuration ist **Release** (nicht Free/Premium). Xcode wählt das automatisch beim Archivieren.

---

## SCHRITT 8: App Store Connect – App fertigstellen

Gehe zurück zu https://appstoreconnect.apple.com → deine App

### Version Information
- **Version**: 1.0
- **What's New**: (leer lassen bei erster Version)

### App Information
- **Category**: Finance
- **Secondary Category**: Productivity
- **Privacy Policy URL**: deine URL aus Schritt 5

### Pricing and Availability
- Price: **Free** (Geld kommt aus den In-App Käufen)
- Availability: All Countries / Regions

### App Review Information
- Sign-in required: **No**
- Demo Account: (leer)
- Notes: `App tracks homeoffice days for German tax purposes (§4 Abs. 5 Satz 1 Nr. 6c EStG). Premium features unlockable via in-app purchase. No login required.`
- First & Last Name: dein Name
- Phone: deine Nummer
- Email: deine E-Mail

### Screenshots hochladen
1. Wähle **"iPhone 6.7" Display"** Tab
2. Ziehe deine 5 Screenshots rein (in der richtigen Reihenfolge)

### Build auswählen
Scrolle zu **"Build"** → klicke **"+"** → wähle den gerade hochgeladenen Build
(Kann 10–30 Minuten dauern bis der Build erscheint — Kaffee holen)

### Metadaten ausfüllen
- **Description**: (Text aus `Docs/AppStoreSubmission.md` kopieren)
- **Keywords**: `homeoffice,steuer,finanzamt,arbeitszimmer,home office,steuererklärung,tracker`
- **Support URL**: GitHub-Seite oder eigene Website

---

## SCHRITT 9: Zur Prüfung einreichen

1. Alle Felder ausgefüllt? → kein roter Hinweis mehr sichtbar
2. Klicke oben rechts: **"Add for Review"**
3. Dann: **"Submit to App Review"**

**Wartezeit**: Erstmalig 24–48 Stunden (oft schneller, manchmal länger)
**Status verfolgen**: App Store Connect → deine App → "App Review"

---

## SCHRITT 10: Nach der Genehmigung

1. Du bekommst eine E-Mail "Your app has been approved"
2. In App Store Connect: **"Release this Version"** klicken
3. Die App ist live! 🎉

---

## Häufige Ablehnungsgründe (und wie du sie vermeidest)

| Grund | Lösung |
|-------|--------|
| Kein Restore-Button bei Abo | ✅ bereits implementiert in PaywallView |
| Fehlende Datenschutz-URL | ✅ Schritt 5 |
| IAP-Produkte nicht genehmigt | ✅ In Schritt 3 "Submit for Review" klicken |
| Screenshots fehlen | ✅ Schritt 6 |
| App stürzt beim Start ab | Vorher im TestFlight testen |

---

## Optional aber empfohlen: TestFlight Beta-Test

Vor dem echten Release auf TestFlight (Apples Beta-Plattform) testen:

1. In App Store Connect: **"TestFlight"** Tab
2. Build erscheint automatisch (nach Upload)
3. **"+"** bei Internal Testers → deine Apple ID hinzufügen
4. Auf iPhone: TestFlight App installieren → Beta testen
5. Teste besonders: IAP-Kauf, Restore, Widget, Export

---

## Zeitplan (realistisch)

| Tag | Was |
|-----|-----|
| Tag 1 | Schritte 1–4 erledigen (Accounts, IAP, CloudKit) |
| Tag 1 | Schritt 5: Datenschutz-URL |
| Tag 2 | Schritt 6–7: Screenshots + Archivieren |
| Tag 2 | Schritt 8–9: App Store Connect + Submit |
| Tag 4–5 | Apple-Prüfung abgeschlossen |
| Tag 5 | 🚀 Live im App Store |

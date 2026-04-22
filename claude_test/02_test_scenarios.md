# 02 — Testszenarien

Jedes Szenario hat: Voraussetzungen → Schritte → Erwartetes Ergebnis → Konsistenzprüfung → Persona-Relevanz.

---

## BLOCK 1: Onboarding & Erstkonfiguration

### T-01 Erststart ohne Vorkenntnisse
**Personas:** A3, C1, C5  
**Voraussetzung:** Frische App-Installation, keine Daten

**Schritte:**
1. App öffnen
2. Onboarding erscheint → Step 1: Arbeitstage wählen
3. Standard ist Mo–Fr vorausgewählt → Nutzer ändert nichts
4. "Weiter" tippen
5. Step 2: Standard-HO-Tage → Nutzer wählt Mo + Mi
6. "Fertig" tippen
7. HomeView erscheint

**Erwartetes Ergebnis:**
- Onboarding erscheint genau einmal
- Auswahl aus Step 1 filtert Step 2 korrekt (nur Arbeitstage auswählbar)
- HomeView zeigt korrekten Monat
- Counter zeigt "0 / 210 Tage — €0,00"
- Toggle zeigt heutigen Status korrekt

**Konsistenzcheck:**  
- [ ] Sind Standard-HO-Tage in Settings gespeichert und sichtbar?
- [ ] Öffnet man Settings → sieht man Mo + Mi vorausgewählt?
- [ ] Startet man App erneut → kein Onboarding mehr?

**Bekannte Lücke:** Kein "Überspringen"-Button — Nutzer muss durchklicken.

---

### T-02 Onboarding mit Teilzeit-Konfiguration
**Personas:** A5  
**Voraussetzung:** Frische App-Installation

**Schritte:**
1. Step 1: Nur Mo, Di, Do aktivieren (Teilzeit)
2. "Weiter"
3. Step 2: Prüfen ob nur Mo, Di, Do angeboten werden

**Erwartetes Ergebnis:**  
- Step 2 zeigt exakt die Tage aus Step 1
- Mi, Fr, Sa, So sind in Step 2 nicht wählbar

**Konsistenzcheck:**
- [ ] Counter berücksichtigt Teilzeit korrekt (max 210 Tage nur Mo/Di/Do)?
  - **BUG-RISIKO:** Wenn Benutzer nur 3 Tage/Woche arbeitet, sind 210 Tage nie erreichbar. Zeigt die App das richtig?

---

## BLOCK 2: Tages-Toggle (Core Feature)

### T-03 Heute als Homeoffice markieren
**Personas:** A1, A2, C3  
**Voraussetzung:** Onboarding abgeschlossen, heute ist ein Arbeitstag

**Schritte:**
1. HomeView öffnen
2. Großes Icon antippen (Haus-Symbol)
3. Status wechselt zu "Homeoffice"

**Erwartetes Ergebnis:**
- Icon wechselt zu grünem Haus
- Text wechselt zu "Homeoffice / Heute"
- Counter erhöht sich um 1
- Steuerersparnis aktualisiert sich: +€6,00
- Kalender-Zelle für heute wird grün

**Konsistenzcheck:**
- [ ] Erneutes Tippen → wechselt zurück zu "Kein Homeoffice" + Counter –1
- [ ] Counter stimmt mit farbigen Zellen im Kalender überein
- [ ] Tipp auf Samstag/Sonntag (wenn nicht Arbeitstag) → kein Toggle möglich?

---

### T-04 Rückwirkend Tage eintragen
**Personas:** A1, A2, C4  
**Voraussetzung:** App seit 2 Wochen nicht genutzt

**Schritte:**
1. Vergangene Woche im Kalender sehen
2. Montag (vor 5 Tagen) antippen
3. Detail-Sheet öffnet sich
4. "Homeoffice" Toggle aktivieren
5. Speichern
6. Dienstag antippen → Detail-Sheet → HO aktivieren → Speichern
7. Mittwoch: Urlaub → "Urlaub" wählen → Speichern

**Erwartetes Ergebnis:**
- Mo + Di grün im Kalender
- Mi orange (Urlaub) im Kalender
- Counter +2 (Urlaub zählt NICHT als HO-Tag)
- Steuerersparnis +€12,00

**Konsistenzcheck:**
- [ ] Kann man Zukunftstage ohne Planning Mode antippen? → Nein, blockiert
- [ ] Stimmt die Farbkodierung: Grün=HO, Orange=Urlaub, Rot=Krank, Lila=Feiertag, Grau=Büro?

---

### T-05 Wochenende / Nicht-Arbeitstag
**Personas:** A5, D1  
**Voraussetzung:** Arbeitstage = Mo–Fr konfiguriert

**Schritte:**
1. Samstag im Kalender antippen

**Erwartetes Ergebnis:**
- Kein Detail-Sheet erscheint ODER Sheet öffnet sich mit deaktiviertem HO-Toggle
- Keine Zählung

**Konsistenzcheck:**
- [ ] Was passiert wenn Nutzer Samstag als Arbeitstag konfiguriert hat? → Toggle sollte dann funktionieren

---

## BLOCK 3: Wochenplanung / Planning Mode (Vorab-Markierung)

### T-06 Planning Mode aktivieren und Zukunftstage markieren
**Personas:** A1, B2, C3  
**Voraussetzung:** Heutiges Datum = 11. April, Zukunftstage noch nicht belegt

**Schritte:**
1. Planning Mode Icon (oben rechts) antippen → Kalender.badge.plus
2. April 14 (Montag nächste Woche) antippen
3. Detail-Sheet öffnet sich
4. HO aktivieren, speichern
5. April 15–17 einzeln oder via Drag markieren

**Erwartetes Ergebnis:**
- Zukünftige Tage werden grün markiert
- Counter erhöht sich entsprechend (geplante HO-Tage werden schon gezählt)
- Planning Mode Indicator ist sichtbar

**Konsistenzcheck:**
- [ ] Wenn man Planning Mode ausschaltet → sind geplante Tage noch sichtbar?
- [ ] Sind geplante Tage im Counter enthalten oder nicht? (Klare Regel nötig!)
- [ ] Kann man einen geplanten Tag am Tag selbst überschreiben?

**KRITISCHER FRAGE:** Zählt die App geplante Zukünftige Tage im Counter mit?  
→ Wenn ja: Nutzer sieht €-Ersparnis bevor sie eingetreten ist → positiv für Motivation  
→ Wenn nein: Konsistenz wichtig — muss klar kommuniziert werden

---

### T-07 Drag-to-Select (Mehrere Tage auf einmal)
**Personas:** A2, B3, C4  
**Voraussetzung:** Planning Mode aktiv, leere Zukunftswoche

**Schritte:**
1. Finger auf Montag legen und über Di, Mi, Do, Fr ziehen
2. Multi-Select-Sheet erscheint: "5 Tage ausgewählt"
3. "Homeoffice" aktivieren
4. Speichern

**Erwartetes Ergebnis:**
- Alle 5 Tage grün im Kalender
- Counter +5, Ersparnis +€30

**Konsistenzcheck:**
- [ ] Was passiert wenn Drag auf Wochenend-Tage geht? → Sollte übersprungen werden
- [ ] Was wenn Drag auf bereits markierte Tage geht? → Toggle oder Überschreiben?
- [ ] Funktioniert Drag auch für vergangene Tage im Planning Mode?

---

### T-08 Regelmäßige HO-Tage als Standard (Wochenmuster)
**Personas:** A1, A5, B4  
**Voraussetzung:** Standard-HO-Tage = Mo + Mi in Settings

**Test-Frage:** Gibt es eine Funktion "Alle Montage und Mittwoche als HO markieren"?

**Aktuelle Situation (Stand Code-Analyse):**
- Standard-HO-Tage existieren in Settings
- Aber es ist **kein Auto-Fill** implementiert — die App markiert Tage nicht automatisch
- Nutzer muss jeden Tag manuell toggeln

**Erwartetes Verhalten (idealerweise):**
- Button "Standard-Woche anwenden" für aktuellen/vergangenen Monat
- Oder: Beim Öffnen der App wird Heute automatisch auf Standard gesetzt

**Befund:** Dies ist ein **Feature Gap** — Standard-HO-Tage sind konfigurierbar aber werden nicht genutzt!

---

## BLOCK 4: Spezielle Tage

### T-09 Urlaub eintragen
**Personas:** A2, B4, D1  

**Schritte:**
1. Vergangenen Urlaubstag antippen
2. Detail-Sheet öffnen
3. Typ "Urlaub" wählen
4. Speichern

**Erwartetes Ergebnis:**
- Orange im Kalender
- HO-Counter bleibt unverändert (Urlaub ≠ HO-Tag)
- Kein negativer Einfluss auf 210-Tage-Limit

**Konsistenzcheck:**
- [ ] Was wenn man gleichzeitig "Homeoffice" UND "Urlaub" wählt? Sollte verhindert werden
- [ ] Urlaub-Tage in Export enthalten? → Ja, für vollständige Dokumentation

---

### T-10 Feiertag eintragen / Automatische Erkennung
**Personas:** B4, D3  

**Schritte:**
1. Karfreitag (18.04.) antippen
2. Als "Feiertag" markieren

**Erwartetes Ergebnis:**
- Lila im Kalender
- Zählt nicht als HO-Tag

**Feature Gap:**  
- Es gibt **keine automatische Feiertagserkennung** — Nutzer muss selbst wissen welche Tage Feiertage sind
- DACH-Region hat unterschiedliche Feiertage je Bundesland/Kanton

---

## BLOCK 5: Jahresgrenze & Counter-Logik

### T-11 Jahreswechsel (Dezember → Januar)
**Personas:** A2, D2  
**Voraussetzung:** Dezember mit 20 HO-Tagen belegt

**Schritte:**
1. 20 HO-Tage im Dezember eintragen
2. Counter zeigt "20 / 210 Tage"
3. In App zu Januar navigieren (Monat wechseln)

**Erwartetes Ergebnis:**
- Januar-Counter zeigt "0 / 210 Tage"
- Dezember-Counter noch korrekt in Dezember-Ansicht

**Konsistenzcheck:**
- [ ] Welches Jahr zeigt der Counter auf HomeView? Aktuelles Kalenderjahr
- [ ] Kann man rückwirkend Jahr 2024 einsehen?
- [ ] Exportiert man 2024 korrekt (nur 2024-Daten)?

---

### T-12 210-Tage-Limit erreicht
**Personas:** B4, A2  
**Voraussetzung:** Nahezu 210 HO-Tage eingetragen

**Schritte:**
1. 209 Tage eingetragen
2. Nächsten Tag als HO markieren → Counter 210/210
3. Nächsten weiteren Tag als HO markieren → Counter 211/210?

**Erwartetes Ergebnis:**
- Counter zeigt "210 / 210 Tage — €1.260,00"
- Bei 211 Tagen: Warnung oder Counter zeigt weiterhin max €1.260?
- **Noch kein Hinweis im Code** ob es eine Deckelung gibt

**BUG-RISIKO:** App könnte "€1.266,00" anzeigen — falsche Steuerinformation!

---

## BLOCK 6: Export (Premium)

### T-13 Export-Button ohne Premium
**Personas:** C1, C5, A3  

**Schritte:**
1. Zu Export/Settings navigieren
2. "Export (Premium)" Button antippen

**Erwartetes Ergebnis:**
- Paywall erscheint
- Preis aus StoreKit geladen
- "Vielleicht später" schließt Paywall

**Konsistenzcheck:**
- [ ] Preis korrekt für AT/CH-Nutzer (lokale Währung)?
- [ ] Paywall zeigt alle Premium-Features klar?
- [ ] Wiederherstellungs-Option vorhanden?

---

### T-14 CSV-Export (Post-Purchase)
**Personas:** A1, A2, B3  
**Voraussetzung:** Premium freigeschaltet, 50 HO-Tage eingetragen

**Schritte:**
1. Export-Screen öffnen
2. Steuerjahr 2025 auswählen
3. "Als CSV exportieren" antippen
4. Share-Sheet erscheint

**Erwartetes Ergebnis:**
- Dateiname: `homeoffice_2025.csv`
- UTF-8 BOM vorhanden (für Excel)
- Spalten: Datum, Wochentag, Status, Notiz
- Zusammenfassung: Gesamttage, Steuerersparnis
- Deutsches Datumsformat (TT.MM.JJJJ)

**Konsistenzcheck:**
- [ ] Öffnet CSV in Excel korrekt (Umlaute)?
- [ ] Sind Urlaub/Krank-Tage separat ausgewiesen?
- [ ] PDF hat rechtliche Referenz (§ 4 Abs. 5)?

---

## BLOCK 7: Konsistenz der Zählung

### T-15 Counter vs. Kalender — Synchronität
**Personas:** ALLE  

**Schritte:**
1. 10 HO-Tage über Detail-Sheets eintragen
2. Counter oben notieren
3. Manuell Kalender-Zellen zählen

**Erwartetes Ergebnis:**
- Counter = Anzahl grüner Zellen im Kalender (exakt)

**Konsistenzcheck:**
- [ ] Gilt nur für aktuelles Steuerjahr?
- [ ] Urlaub/Krank-Tage nicht im Counter?
- [ ] Feiertage nicht im Counter?

---

### T-16 Steuerersparnis-Berechnung
**Personas:** A2, C5  

**Formel:** HO-Tage × €6 (max 210 × €6 = €1.260)

**Schritte:**
1. 1 HO-Tag → €6,00?
2. 10 HO-Tage → €60,00?
3. 210 HO-Tage → €1.260,00?
4. 211 HO-Tage → noch €1.260,00?

**Konsistenzcheck:**
- [ ] Österreich-Nutzer (€3/Tag, max €300) bekommen falsche Info → kein Länder-Switch
- [ ] Schweiz hat andere Regelung → App geht nicht darauf ein

---

## BLOCK 8: Einstellungen & Persistenz

### T-17 Einstellungen nach App-Neustart
**Personas:** A3, C2  

**Schritte:**
1. Arbeitstage auf Mo–Do setzen
2. Standard-HO: Mo + Mi
3. App komplett schließen (Swipe aus App-Switcher)
4. Neu öffnen

**Erwartetes Ergebnis:**
- Arbeitstage noch Mo–Do
- Standard-HO noch Mo + Mi
- Alle eingetragenen Tage noch vorhanden

---

### T-18 Daten nach iOS-Update / App-Update
**Personas:** C2, D4  
**Voraussetzung:** 100 Tage eingetragen, App-Update installieren

**Erwartetes Ergebnis:**
- Alle Daten erhalten (SwiftData Migration)
- Keine Fehlermeldung
- Settings erhalten

**BUG-RISIKO:** SwiftData Schema-Migrationen bei App-Updates — kein Test dafür vorhanden

---

## Zusammenfassung: Kritische Bugs & Feature Gaps

| # | Befund | Schwere | Persona |
|---|---|---|---|
| FG-01 | Standard-HO-Tage werden nicht automatisch angewendet | Hoch | A1, A5, B4 |
| FG-02 | 210-Tage-Grenze wird möglicherweise nicht gedeckelt | Hoch | A2, B4 |
| FG-03 | Keine automatische Feiertagserkennung | Mittel | B4, D3 |
| FG-04 | Kein Länder-Switch (AT/CH) | Mittel | B5 |
| FG-05 | Kein Bulk-Import / Wochenmuster rückwirkend | Mittel | C4 |
| FG-06 | Widget nicht implementiert (nur Infrastruktur) | Hoch | C3 |
| FG-07 | Kein CSV-Import für App-Wechsler | Niedrig | D4 |
| FG-08 | Keine Mehrjahres-Ansicht | Niedrig | D2 |
| B-01 | Planungsmodus: Unklar ob geplante Tage gezählt werden | Mittel | A1 |
| B-02 | SwiftData-Migration bei App-Updates ungetestet | Hoch | C2 |

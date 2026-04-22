# 05 — Zahlungsbereitschaft: Framework & Interview-Leitfaden

---

## Hypothesen zur Zahlungsbereitschaft

### H1: Der Steuerspar-Kontext erhöht Zahlungsbereitschaft drastisch
Ein Nutzer, der €1.260 Steuerersparnis sieht, zahlt €2,99 ohne Nachzudenken.  
**Messbar:** Conversion-Rate bei Nutzern mit >50 HO-Tagen vs. <10 Tagen.

### H2: Der Export-Moment ist der optimale Paywall-Trigger
Nutzer zahlen, wenn sie kurz vor der Steuererklärung sind (Feb–Juli).  
**Messbar:** Saisonale Kaufkurve analysieren.

### H3: Einmalpreis schlägt Subscription für diese Zielgruppe
Steuerwerkzeuge sind Jahrestool, keine Daily-App — Subscription wirkt fehl am Platz.  
**Testbar:** A/B-Test Einmalpreis vs. Jahreszugang.

### H4: Widget allein rechtfertigt Kauf für Power-User (C3)
Wenn Widget implementiert ist, gibt es eine Segment, die NUR dafür kaufen.  
**Messbar:** Separate Widget-Paywall testen.

---

## Interview-Leitfaden (15-minütiges User Interview)

### Vorbereitung
- Testgerät mit der App installiert
- Demonutzer mit 30–100 HO-Tagen vorbereitet
- Kein erklären, nur beobachten und nachfragen

### Abschnitt 1: Kontext (3 min)

1. "Wie verfolgst du gerade deine Homeoffice-Tage?"  
   → Herausfinden: Excel, Papier, Kalender, andere App, gar nicht

2. "Machst du das für die Steuererklärung?"  
   → Herausfinden: Bewusstsein über HO-Pauschale

3. "Wie viele HO-Tage hattest du letztes Jahr ungefähr?"  
   → Herausfinden: Relevanz für Nutzer (viele HO = hohe Motivation)

### Abschnitt 2: App-Test (7 min)

**Task 1 — Erstnutzung:**  
"Öffne die App und zeig mir, wie du heute als Homeoffice-Tag eintragen würdest."  
→ Beobachten: Versteht Nutzer Toggle sofort? Sucht er etwas?

**Task 2 — Vergangene Tage:**  
"Du hast letzte Woche Montag und Dienstag im HO gearbeitet — trag das nach."  
→ Beobachten: Findet Kalender? Versteht Detail-Sheet?

**Task 3 — Urlaub/Feiertag:**  
"Du hast nächste Woche Urlaub. Wie würdest du das eintragen?"  
→ Beobachten: Findet Planning Mode? Versteht Spezialtypen?

**Task 4 — Export:**  
"Du willst die Daten für deine Steuererklärung exportieren."  
→ Beobachten: Findet Export? Wie reagiert er auf Paywall?

### Abschnitt 3: Zahlungsbereitschaft (5 min)

**Frage 1 — Offener Einstieg:**  
"Was würdest du sagen — für was wärst du bereit zu zahlen, für was nicht?"

**Frage 2 — Konkret zum Export:**  
"Für den Export zahlst du einmalig €2,99. Was denkst du?"  
→ Folge-Frage wenn "zu teuer": "Welcher Preis wäre okay?"  
→ Folge-Frage wenn "okay": "Was müsste die App noch können damit €4,99 okay wäre?"

**Frage 3 — Features bewerten lassen:**  
"Ich zeige dir eine Liste von Features. Sag mir: Free, Premium, oder 'brauche ich nicht'."

| Feature | Einschätzung des Nutzers |
|---|---|
| Tage tracken (Toggle) | |
| Monatskalender | |
| Jahres-Counter + Steuerrechner | |
| CSV-Export | |
| PDF-Export (mit Gesetz-Referenz) | |
| Home Screen Widget | |
| Wochenplanung (Zukunft markieren) | |
| Auto-Regel (Mo+Mi immer HO) | |
| Mehrere Profile (Freelancer) | |
| Feiertagserkennung | |
| Push-Benachrichtigung Abends | |
| Apple Watch Complication | |

**Frage 4 — Preismodell:**  
"Was bevorzugst du: Einmalig €2,99, oder €0,99/Monat, oder €4,99/Jahr?"

**Frage 5 — Dealbreaker:**  
"Was müsste die App können, damit du sie sofort deinstallierst?"

---

## Quantitatives Survey (für größere Gruppe)

**Methode:** App-Store-Umfrage oder In-App nach 3+ Tagen Nutzung

### Fragen

**Q1:** Wie viele Tage arbeitest du pro Woche im Homeoffice?  
○ Keinen ○ 1 Tag ○ 2 Tage ○ 3 Tage ○ 4 Tage ○ Vollzeit (5+)

**Q2:** Was ist dein Hauptgrund für die Nutzung?  
○ Steuererklärung ○ Arbeitgeber-Nachweis ○ Überblick behalten ○ Sonstiges

**Q3:** Hast du Premium bereits gekauft?  
○ Ja ○ Nein, aber ich würde ○ Nein, und ich würde nicht

**Q4 (wenn Nein):** Warum nicht?  
○ Zu teuer ○ Brauche Export nicht ○ Nicht gewusst dass es Premium gibt ○ Warte auf mehr Features ○ Nutze App zu selten

**Q5:** Welches Feature würde dich am ehesten zum Kauf bewegen?  
○ CSV-Export ○ PDF-Export ○ Widget ○ Auto-Wochenmuster ○ Mehrere Profile ○ Feiertagserkennung

**Q6:** Welchen Preis hältst du für fair?  
○ Kostenlos ○ €0,99 ○ €1,99 ○ €2,99 (aktuell) ○ €4,99 ○ Mehr

**Q7:** Würdest du ein Jahresabo bevorzugen?  
○ Ja, für €0,99/Monat ○ Ja, für €2,99/Jahr ○ Nein, Einmalpreis bevorzugt

---

## Erwartete Ergebnisse nach Persona

| Persona | Kaufwahrscheinlichkeit | Haupttrigger |
|---|---|---|
| A1 (IT-Entwickler) | 75% | CSV für ELSTER |
| A2 (Controllerin) | 90% | PDF + Vollständigkeit |
| A3 (Vergesslicher) | 30% | Wenn Reminder vorhanden |
| A4 (Regel-Hopper) | 60% | Wenn Bulk-Select reicht |
| A5 (Teilzeit) | 50% | Free reicht meist |
| B1 (Hybrid-Pendler) | 80% | Bürotage-Tracking |
| B2 (Freelancer) | 70% | Mehrere Profile |
| B3 (Teamleiter) | 85% | PDF für HR |
| B4 (Vollzeit-Remote) | 65% | Auto-Regel |
| B5 (Grenzgänger AT) | 40% | Falscher Betrag |
| C1 (Einmal/Jahr) | 20% | Nur Export |
| C2 (Datenschutz) | 55% | Lokale Daten bestätigt |
| C3 (Widget-User) | 80% | Widget (sobald implementiert) |
| C4 (Late Adopter) | 35% | Bulk-Import fehlt |
| C5 (Skeptiker) | 25% | Braucht €-Demo |

**Gewichteter Schnitt (grobe Schätzung):** ~57% Kaufrate unter Nutzern mit >20 HO-Tagen

---

## Conversion-Optimierungsempfehlungen

### 1. Counter früher pushen
Zeige noch im Onboarding: "Du arbeitest 3 Tage/Woche HO → das ergibt **~€1.080 Steuerersparnis/Jahr**"  
→ Sofortiger Aha-Moment, bevor Nutzer überhaupt trackt

### 2. Paywall zu richtigem Zeitpunkt zeigen
**Schlecht:** Paywall bei jedem Export-Klick (Nutzer mit 5 Tagen = egal)  
**Gut:** Paywall mit Counter "Du hast €300 Ersparnis angehäuft — jetzt für €2,99 exportieren"

### 3. Gratis-Preview des Exports
Zeige erste 5 Tage des CSV ohne Paywall → Nutzer sieht den Wert → zahlt dann

### 4. Steuersaison-Push
In-App Banner Feb–April: "Steuererklärung naht — exportiere jetzt deine HO-Tage"

### 5. Social Proof
"Bereits X Nutzer haben ihre Steuererstattung beantragt" (wenn Daten vorhanden)

# 03 — Premium-Strategie: Was ist Free, was ist Premium?

## Die Kernfrage

> Macht es Sinn, Tage zusammenzählen, CSV-Export, Wochenplanung und Regeln wie regelmäßige HO-Tage als Premium anzubieten?

**Kurze Antwort: Teilweise — aber die Abgrenzung muss schärfer sein.**

---

## Analyse: Jedes Feature einzeln bewertet

### 1. Tage zusammenzählen (Counter)
**Aktueller Status:** Free  
**Empfehlung: Free halten — das ist das Kern-Value-Prop**

Begründung:
- Der Counter ist der einzige sofortige "Aha"-Moment ("Oh, ich spare schon €78 Steuern!")
- Wenn Nutzer den Counter nicht sehen, gibt es keinen Anreiz täglich zu tracken
- Ohne tägliche Nutzung stirbt die App
- Vergleich: Fitness-Apps zeigen Schritte immer gratis — das ist der Hook

**Fazit:** Counter hinter Paywall = Conversion-Killer. Niemals.

---

### 2. CSV-Export
**Aktueller Status:** Premium ✓  
**Empfehlung: Premium — richtige Entscheidung**

Begründung:
- Nutzer der CSV braucht haben bereits Tage eingetragen → hohes Engagement → höhere Zahlungsbereitschaft
- Der Export-Moment ist der natürliche Conversion-Point: kurz vor der Steuererklärung
- Nutzer fühlt in diesem Moment den konkreten Wert (spart €1.260 → zahlt €3 → klar)
- Timing: Steuersaison (Febr.–Juli) = Hauptumsatz

**Best Practice:**
- Kleiner "vorschau" Export (z.B. erste 5 Tage) gratis zeigen → dann Paywall
- Für ELSTER-Nutzer: "Zur Steuererklärung exportieren" als CTA

---

### 3. PDF-Export
**Aktueller Status:** Premium ✓  
**Empfehlung: Premium — aber als Teil desselben €2,99-Pakets**

Begründung:
- PDF ist für HR-Nachweis (B3) wertvoll — höhere Zahlungsbereitschaft dieser Gruppe
- Rechtliche Referenz im PDF (§ 4 EStG) macht es zu einem professionellen Dokument
- Nicht genug für eigenen Preis, aber stärkt das Premium-Paket

---

### 4. Wochenplanung / Vorab-Markierung (Planning Mode)
**Aktueller Status:** Free (!)  
**Empfehlung: SPLITTEN — Basic Planning Free, Advanced Planning Premium**

Begründung:
- Einfaches Antippen eines zukünftigen Tages: **Free** (kaum zusätzlicher Wert)
- Drag-to-Select für mehrere Tage vorab: **Free** (Kernfunktionalität)
- **Premium**: Wochenmuster-Template ("jeden Montag und Mittwoch als HO vorplanen")
- **Premium**: Monatsplanung per Klick ("ganze Woche als HO markieren")

**Warum Planning Mode wertvoll für Premium ist:**
- Spart Zeit (statt 20 Einzelklicks → 1 Klick)
- Schafft Gewohnheit → erhöht Retention → erhöht Zahlungsbereitschaft

---

### 5. Regelmäßige HO-Tage als Regel (Wochenmuster)
**Aktueller Status:** Konfigurierbar in Settings, aber KEIN Auto-Fill implementiert!  
**Empfehlung: Diese Funktion ist NICHT implementiert — das ist ein kritischer Gap**

**Was Nutzer erwarten:**
- "Ich gehe jeden Mo + Mi ins HO → App trägt das automatisch ein"
- "Ich muss nur Ausnahmen korrigieren, nicht alle Tage einzeln"

**Was die App tatsächlich tut:**
- Speichert Präferenz → aber trägt NICHTS automatisch ein
- Nutzer muss trotzdem jeden Tag manuell toggeln

**Empfehlung für Feature-Design:**

```
FREE:     Manual toggle jeden Tag
FREE:     Planning Mode (Zukunftstage einzeln markieren)
PREMIUM:  Smart-Fill — "Mein HO-Muster auf ganzen Monat anwenden"
PREMIUM:  Auto-Regel — "Jeden Mo/Mi als HO vorbelegen"
PREMIUM:  Ausnahme-Modus — Regel aktiv, Ausnahmen per Tap korrigieren
```

Das wäre das stärkste Premium-Argument, weil es echten Arbeitsaufwand spart.

---

### 6. Widget
**Aktueller Status:** Geplant, nicht implementiert  
**Empfehlung: Premium (sobald implementiert)**

Begründung:
- Persona C3 (Widget-Nutzer) würde dafür alleine zahlen
- Widget = schnellster Toggle-Flow → Premium-Komfort-Feature
- Klassisches "Power User"-Feature

---

### 7. Mehrjahres-Ansicht
**Aktueller Status:** Nicht implementiert  
**Empfehlung: Premium**

---

### 8. Mehrere Profile (Freelancer)
**Aktueller Status:** Geplant, nicht implementiert  
**Empfehlung: Premium (und eigener Preis rechtfertigbar)**

---

## Empfohlene Free/Premium-Aufteilung

### FREE (muss immer bleiben)
| Feature | Begründung |
|---|---|
| Tages-Toggle (heute) | Core Loop — ohne das kein Engagement |
| Counter (Tage + €) | Value Prop — motiviert zur Nutzung |
| Monatskalender | Übersicht — essentiell |
| Vergangene Tage bearbeiten | Grundnutzen |
| Spezielle Tage (Urlaub etc.) | Vollständigkeit |
| Planning Mode (einzelne Tage vorab) | Grundnutzen |
| Settings: Arbeitstage konfigurieren | Notwendig für korrekte Nutzung |
| Einmal-Onboarding | Notwendig |

### PREMIUM (€2,99/Jahr — Jahres-Abo, aktuelle Strategie)
| Feature | Stärke | Status |
|---|---|---|
| CSV-Export | ★★★★★ | Implementiert (theoretisch) |
| PDF-Export (mit § 4 EStG) | ★★★★☆ | Implementiert (theoretisch) |
| Widget (Home Screen) | ★★★★☆ | Nicht implementiert |
| Auto-Fill Wochenmuster | ★★★★★ | Nicht implementiert |
| Mehrere Profile | ★★★☆☆ | Nicht implementiert |
| Mehrjahres-Ansicht | ★★★☆☆ | Nicht implementiert |

### DISKUTABEL (könnte Free oder Premium sein)
| Feature | Argument Free | Argument Premium |
|---|---|---|
| Drag-to-Select | Spart Aufwand, sollte normal sein | Komfort-Feature |
| Benachrichtigungen/Reminder | Retention-Tool → hilft App | Komfort-Feature |
| Feiertagserkennung | Macht App vollständig | Zeitersparnis |

---

## Zahlungsbereitschaft vs. Nutzen-Matrix

```
         │ Niedrig        │ Mittel          │ Hoch
─────────┼────────────────┼─────────────────┼──────────────────
Niedriger│ C1 (Lehrer)    │ A3 (Vergesslich)│ —
Nutzen   │ C5 (Skeptiker) │                 │
─────────┼────────────────┼─────────────────┼──────────────────
Mittlerer│ —              │ A1 (Standard)   │ A4 (Regel-Hopper)
Nutzen   │                │ A5 (Teilzeit)   │ C3 (Widget)
─────────┼────────────────┼─────────────────┼──────────────────
Hoher    │ D1 (Elternzeit)│ B5 (Grenzgänger)│ A2 (Optimiererin)
Nutzen   │                │ C4 (Late Adopt) │ B1–B3 (Komplex)
         │                │                 │ D2 (Mehrjahre)
```

**Kerninsight:** Die Nutzer mit höchster Zahlungsbereitschaft (A2, B1-B3) sind auch die, die den Export brauchen. Der Paywall-Moment ist perfekt platziert.

---

## Preisgestaltung — Empfehlung

**Aktuell: €2,99/Jahr (Jahres-Abo)**

Bewertung: **Gut — klares Modell, niedriger Einstiegspreis**

| Szenario | Preis | Begründung |
|---|---|---|
| Aktuell | €2,99/Jahr | Impulskauf-freundlich, klares Jahres-Abo |
| Alternativ Phase 2 | €4,99/Jahr | Nach Widget + Auto-Fill implementiert, 67% mehr Umsatz |
| Nicht gewählt | Einmalkauf | Würde konfuses Kaufmodell erzeugen; kein automatischer Restore |

**Empfehlung:**  
Jahres-Abo bei €2,99/Jahr belassen bis Widget + Auto-Fill implementiert sind.  
Danach auf €4,99/Jahr erhöhen — Bestandsabonnenten bleiben auf altem Preis (Grandfathering via Apple).

---

## Fazit: Macht die aktuelle Premium-Strategie Sinn?

**Weitgehend ja. Die offenen Punkte:**

1. **Auto-Fill Wochenmuster ist das stärkste Premium-Argument** — ist aber nicht implementiert
2. **Widget ist versprochen im Paywall** — ist aber nicht implementiert → rechtliches Risiko (Apple Guideline 3.1.1)
3. **Planning Mode ist Free** — könnte als "Advanced Planning" teilweise Premium sein
4. **Feiertagserkennung fehlt** — macht Nutzer manuell abhängig

**Die Stärken:**
1. Export zum richtigen Conversion-Moment ist exzellent
2. Jahres-Abo bei €2,99/Jahr ist niedrigste Einstiegsschwelle — kein Lock-in-Gefühl
3. Automatischer Restore über Apple ID — kein Support-Aufwand
4. Counter + Toggle gratis hält Engagement hoch

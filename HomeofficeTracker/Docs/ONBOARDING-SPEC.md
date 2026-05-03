# ONBOARDING-SPEC.md — Onboarding-Anforderungen

> Adressiert: **Case 3 (Monika – technikferne Nutzerin)** und **Case 4 (Florian – Selbstständiger ohne Klarheit über Anspruch)**  
> Referenz: UX-Audit-UserUsecases.md, RECHTSLAGE.md

---

## Ziel des Onboardings

Das Onboarding hat **drei Aufgaben**, in dieser Priorität:

1. **Verständnis schaffen:** Der Nutzer versteht in 30 Sekunden, was die App tut und warum sie für ihn relevant ist (oder nicht).
2. **Eligibility prüfen:** Nutzer erkennen sofort ob die Homeoffice-Pauschale auf sie zutrifft — und in welcher Form. Kein Nutzer soll die App wochenlang benutzen und dann feststellen, dass sie für seinen Fall nicht relevant ist.
3. **Reibungslosen Start ermöglichen:** Der Nutzer kann sofort loslegen, rückwirkend Tage eintragen, und versteht die Kernfunktion nach dem Onboarding ohne Rückfragen.

**Was das Onboarding NICHT tut:** Paywall zeigen. Die einzige erlaubte Erwähnung von Premium im Onboarding ist ein dezenter Hinweis im letzten Screen ("Export ist ein Premium-Feature"). Kein Kauf-Prompt während des Onboardings.

---

## Screen-Sequenz

### Screen 1 — Wert-Proposition (max. 3 Sekunden Lesezeit)

**Headline:** „Bis zu 1.260 € Steuerersparnis — einfach tracken."  
**Subline:** „Die Homeoffice-Pauschale: 6 € pro Tag, max. 210 Tage im Jahr."  
**Visual:** Große, schlichte Illustration — Haus + €-Zeichen, oder ein animierter Betragszähler  
**CTA:** „Weiter" (kein Skip)

**Designprinzip:** Kein Text-Wall. Maximal 2 Sätze. Die Zahl 1.260 € muss dominieren — das ist der emotionale Hook.

**Pflicht:** Die Beträge kommen aus `LegalConfiguration.current` — niemals hardcoded. Wenn das Gesetz sich ändert, aktualisiert sich dieser Screen automatisch.

```swift
// Beispiel-Implementierung
Text("Bis zu \(LegalConfiguration.current.maxAmount.formatted(.currency(code: "EUR"))) Steuerersparnis")
```

---

### Screen 2 — Kurzerklärung (für Monika)

**Headline:** „Was ist die Homeoffice-Pauschale?"  
**Inhalt (als einfacher Fließtext, kein Bullet-Point-Wall):**

> „Wenn du von zuhause arbeitest, kannst du jeden Homeoffice-Tag mit 6 € von der Steuer absetzen — ohne Belege, ohne Nachweise. Einfach Tage tracken, am Jahresende exportieren, fertig."

**Wichtig:** Kein Finanzjargon. Kein Verweis auf EStG-Paragraphen. Die Steuerberaterin (Sandra) liest das nicht — die kennt es. Monika soll es verstehen.

**Optional-Link:** „Mehr erfahren →" öffnet einen In-App-Sheet mit ausführlicherer Erklärung (nicht externe URL — spart die App-Store-Review-Diskussion und hält Nutzer in der App).

---

### Screen 3 — Eligibility-Check (für Florian)

**Headline:** „Für wen gilt die Pauschale?"  
**Subline:** „Kurze Frage, damit die App dir korrekte Hinweise geben kann."

**Auswahloptionen (Radio-Buttons, große Touch-Targets):**

```
○  Arbeitnehmer / Angestellter
○  Selbstständig / Freiberufler
○  Beamter / Öffentlicher Dienst
○  Ich bin unsicher
```

**Logik pro Auswahl:**

**→ Arbeitnehmer:**  
Kein weiterer Hinweis nötig. Das ist der Hauptfall. Direkt zu Screen 4.

**→ Selbstständig / Freiberufler:**  
Zeige einen kleinen Info-Banner (kein Abbruch, kein Alarm):

> „✓ Auch als Selbstständiger kannst du die Homeoffice-Pauschale nutzen — als Betriebsausgabe (§ 4 EStG). Hast du bereits ein steuerlich anerkanntes häusliches Arbeitszimmer? Dann solltest du mit deinem Steuerberater klären, welche Variante günstiger ist."

Dann: „Trotzdem loslegen →" — der Nutzer kommt zur App. Kein Ausschluss.

**→ Beamter:**  
Kein Banner nötig. Direkt zu Screen 4.

**→ Ich bin unsicher:**  
Kurztext:

> „Die Pauschale gilt für fast alle, die von zuhause arbeiten — egal ob angestellt oder selbstständig. Im Zweifel einfach tracken und beim Steuerberater nachfragen."

Dann: „Weiter →"

**Persistenz:** Die Auswahl wird in `@AppStorage("userEmploymentType")` gespeichert. Sie beeinflusst den Haftungshinweis im PDF-Export (Arbeitnehmer → Werbungskosten / Selbstständige → Betriebsausgaben) und kann in Einstellungen geändert werden.

**Warum dieser Screen:** Verhindert 1-Stern-Bewertungen von Selbstständigen die denken, die App sei für sie nutzlos. Zeigt Kompetenz in der Zielgruppe. Dauert 5 Sekunden.

---

### Screen 4 — Startdatum (für Monika, kritisch)

**Headline:** „Ab wann möchtest du tracken?"

**Optionen:**

```
● Heute (12. April 2026)
○ Rückwirkend ab 1. Januar 2026
○ Anderes Datum wählen  →  [DatePicker]
```

**Defaultauswahl:** „Rückwirkend ab 1. Januar [aktuelles Jahr]" — das ist die häufigste sinnvolle Wahl, weil die meisten Nutzer die App nicht am 1. Januar installieren.

**Hinweis unter den Optionen** (klein, grau):

> „Du kannst jederzeit vergangene Tage nachtragen — tippe einfach auf ein Datum im Kalender."

**Warum:** Wenn Monika die App im März installiert und nicht weiß, dass sie Januar/Februar nachtragen kann, verliert sie 2 Monate potenzielle Ersparnis. Das ist ein echter finanzieller Schaden durch schlechte UX.

---

### Screen 5 — Erinnerungen (Opt-in, nicht erzwungen)

**Headline:** „Erinnerung einrichten?"  
**Subline:** „Damit du keinen Tag vergisst."

**Toggle:** „Täglich erinnern" (default: ON)  
**Zeitauswahl:** Schieberegler für Uhrzeit, default 17:30 Uhr  
**Vorschau der Notification:** „Hast du heute im Homeoffice gearbeitet? Eintrag dauert 1 Sekunde."

**CTA:** „Aktivieren" / „Jetzt nicht" (beide gut sichtbar, kein Dark Pattern)

Wenn „Aktivieren": sofort iOS-Permission-Dialog triggern.  
Wenn „Jetzt nicht": Kein erneutes Nachfragen für 30 Tage. Dann ein In-App-Banner (nicht Push).

**Begründung:** Erinnerungen sind der wichtigste Retention-Hebel. Sie gehören in den Free-Tier. Ohne sie verlieren Nutzer die Gewohnheit nach 2 Wochen und zahlen nicht.

---

### Screen 6 — Los geht's (letzter Screen)

**Headline:** „Alles bereit."  
**Inhalt:**

> „Tippe auf einen Tag um ihn zu loggen. Deine Ersparnis aktualisiert sich sofort.  
> Export (PDF/CSV) ist ein Premium-Feature — probiere die App erst aus."

**CTA:** „App starten →" (großer, prominenter Button)

Kein Kauf-Prompt. Kein „Premium für 2,99€"-Banner. Rein.

---

## Rückdatierung — UX-Anforderungen (für Monika)

Die Rückdatierung ist keine Edge-Case-Funktion — sie ist für die Mehrheit der Nutzer die erste echte Interaktion.

**Anforderungen:**
- Im Monatskalender: Tap auf beliebiges **vergangenes** Datum → Sofortiger Toggle (ohne Bestätigungsdialog)
- Visuelles Feedback: Datum färbt sich sofort grün, Counter und Betrag aktualisieren sich sichtbar (Animation)
- Kein Modal, kein „Sind Sie sicher?"-Dialog für Standard-Einträge
- Löschen: Long-Press auf grünen Tag → Kontextmenü „Tag entfernen" (mit Bestätigung)
- Zukünftige Daten: Grau, nicht tappbar, kein Fehler — einfach deaktiviert

**Fehlervermeidung für Monika:** Wenn sie versehentlich einen Tag antippt, muss sie ihn sofort wieder abwählen können — selber Tap, kein Suchen nach einer Löschfunktion.

---

## Texte für In-App-Haftungshinweise

Alle Texte kommen aus einer zentralen `Strings`-Datei (Localizable.strings / String Catalog). Kein Haftungstext ist hardcoded in einer View.

### Kurzversion (Onboarding Screen 1 oder 2, 1 Satz)
> „Die App hilft beim Tracken — die steuerliche Prüfung liegt bei dir oder deinem Steuerberater."

### Vollversion (Einstellungen → Über die App)
> „Diese App dient der persönlichen Erfassung und Berechnung von Homeoffice-Tagen für die Homeoffice-Pauschale nach § 4 Abs. 5 Nr. 6c EStG. Sie ersetzt keine individuelle Steuerberatung. Die steuerliche Anerkennung der eingetragenen Tage obliegt dem Nutzer. Gesetzliche Werte (Tagessatz, Maximaltage) werden bei Änderungen durch App-Updates angepasst. Stand: [LegalConfiguration.current.verifiedOn]."

### Export-Footer (kompakt, im PDF)
> „Erstellt mit Homeoffice-Tracker · Alle Angaben ohne Gewähr · Steuerliche Prüfung durch Steuerberater empfohlen · Rechtliche Grundlage: § 4 Abs. 5 Nr. 6c EStG"

---

## Acceptance Criteria

Onboarding ist abgenommen wenn:

- [ ] Screen 1 zeigt Beträge aus `LegalConfiguration.current` (nicht hardcoded)
- [ ] Screen 2 enthält einen verständlichen Erklärungstext ohne Fachjargon
- [ ] Screen 3 hat alle vier Eligibility-Optionen mit korrekter Folge-Logik
- [ ] Selbstständige sehen einen Info-Banner, werden aber NICHT ausgeschlossen
- [ ] Screen 4 bietet „Rückwirkend ab 1. Januar" als Default an
- [ ] Screen 5: Notification-Opt-in, kein Dark Pattern, keine Paywall
- [ ] Screen 6: Kein Kauf-Prompt
- [ ] Rückdatierung im Kalender: Ein Tap = sofortiger Toggle, kein Dialog
- [ ] Long-Press auf Eintrag: Löschen mit Bestätigung möglich
- [ ] Haftungshinweis in Onboarding, Settings und Export-PDF vorhanden
- [ ] Alle Texte über String Catalog lokalisierbar (de/de-AT/de-CH)

---

*Kanonischer Pfad: `Docs/ONBOARDING-SPEC.md` | Verknüpft mit: RECHTSLAGE.md, PDF-EXPORT-SPEC.md, UX-Audit-UserUsecases.md*

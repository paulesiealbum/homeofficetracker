# UX-Audit & User Use Cases – Homeoffice-Tracker
**Datum:** April 2026 | **Reviewer:** Claude (kritisch, anspruchsvoll)

---

## Status der Maßnahmen

| Persona | Thema | Status | Dokument |
|---------|-------|--------|----------|
| Case 1 – Sandra (Steuerberaterin) | PDF-Inhalt, Rechtslage | ✅ Spezifiziert | [PDF-EXPORT-SPEC.md](PDF-EXPORT-SPEC.md) · [RECHTSLAGE.md](RECHTSLAGE.md) |
| Case 2 – Tobias (Power User) | Widget, Fortschritts-Anker | ⏳ Zurückgestellt | Widget-Phase später |
| Case 3 – Monika (Technikfern) | Onboarding, Rückdatierung | ✅ Spezifiziert | [ONBOARDING-SPEC.md](ONBOARDING-SPEC.md) |
| Case 4 – Florian (Freelancer) | Eligibility-Check | ✅ Spezifiziert | [ONBOARDING-SPEC.md](ONBOARDING-SPEC.md) |

**Oberste Priorität der App: Rechtliche Korrektheit.** Alle steuerrechtlichen Werte und Regeln sind in [RECHTSLAGE.md](RECHTSLAGE.md) und `LegalConfiguration.swift` als Single Source of Truth verankert. Jährliche Update-Pflicht bis 31. Januar.

---

## Methodik

Vier reale, anspruchsvolle Nutzer-Personas testen die App end-to-end: von der App-Store-Beschreibung über das erste Öffnen bis zum erfolgreichen Steuer-Export. Bewertet werden Onboarding, tägliche Nutzung, Qualität der Ergebnisse und Design/UI. Jede Persona beleuchtet eine andere Risikozone des Produkts.

---

## Persona 1 — Sandra, 34, Steuerberaterin (München) ✅ Adressiert → [PDF-EXPORT-SPEC.md](PDF-EXPORT-SPEC.md) · [RECHTSLAGE.md](RECHTSLAGE.md)

### Profil
Arbeitet 3–4 Tage/Woche im Homeoffice, kennt die Homeoffice-Pauschale in- und auswendig. Prüft Apps für ihre Klienten bevor sie Empfehlungen ausspricht. Sehr kritisch gegenüber rechtlichen Ungenauigkeiten. Nutzt: iPhone 15 Pro, iCloud Drive, ELSTER.

### Ihre User Journey

**App Store:** Sandra liest die Beschreibung genau. Erste Frage: Gilt das für 2024 *und* 2025? Die Erhöhung von 5€ auf 6€ und das neue Tageslimit (max. 210 Tage statt früher 120) muss klar kommuniziert sein. Wenn die Beschreibung veraltet ist oder beides vermischt, Download-Abbruch.

**Onboarding:** Sandra überspringt kein Onboarding-Screen – sie liest alles. Stolperstein: Wenn beim Einrichten gefragt wird „Wann fängst du an zu tracken?" fehlt die Möglichkeit, rückwirkend für Januar–März Tage nachzutragen. Sie öffnet die App im März, will aber ab 1. Januar erfassen. Kann sie das?

**Durchführung:** Sandra loggt einen Tag, schaut dann sofort auf die Berechnung. Sie rechnet im Kopf nach: 1 Tag × 6€ = 6€. Zeigt die App das? Und wenn ja: Zeigt sie auch den *maximalen Jahresbetrag* (210 × 6 = 1.260€) als Kontext? Fehlt dieser Rahmen, fehlt der emotionale Anker.

**Export / Steuern:** Das ist der Kern für Sandra. Sie braucht ein PDF das sie ihren Klienten schicken kann. Kritisch: Steht auf dem PDF das korrekte Steuerjahr? Sind die Tage einzeln aufgelistet (mit Datum) oder nur als Summe? Ohne Einzeldaten ist das Dokument wertlos für das Finanzamt.

**Critical Drop-Off-Risiko:** Sandra empfiehlt die App *nicht weiter*, wenn:
- Das PDF nur eine Gesamtzahl zeigt, keine Datumsliste
- Rechtliche Begriffe falsch oder veraltet sind (z.B. noch „120 Tage" statt 210)
- Kein Hinweis erscheint, was passiert wenn man Urlaubs- oder Krankheitstage eingetragen hat (dürfen diese nicht mitgezählt werden)

**Verbesserungs-Empfehlungen für Sandra:**
- PDF muss tagesgenaue Auflistung enthalten, exportierbar nach Monat oder Gesamtjahr
- Korrekte Rechtslage für das aktuelle Jahr prominent einblenden (versionierbar bei gesetzlichen Änderungen)
- Hinweis: Krankheits-, Urlaubs- und Dienstreisetage zählen nicht als Homeoffice-Tag
- Rückwirkende Eingabe vom ersten Appstart ohne Umwege ermöglichen

---

## Persona 2 — Tobias, 28, Software Engineer (Berlin)

### Profil
Remote-first, 5 Tage/Woche Homeoffice. Nutzt Kalender-Integrationen, Widgets, Shortcuts. Hat drei ähnliche Apps ausprobiert und alle wieder gelöscht. Erwartet Zero-Friction-UX. Kaufentscheidung fällt in den ersten 90 Sekunden.

### Seine User Journey

**App Store:** Tobias schaut sofort auf die Screenshots. Er will ein Widget sehen und einen klaren Zähler. Wenn die Screenshots nur generische iPhones mit bunten Blobs zeigen, ist er weg.

**Onboarding:** Tobias tippt beim ersten Screen auf „Weiter" ohne zu lesen. Wenn Screen 2 schon einen Call-to-Action für den Kauf zeigt, schließt er die App. Er will die App *erleben* bevor er zahlt. Onboarding-Paywall im zweiten Schritt = harter Absprung.

**Erster Tap:** Er will sofort auf dem Home-Screen einen großen Button sehen: **„Heute war Homeoffice"**. One-tap-Tracking ist nicht nice-to-have, sondern Kernfunktion. Wenn er erst ein Datum auswählen, eine Kategorie wählen oder eine Notiz eingeben muss, ist das zu viel.

**Widget:** Tobias installiert das Widget am zweiten Tag. Wenn das Widget nur eine statische Zahl zeigt (kein interaktiver Tap zum Loggen direkt aus dem Widget), ist er enttäuscht. iOS 17+ erlaubt Interactive Widgets – das muss genutzt werden.

**Halbzeit-Check (Juli):** Tobias schaut nach, wie viele Tage er noch tracken könnte. Zeigt die App: „Du hast noch 95 Tage übrig (noch 570€ möglich)"? Dieser Fortschritts-Anker ist für Power-User extrem wertvoll.

**Critical Drop-Off-Risiko:** Tobias zahlt nicht, wenn:
- Das Widget nicht interaktiv ist (kein One-Tap-Log aus Widget)
- Keine Jahresfortschritts-Ansicht (wie viel % des Maximums bin ich?)
- Kein Shortcut / App Intent (Siri, Shortcuts-App-Integration)

**Verbesserungs-Empfehlungen für Tobias:**
- Interactive Widget: Ein Tap = heutiger Tag als Homeoffice geloggt (mit Confirmation-Haptic)
- Fortschrittsbalken auf dem Home-Screen: „X von 210 Tagen – noch Y€ möglich"
- App Intent für Shortcuts.app: „Log today as home office"
- Keine Paywall vor dem ersten Erlebnis. Erst Wert zeigen, dann Kauf anbieten

---

## Persona 3 — Monika, 52, Verwaltungsangestellte (Köln) ✅ Adressiert → [ONBOARDING-SPEC.md](ONBOARDING-SPEC.md)

### Profil
Arbeitet seit 2021 hybrid (3x Homeoffice/Woche), hat bisher Tage auf einem Kalenderblock notiert. Kommt durch eine Kollegin zur App. Nicht technikaffin, hat Angst etwas falsch zu machen bei der Steuererklärung. Nutzt iPhone SE (2022), keine Widgets.

### Ihre User Journey

**App Store:** Monika liest die Beschreibung, versteht aber nicht sofort was „Pauschale" bedeutet. Wenn im ersten Satz der konkrete Nutzen fehlt – **„Spar Steuern: Bis zu 1.260€ pro Jahr"** – tut sie sich schwer mit dem Download.

**Onboarding:** Für Monika ist Onboarding entscheidend. Sie braucht Kontext: Was ist die Homeoffice-Pauschale? Wer hat Anspruch darauf? Wenn die App das in 1–2 Sätzen erklärt (nicht auf eine Website verlinkt), schafft das Vertrauen. Fehlt diese Erklärung komplett, wirkt die App unprofessionell für ihren Use Case.

**Dateneingabe:** Monika will keine Angst haben, einen falschen Tag eingetragen zu haben. Sie braucht: Tipp-Feedback (der Tag wurde gespeichert), einfaches Löschen eines versehentlich eingetragenen Tages, und eine Übersicht „was habe ich diese Woche eingetragen".

**Wochentag-Problem:** Monika vergisst öfters, einen Tag einzutragen. Wenn sie freitags merkt, dass sie Mittwoch und Donnerstag vergessen hat – wie trägt sie das nach? Ist die Rückdatierung intuitiv? Kann sie auf das Datum im Kalender-View tippen? Wenn sie dafür eine Einstellungsseite suchen muss, scheitert sie.

**November-Panik:** Im November, kurz vor der Steuererklärung, will Monika alles nochmal prüfen. Gibt es eine Jahresübersicht mit allen eingetragenen Tagen? Kann sie schnell erkennen ob ein Monat fehlt?

**Export:** Monika will das PDF per E-Mail an ihren Steuerberater schicken. Wenn der Share-Button fehlt oder das PDF im Files-App landet ohne erklärung, verliert sie es.

**Critical Drop-Off-Risiko:** Monika gibt auf, wenn:
- Die App nicht erklärt, was die Homeoffice-Pauschale ist
- Rückdatierung nicht sofort offensichtlich ist
- Das PDF nicht direkt per Mail teilbar ist
- Kein visuelles Feedback nach dem Eintragen eines Tages (hat es geklappt?)

**Verbesserungs-Empfehlungen für Monika:**
- 1-Satz-Erklärung im Onboarding: „6€ pro Homeoffice-Tag, max. 1.260€/Jahr – direkt von der Steuer absetzbar"
- Kalender-View als primäre Ansicht: Monika versteht Kalender, keine abstrakten Listen
- Erfolgs-Feedback nach Eintrag: grüner Haken, kurze Haptic, sichtbare Aktualisierung des Zählers
- Share Sheet direkt nach PDF-Generierung zeigen (nicht ins Dateisystem verstecken)
- Rückdatierung: Tap auf beliebiges vergangenes Datum im Kalender = sofort editierbar

---

## Persona 4 — Florian, 41, Freiberuflicher Grafiker (Hamburg) ✅ Adressiert → [ONBOARDING-SPEC.md](ONBOARDING-SPEC.md)

### Profil
Selbstständig seit 8 Jahren, arbeitet immer von zuhause. Hört von der App durch einen Post in einer Freelancer-Facebook-Gruppe. Klickt auf den App-Store-Link ohne viel zu lesen.

### Sein User Journey — der Misfit-Test

**Ursprüngliche Annahme (revidiert):** Erste Analyse nahm an, Selbstständige haben keinen Anspruch auf die Homeoffice-Pauschale. Das ist falsch. **Korrektur:** Die Homeoffice-Pauschale gilt auch für Selbstständige (§ 4 Abs. 5 Nr. 6c EStG) — als Betriebsausgabe statt Werbungskosten. Der Unterschied liegt im Abzugstyp, nicht in der Berechtigung. Die App ist also für Florian relevant. Richtig adressiert: Eligibility-Check im Onboarding klärt den Unterschied und gibt den korrekten Hinweis (Betriebsausgaben vs. Werbungskosten).

**Was die App tun sollte:** Im Onboarding eine kurze Frage: „Bist du Arbeitnehmer (angestellt) oder selbstständig?" Wenn selbstständig: Klarer Hinweis, dass die Homeoffice-Pauschale für diesen Fall nicht greift, und optionale Erklärung des Unterschieds. Das klingt nach einem Conversions-Killer – ist aber das Gegenteil: Es baut massives Vertrauen auf und verhindert negative Reviews von Nutzern die die App für ihr Setup nicht verstehen.

**App Store Reviews als Risiko:** Ohne diesen Filter wird Florian eine 1-Stern-Bewertung hinterlassen: „Nutzlos für Selbstständige – hätte das vorher stehen sollen." Dieser Review schadet unverhältnismäßig stark in einer Nische mit wenig Traffic.

**Verbesserungs-Empfehlungen für Florian:**
- Kurzer Eligibility-Check im Onboarding (Arbeitnehmer / Selbstständig / Beamter)
- Bei „Selbstständig": Freundliche Erklärung + Hinweis auf die andere steuerliche Behandlung
- Das verhindert schlechte Reviews und zeigt Kompetenz in der Nische

---

## Übergreifende Bewertung

### Onboarding (Note: noch offen, Risiken hoch)

Der größte Onboarding-Fehler wäre eine zu frühe Paywall. Empfohlenes Muster: **„Try before you buy"** – die ersten 30 Tage erfassen ist komplett kostenlos, der Export (der Steuer-Use-Case) ist Premium. So erlebt der Nutzer den Wert der App, bevor er zahlt.

Fehlendes Eligibility-Screening ist ein echtes Risiko für Reviews. Fehlende Rückdatierungsmöglichkeit im Onboarding ist ein Conversion-Killer für Nutzer die die App nicht im Januar installieren.

**Konkrete Onboarding-Sequenz-Empfehlung:**
1. Screen 1: Wert-Proposition. „Bis zu 1.260€ Steuerersparnis – einfach tracken." (kein Text-Wall)
2. Screen 2: Eligibility-Check (Arbeitnehmer / Selbstständig)
3. Screen 3: Startdatum wählen (mit Option „Rückwirkend ab 1. Januar")
4. Screen 4: Notification-Permission anfragen (mit konkretem Nutzen erklären: „Erinnere mich täglich um 17 Uhr")
5. Los geht's – kein Kauf-Prompt bis zum ersten Export-Versuch

---

### Tägliche Nutzung / Durchführung

**Stärken (angenommen):**
- SwiftData für lokale Persistenz ist die richtige Wahl (kein Backend-Ausfall, Privacy-First)
- Widget ist konzeptionell richtig

**Schwächen / Risiken:**
- Wenn der primäre CTA nicht „Heute war Homeoffice" als dominanter Button ist, sinkt die tägliche Retention drastisch
- Kein interaktives Widget = verpasste iOS 17-Feature-Nutzung
- Fehlende Streaks oder Wochen-Zusammenfassung macht die App passiv statt aktiv

**Was fehlende Reminder kosten:** Ohne tägliche Push-Notification verlieren Nutzer die Gewohnheit nach ca. 2 Wochen. Die Notification muss aktivierbar sein, aber nicht aufdringlich. Empfehlung: Standard-Zeit 17:30 Uhr mit einem-Tap-Änderung.

---

### Nutzungsqualität

**Datenintegrität:** Da es keine Server gibt, gibt es auch kein Backup. Was passiert bei iPhone-Wechsel? Wenn SwiftData über iCloud-Backup wiederhergestellt wird – funktioniert das zuverlässig? Wenn ein Nutzer nach iPhone-Wechsel seine Daten verliert, ist das eine 1-Stern-Bewertung und eine verlorene Empfehlung.

**Empfehlung:** Expliziter Hinweis in den Einstellungen: „Deine Daten werden automatisch in iCloud Backup gesichert. Bei iPhone-Wechsel: App installieren und aus iCloud wiederherstellen." Verhindert Panik.

**Steuerjahrwechsel:** Was passiert am 1. Januar? Startet die App automatisch ein neues Zähljahr? Zeigt sie einen Jahresabschluss-Screen („2024: 187 Tage, 1.122€ gespart")? Das ist ein Moment mit hohem emotionalem Wert – und ein natürlicher Upgrade-Prompt für Premium.

**Grenzfall Teilzeit:** Was wenn jemand an einem Tag nur 4 Stunden im Homeoffice ist? Zählt das als voller Tag? (Steuerrechtlich: ja, wenn der überwiegende Teil der Arbeitszeit Homeoffice war.) Das sollte in einer FAQ oder einem kleinen Info-Button erklärt sein.

---

### Design / UI

**Basierend auf SwiftUI-Best-Practices und der Zielgruppe:**

**Was gut funktionieren sollte:**
- Native iOS-Komponenten = vertraute Interaktionsmuster
- SwiftUI + iOS 17 = moderne Optik ohne Mehraufwand

**Kritische Design-Risiken:**

1. **Zähler-Prominenz:** Der Tages-Zähler und der Euro-Betrag müssen auf dem ersten Screen dominant sichtbar sein. Wenn der Nutzer suchen muss, wie viele Tage er schon hat, ist die primäre Motivation (Geld) nicht sichtbar.

2. **Farbcodierung:** Empfehlung: Fortschrittsbalken grün → gelb → rot wenn man sich dem Limit (210 Tage) nähert. Aber: Kein Nutzer kommt jemals an 210 Tage, also ist das eher Motivation als Warnung. Formulierung: „Noch 85 Tage möglich" (positiv) statt „Du hast 125 von 210 Tagen genutzt" (neutral).

3. **Kalender vs. Liste:** Kalender-View ist für Monika intuitiver. Liste ist kompakter für Tobias. Beide Views anzubieten (Toggle) ist die sauberste Lösung und ein mögliches Premium-Feature.

4. **Dark Mode:** Muss tadellos funktionieren. Besonders weil Tech-affine Nutzer (Tobias) fast immer Dark Mode nutzen. Fehlerhafte Dark-Mode-Darstellung (falsche Kontraste, unsichtbare Elemente) wirkt amateurhaft.

5. **Typografie:** Eine einzige Schriftgröße für alle Texte ist ein häufiger Anfängerfehler in SwiftUI. Die Hierarchie muss klar sein: Betrag (groß, fett) > Tage-Zähler (mittel) > Hilfstexte (klein, grau).

6. **App Icon:** Das Icon konkurriert im App Store mit generischen Kalender-Icons. Ein differenziertes Icon (z.B. Haus + €-Symbol, minimalistisch) ist entscheidend für die Klick-Rate.

---

## Monetarisierung: Free vs. Premium

### Aktuelle Struktur (angenommen)
- **Free:** Tracking + Anzeige der Tage/Betrag
- **Premium (2,99€):** PDF-Export, CSV-Export, Widget, Erinnerungen

### Bewertung der Free/Premium-Grenze

**Problem:** Wenn Widget und Erinnerungen hinter der Paywall liegen, fehlen genau die Features, die tägliche Nutzungsgewohnheit aufbauen. Ein Nutzer der kein Widget hat und keine Reminder bekommt, nutzt die App seltener, sieht weniger Wert, zahlt nicht.

**Empfehlung:** Widget und Erinnerungen in die Free-Tier verschieben. Export bleibt Premium. Das erhöht die tägliche Retention (und damit den wahrgenommenen Wert der App) und macht den Export-Paywall-Moment stärker – weil der Nutzer zu diesem Zeitpunkt echte Daten hat, die er exportieren will.

### Optimale Paywall-Strategie

Der Paywall-Moment mit der höchsten Conversion-Rate: Wenn der Nutzer das erste Mal auf „PDF exportieren" tippt. Zu diesem Zeitpunkt:
- Hat er echte Daten eingetragen (emotionaler Wert)
- Will er etwas konkretes tun (Export für Steuer)
- Versteht er sofort was 2,99€ ihm bringt

**Paywall-Screen:** Klar, knapp, mit Vorschau des PDFs (unscharf/watermark). „Einmaliger Kauf – keine Abo-Falle. Für 2,99€ alle Exporte unbegrenzt." Das ist der stärkste Kaufmoment.

### Wo verliert man Geld (Free-User die nie zahlen)?

1. **Nutzer die nie exportieren** – sie sehen keinen Grund zu zahlen. Lösung: Aktiver Jahresend-Prompt im Dezember/Januar: „Deine Steuererklärung naht – exportiere jetzt deine Daten."
2. **Nutzer die exportieren wollen, aber die 2,99€ zu viel erscheint** – Lösung: Kontext zeigen. „Du sparst ca. 1.122€ an Steuern – für 2,99€ der Nachweis dafür." Das reframt den Preis.
3. **Nutzer die die App nach 2 Wochen vergessen** – Lösung: Push-Notification „Hast du heute im Homeoffice gearbeitet?" täglich um 17:30 (opt-in, Free-Feature).

### Potenzielle zusätzliche Einnahmequellen

**1. Kombi-App / Bundling (mittelfristig):**
Du hast bereits die Pendelstrecken-App als Follow-up identifiziert. Ein „DACH Tax Bundle" (Homeoffice-Tracker + Pendler-Tracker) für 4,99€ statt 2×2,99€ ist ein natürlicher Upsell. Nutzer die einen Tracker kaufen, sind hoch-wahrscheinlich bereit für den zweiten.

**2. Jahreswechsel-Upgrade-Prompt:**
Zum Jahreswechsel: „2024 abgeschlossen – möchtest du eine schöne Jahresübersicht als PDF?" Wenn das ein Premium-Feature ist, ist der Prompt hochrelevant und zeitlich perfekt.

**3. Steuerberater-Sharing-Feature (langfristig):**
„Teile deine Daten direkt mit deinem Steuerberater" – ein strukturiertes PDF mit Logo-Platzhalter oder einer Teilen-URL (ohne Server, einfach als formatiertes PDF). Kein Monetarisierungs-Feature direkt, aber viraler Verbreitungskanal wenn Steuerberater (wie Sandra) es ihren Klienten empfehlen.

**4. Preis erhöhen auf 3,99€:**
2,99€ ist in der DACH-Region für eine Steuer-Utility mit klarem ROI (bis zu 1.260€/Jahr) sehr niedrig. Ein A/B-Test mit 3,99€ ist es wert – die Preis-Sensitivität bei dieser Zielgruppe ist gering wenn der Wert kommuniziert wird.

---

## Absprung-Risiken nach Phase

| Phase | Risiko | Wahrscheinlichkeit | Empfehlung |
|---|---|---|---|
| App Store | Veraltete Rechtslage in Beschreibung | Hoch | Jährliche Review-Pflicht im Januar |
| App Store | Kein Widget-Screenshot | Mittel | Widget prominent in Screenshot 2 zeigen |
| Onboarding | Paywall zu früh | Hoch | Erst Wert erleben, dann Kauf |
| Onboarding | Kein Eligibility-Check | Mittel | Selbstständige filtern → weniger schlechte Reviews |
| Tag 1–3 | Kein One-Tap-Logging | Hoch | Dominanter „Heute"-Button als primärer CTA |
| Woche 2–3 | Keine Erinnerungen | Hoch | Push-Notification als Free-Feature |
| Steuersaison | Export-Paywall ohne Kontext | Mittel | Preis-Reframing: „2,99€ für 1.260€ Ersparnis" |
| Jahreswechsel | Datenverlust bei iPhone-Wechsel | Niedrig/Hoch wenn passiert | iCloud-Backup-Hinweis aktiv kommunizieren |
| Post-Kauf | Kein Follow-up / Upsell | Mittel | Pendler-App cross-promoten |

---

## Priorisierte Top-10 Maßnahmen

1. **Interactive Widget** (iOS 17 App Intent) – One-Tap-Log aus dem Widget heraus
2. **Onboarding Eligibility-Check** – Selbstständige freundlich ausfiltern
3. **Free-Tier: Widget + Notifications** – Nutzungsgewohnheit aufbauen, dann Premium
4. **Rückdatierungs-UX** – Tap auf Kalender-Datum = sofort editierbar, ohne Umwege
5. **Jahresfortschritts-Anker** – „Noch X€ möglich" als prominente Kennzahl
6. **Paywall mit Preis-Reframing** – „2,99€ für bis zu 1.260€ Steuerersparnis"
7. **PDF mit Tages-Einzelauflistung** – Ohne das ist der Export für Finanzamt unbrauchbar
8. **Jahreswechsel-Prompt im Dezember** – Steuererklärung naht = höchster Kaufmoment
9. **iCloud-Backup-Hinweis in Settings** – Verhinert Datenverlust-Panik und 1-Stern-Reviews
10. **App-Store-Beschreibung jährlich aktualisieren** – Rechtslage und Beträge müssen stimmen

---

*Erstellt: April 2026 | Nächste Review: Januar 2027 (nach Gesetzesänderungen prüfen)*

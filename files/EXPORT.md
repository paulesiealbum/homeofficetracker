# EXPORT.md — Export-Spezifikation (Swift / iOS)

## Anforderungen

Das Export-Dokument muss für deutschen Steuerberater und Finanzamt geeignet sein:

- Deutsch formatierte Datumsangaben (`dd.MM.yyyy`)
- Deutsches Dezimaltrennzeichen (Komma, nicht Punkt)
- UTF-8 BOM für Excel-Kompatibilität (Windows + Mac)
- Klarer Header mit Name und Steuerjahr

---

## CSV-Export

### Format

```
[BOM]Homeoffice-Nachweis;Steuerjahr 2024
Name;Max Mustermann
Erstellt am;15.01.2025

Datum;Wochentag;Notiz
02.01.2024;Dienstag;
03.01.2024;Mittwoch;Projekt Alpha
...

Gesamt;45 Tage;270,00 €
```

### Swift-Implementierung

```swift
// Features/Export/ExportService.swift
import Foundation

func generateCSV(days: [WorkDay], year: Int, name: String) -> String {
    let bom = "\u{FEFF}"  // UTF-8 BOM für Excel auf Windows

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy"
    dateFormatter.locale = Locale(identifier: "de_DE")

    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEEE"
    weekdayFormatter.locale = Locale(identifier: "de_DE")

    let hoDays = days
        .filter { $0.isHomeoffice }
        .sorted { $0.date < $1.date }

    let totalSavings = Double(hoDays.count) * TaxConstants.ratePerDay

    var lines: [String] = []
    lines.append("\(bom)Homeoffice-Nachweis;Steuerjahr \(year)")
    lines.append("Name;\(name)")
    lines.append("Erstellt am;\(dateFormatter.string(from: Date()))")
    lines.append("")
    lines.append("Datum;Wochentag;Notiz")

    for day in hoDays {
        let date = dateFormatter.string(from: day.date)
        let weekday = weekdayFormatter.string(from: day.date)
        let note = day.note ?? ""
        lines.append("\(date);\(weekday);\(note)")
    }

    lines.append("")

    let savingsFormatted = totalSavings.formatted(.number.locale(Locale(identifier: "de_DE")).precision(.fractionLength(2)))
    lines.append("Gesamt;\(hoDays.count) Tage;\(savingsFormatted) €")

    return lines.joined(separator: "\n")
}
```

### Dateiname

```dart
'homeoffice_nachweis_$year.csv'  // z.B. homeoffice_nachweis_2024.csv
```

---

## PDF-Export

### Layout

```
┌─────────────────────────────────────────┐
│  HOMEOFFICE-NACHWEIS                    │
│  Steuerjahr 2024                        │
│─────────────────────────────────────────│
│  Name:         Max Mustermann           │
│  Erstellt am:  15.01.2025               │
│─────────────────────────────────────────│
│  Datum          Wochentag    Notiz      │
│  02.01.2024     Dienstag               │
│  03.01.2024     Mittwoch     Projekt A │
│  ...                                    │
│─────────────────────────────────────────│
│  Gesamt: 45 Tage  ×  6,00 €/Tag        │
│  = 270,00 € absetzbar                  │
│                                         │
│  Hinweis: Homeoffice-Pauschale gemäß   │
│  § 4 Abs. 5 Satz 1 Nr. 6b EStG        │
└─────────────────────────────────────────┘
```

### Swift-Implementierung (PDFKit)

```swift
import PDFKit
import UIKit

func generatePDF(days: [WorkDay], year: Int, name: String) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in Punkten
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy"
    dateFormatter.locale = Locale(identifier: "de_DE")

    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEEE"
    weekdayFormatter.locale = Locale(identifier: "de_DE")

    let hoDays = days.filter { $0.isHomeoffice }.sorted { $0.date < $1.date }
    let totalSavings = Double(hoDays.count) * TaxConstants.ratePerDay
    let savingsStr = totalSavings.formatted(.number.locale(Locale(identifier: "de_DE")).precision(.fractionLength(2)))

    return renderer.pdfData { ctx in
        ctx.beginPage()
        let margin: CGFloat = 40
        var y: CGFloat = margin

        // Titel
        let title = "Homeoffice-Nachweis" as NSString
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 22)
        ])
        y += 30

        let subtitle = "Steuerjahr \(year)" as NSString
        subtitle.draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ])
        y += 28

        // Trennlinie
        ctx.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        ctx.cgContext.move(to: CGPoint(x: margin, y: y))
        ctx.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        ctx.cgContext.strokePath()
        y += 12

        // Meta
        ("Name: \(name)" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12)
        ])
        y += 20
        ("Erstellt am: \(dateFormatter.string(from: Date()))" as NSString).draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
        )
        y += 28

        // Tabellen-Header
        let col = [margin, margin + 110, margin + 220] as [CGFloat]
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        ("Datum" as NSString).draw(at: CGPoint(x: col[0], y: y), withAttributes: headerAttrs)
        ("Wochentag" as NSString).draw(at: CGPoint(x: col[1], y: y), withAttributes: headerAttrs)
        ("Notiz" as NSString).draw(at: CGPoint(x: col[2], y: y), withAttributes: headerAttrs)
        y += 18

        // Tabellenzeilen
        let rowAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
        for day in hoDays {
            if y > pageRect.height - 80 {
                ctx.beginPage()
                y = margin
            }
            (dateFormatter.string(from: day.date) as NSString).draw(at: CGPoint(x: col[0], y: y), withAttributes: rowAttrs)
            (weekdayFormatter.string(from: day.date) as NSString).draw(at: CGPoint(x: col[1], y: y), withAttributes: rowAttrs)
            ((day.note ?? "") as NSString).draw(at: CGPoint(x: col[2], y: y), withAttributes: rowAttrs)
            y += 16
        }

        y += 12
        // Summe
        let summaryStr = "Gesamt: \(hoDays.count) Tage × 6,00 €/Tag = \(savingsStr) €" as NSString
        summaryStr.draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 13)
        ])
        y += 20

        // Paragraph-Hinweis
        let legalHint = "Homeoffice-Pauschale gemäß § 4 Abs. 5 Satz 1 Nr. 6b EStG" as NSString
        legalHint.draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.lightGray
        ])
    }
}
```

---

## Share Sheet (UIActivityViewController)

```swift
// Features/Export/ExportView.swift (Ausschnitt)
import SwiftUI

struct ExportView: View {
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        // ...
        Button("Als CSV exportieren") {
            let csv = generateCSV(days: days, year: selectedYear, name: userName)
            let data = csv.data(using: .utf8)!
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("homeoffice_nachweis_\(selectedYear).csv")
            try? data.write(to: url)
            shareItems = [url]
            showShareSheet = true
        }

        Button("Als PDF exportieren") {
            let pdfData = generatePDF(days: days, year: selectedYear, name: userName)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("homeoffice_nachweis_\(selectedYear).pdf")
            try? pdfData.write(to: url)
            shareItems = [url]
            showShareSheet = true
        }
        // ...
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
```

---

## Wichtige Hinweise

- **UTF-8 BOM ist Pflicht** für Excel auf Windows (ohne BOM werden Umlaute falsch dargestellt)
- **Semikolon als Trennzeichen** (nicht Komma) — Deutschland/Europa Excel-Standard
- **Dezimalkomma** (270,00 €) nicht Dezimalpunkt
- **Datum `dd.MM.yyyy`** — deutsches Standard-Format
- Paragraph-Hinweis im PDF stärkt Glaubwürdigkeit gegenüber Finanzamt

// ExportView.swift
// Premium-Export: PDF (finanzamtstauglich) und CSV (DACH-Excel-kompatibel).
// Alle Beträge aus LegalConfiguration — nie hardcoded.

import SwiftUI
import SwiftData
import StoreKit

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkScheduleSettings.self) private var schedule
    @Environment(\.requestReview) private var requestReview
    @Query private var allDays: [WorkDay]

    @State private var showPaywall = false
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showError = false

    @AppStorage("exportCount") private var exportCount: Int = 0

    /// True wenn Nutzer ein DACH-Land außerhalb Deutschlands gewählt hat
    private var isNonGermanRegion: Bool {
        let state = schedule.federalState
        return state == FederalState.at.rawValue || state == FederalState.ch.rawValue
    }

    private var availableYears: [Int] {
        let years = Set(allDays.map { Calendar.current.component(.year, from: $0.date) })
        let current = Calendar.current.component(.year, from: Date())
        return ([current] + years).uniqued().sorted(by: >)
    }

    private var hoDaysInYear: [WorkDay] {
        allDays.filter {
            $0.isHomeoffice &&
            $0.specialType == nil &&
            Calendar.current.component(.year, from: $0.date) == selectedYear
        }
    }

    var body: some View {
        NavigationStack {
            if AppConfig.shared.isPremium {
                premiumContent
            } else {
                lockedContent
            }
        }
    }

    // MARK: - Premium Content

    private var premiumContent: some View {
        let cfg = LegalConfiguration.config(for: selectedYear)
        let count = hoDaysInYear.count
        let savings = LegalConfiguration.savings(days: count, year: selectedYear)

        return List {
            // AT/CH-Warnung
            if isNonGermanRegion {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export nur für deutsches Steuerrecht")
                                .font(.subheadline.bold())
                            Text("Dein Feiertagskalender ist auf \(schedule.federalState == FederalState.at.rawValue ? "Österreich" : "die Schweiz") eingestellt. Der PDF- und CSV-Export basiert ausschließlich auf dem deutschen EStG und ist für AT/CH-Steuererklärungen nicht geeignet. Bitte einen lokalen Steuerberater hinzuziehen.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.orange.opacity(0.08))
                }
            }

            // Jahresauswahl
            Section {
                Picker("Steuerjahr", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Steuerjahr auswählen")
            }

            // Zusammenfassung
            Section {
                HStack {
                    Text("Homeoffice-Tage")
                    Spacer()
                    Text("\(count) / \(cfg.maxDays)")
                        .foregroundStyle(count >= cfg.maxDays ? .orange : .secondary)
                }
                HStack {
                    Text("Absetzbare Summe")
                    Spacer()
                    Text(savings, format: .currency(code: "EUR"))
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                if count == 0 {
                    Label("Noch keine Homeoffice-Tage für \(selectedYear) eingetragen.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Übersicht \(String(selectedYear))")
            }

            // Export-Buttons
            Section {
                ExportButton(
                    title: "PDF exportieren",
                    subtitle: "Nachweis für Steuerberater / Finanzamt",
                    icon: "doc.richtext",
                    isDisabled: count == 0 || isGenerating || isNonGermanRegion,
                    action: { exportPDF() }
                )
                ExportButton(
                    title: "CSV exportieren",
                    subtitle: "Für Excel (DACH-kompatibel, Semikolon)",
                    icon: "tablecells",
                    isDisabled: count == 0 || isGenerating || isNonGermanRegion,
                    action: { exportCSV() }
                )
            } header: {
                Text("Export")
            } footer: {
                if isNonGermanRegion {
                    Text("Export nicht verfügbar: Die Berechnung basiert auf deutschem Steuerrecht (EStG). Bitte in den Einstellungen ein deutsches Bundesland auswählen oder einen lokalen Steuerberater hinzuziehen.")
                        .foregroundStyle(.orange)
                } else {
                    Text("Das PDF enthält eine tagesgenaue Auflistung aller Homeoffice-Tage — geeignet für Steuerberater und Finanzamt.")
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if isGenerating {
                ProgressView("Wird erstellt…")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: shareItems)
                .presentationDetents([.medium, .large])
        }
        .alert("Fehler beim Export", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unbekannter Fehler. Bitte versuche es erneut.")
        }
    }

    // MARK: - Export-Aktionen

    private func exportPDF() {
        isGenerating = true
        Task.detached(priority: .userInitiated) {
            let homeAddr = await schedule.workplacePeriods
                .first(where: { !$0.homeAddress.isEmpty })?.homeAddress ?? ""
            let pdfData = PDFExportService.generatePDF(
                days: await allDays,
                year: await selectedYear,
                userName: await schedule.userName,
                employmentType: await schedule.employmentType,
                homeAddress: homeAddr,
                workplacePeriods: await schedule.workplacePeriods
            )
            let fileName = "Homeoffice_\(await selectedYear).pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try pdfData.write(to: url)
                await MainActor.run {
                    isGenerating = false
                    shareItems = [url]
                    showShareSheet = true
                    exportCount += 1
                    if exportCount == 2 { requestReview() } // Nach 2. Export: Review-Prompt
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "PDF konnte nicht gespeichert werden: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func exportCSV() {
        isGenerating = true
        Task.detached(priority: .userInitiated) {
            let csvData = CSVExportService.generateCSV(
                days: await allDays,
                year: await selectedYear,
                userName: await schedule.userName,
                employmentType: await schedule.employmentType,
                workplacePeriods: await schedule.workplacePeriods
            )
            let fileName = CSVExportService.fileName(year: await selectedYear)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try csvData.write(to: url)
                await MainActor.run {
                    isGenerating = false
                    shareItems = [url]
                    showShareSheet = true
                    exportCount += 1
                    if exportCount == 2 { requestReview() }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "CSV konnte nicht gespeichert werden: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Locked / Paywall Content

    private var lockedContent: some View {
        let cfg = LegalConfiguration.current
        let priceLabel = StoreKitService.shared.subscriptionProduct.map { "\($0.displayPrice)/Jahr" } ?? "2,99 €/Jahr"
        return ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 12)

                // ── Icon ───────────────────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(Color.emerald.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Color.emerald)
                }

                // ── Headline ───────────────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("Export für den Steuerberater")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Deine Homeoffice-Tage als PDF oder CSV — direkt für Steuerberater und Finanzamt.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)

                // ── Value Card ─────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Du sparst bis zu \(cfg.maxAmountFormatted) im Jahr.")
                        .font(.headline)
                        .foregroundStyle(Color.emerald)
                        .multilineTextAlignment(.center)
                    Text("Für \(priceLabel) abonnieren — Kündigung jederzeit möglich.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .glassCard(tint: .emerald, tintOpacity: 0.25, radius: 16)

                // ── PDF Preview (MUSTER) ───────────────────────────────────────
                PDFPreviewCard(year: selectedYear)
                    .padding(.vertical, 4)

                // ── Feature List ───────────────────────────────────────────────
                VStack(spacing: 0) {
                    FeatureRow(icon: "doc.richtext", color: .emerald,
                               title: "PDF-Export", subtitle: "Finanzamtstauglich, inkl. § 4 EStG")
                    Divider().padding(.leading, 52)
                    FeatureRow(icon: "tablecells", color: .blue,
                               title: "CSV-Export", subtitle: "DACH-kompatibel, öffnet in Excel")
                    Divider().padding(.leading, 52)
                    FeatureRow(icon: "person.2", color: .purple,
                               title: "Mehrere Profile", subtitle: "Für Freelancer mit mehreren Jobs")
                }
                .glassCard(tint: .primary, tintOpacity: 0.07, radius: 16)

                // ── CTA ────────────────────────────────────────────────────────
                Button {
                    showPaywall = true
                } label: {
                    Text("Premium freischalten")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.emerald)

                Spacer().frame(height: 12)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Export Button

private struct ExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(isDisabled ? .tertiary : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(isDisabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(Color.emerald))
            }
        }
        .disabled(isDisabled)
    }
}

// MARK: - PDF Preview (MUSTER — nicht exportierbar)

/// Zeigt eine stilisierte Vorschau des PDF-Exports mit MUSTER-Wasserzeichen.
/// Enthält nur Beispieldaten — dient ausschließlich als Vorschau für Free-User.
private struct PDFPreviewCard: View {
    let year: Int

    private var cfg: LegalConfiguration.YearConfig {
        LegalConfiguration.config(for: year)
    }

    var body: some View {
        ZStack {
            // PDF-Mockup
            VStack(alignment: .leading, spacing: 0) {
                // Kopfzeile
                VStack(alignment: .center, spacing: 3) {
                    Text("Homeoffice-Tracker · Steuerjahr \(year)")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                    Text("Steuernachweis Homeoffice & Pendler")
                        .font(.system(size: 13, weight: .bold))
                    Text("Steuerjahr \(year)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                Divider()

                // Info-Zeile
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NAME").font(.system(size: 6)).foregroundStyle(.secondary)
                        Text("Max Mustermann").font(.system(size: 9, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BESCHÄFTIGUNGSSTATUS").font(.system(size: 6)).foregroundStyle(.secondary)
                        Text("Arbeitnehmer").font(.system(size: 9, weight: .semibold))
                    }
                }
                .padding(.vertical, 6)

                Divider()

                // Section Header
                HStack {
                    Text("1. Homeoffice-Pauschale")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.emerald)
                    Spacer()
                }
                .padding(.vertical, 4)

                // Zusammenfassung
                Group {
                    mockRow(label: "Homeoffice-Tage (eingetragen)", value: "47 Tage")
                    mockRow(label: "Anerkannte Tage (max. \(cfg.maxDays))", value: "47 Tage")
                    mockRow(label: "Pauschale pro Tag", value: cfg.dailyRateFormatted)
                    Divider().padding(.vertical, 2)
                    mockRow(label: "Abzugsbetrag Homeoffice-Pauschale",
                            value: (47.0 * cfg.dailyRate).euroFormatted,
                            bold: true, color: .emerald)
                }

                // Tabellen-Header (verkürzt)
                HStack {
                    Text("Nr.").font(.system(size: 7)).foregroundStyle(.secondary).frame(width: 20, alignment: .leading)
                    Text("Datum").font(.system(size: 7)).foregroundStyle(.secondary)
                    Spacer()
                    Text("Betrag").font(.system(size: 7)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(Color(.systemFill))

                // Beispiel-Zeilen
                ForEach(sampleRows, id: \.0) { row in
                    HStack {
                        Text(row.0).font(.system(size: 8)).frame(width: 20, alignment: .leading)
                        Text(row.1).font(.system(size: 8))
                        Spacer()
                        Text(cfg.dailyRateFormatted).font(.system(size: 8))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    Divider().opacity(0.4)
                }

                Text("… und weitere Einträge …")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

            // MUSTER-Wasserzeichen
            Text("MUSTER")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(Color.red.opacity(0.22))
                .rotationEffect(.degrees(-30))

            // Schloss-Overlay (obere rechte Ecke)
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2.bold())
                        Text("Nur mit Premium")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(10)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 2)
    }

    private func mockRow(label: String, value: String, bold: Bool = false, color: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: bold ? .bold : .regular))
                .foregroundStyle(bold ? color : .primary)
        }
        .padding(.vertical, 1)
    }

    private var sampleRows: [(String, String)] {
        let entries: [(String, String, String)] = [
            ("1", "03.01.", "Mittwoch"),
            ("2", "08.01.", "Montag"),
            ("3", "15.01.", "Montag"),
            ("4", "22.01.", "Montag"),
        ]
        return entries.map { ("\($0.0)", "\($0.1)\(year), \($0.2)") }
    }
}

private extension Double {
    var euroFormatted: String {
        self.formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
    }
}

// MARK: - Share Sheet (UIActivityViewController)

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Array Helper

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

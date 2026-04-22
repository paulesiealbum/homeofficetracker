import SwiftUI
import UIKit

/// Sheet zum Anlegen und Bearbeiten einer Arbeitsstätten-Periode.
/// Wird sowohl für neue Einträge als auch zum Editieren bestehender Perioden verwendet.
struct WorkplacePeriodEditView: View {
    let onSave: (WorkplacePeriod) -> Void

    @State private var period: WorkplacePeriod
    @State private var useStartDate: Bool
    @State private var useEndDate: Bool
    @State private var useManualDays: Bool

    @FocusState private var labelFocused: Bool
    @FocusState private var kmFocused: Bool
    @FocusState private var homeAddressFocused: Bool
    @FocusState private var workAddressFocused: Bool
    @FocusState private var manualDaysFocused: Bool

    @Environment(\.dismiss) private var dismiss

    init(period: WorkplacePeriod, onSave: @escaping (WorkplacePeriod) -> Void) {
        self.onSave = onSave
        _period = State(initialValue: period)
        _useStartDate = State(initialValue: period.startDate != nil)
        _useEndDate = State(initialValue: period.endDate != nil)
        _useManualDays = State(initialValue: period.manualOfficeDays != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                grunddatenSection
                verkehrsmittelSection
                adressenSection
                zeitraumSection
                buerotageSection
            }
            .navigationTitle("Arbeitsstätte")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onSave(period)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(period.commuteKm == 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Fertig") {
                            labelFocused = false
                            kmFocused = false
                            homeAddressFocused = false
                            workAddressFocused = false
                            manualDaysFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var grunddatenSection: some View {
        Section {
            // Bezeichnung
            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("Bezeichnung (optional)", text: $period.label)
                    .focused($labelFocused)
            }

            // km-Eingabe
            HStack {
                Text("Entfernung Wohnung – Büro")
                Spacer()
                TextField("0", value: Binding(
                    get: { period.commuteKm },
                    set: { period.commuteKm = max(0, min(500, $0)) }
                ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
                .focused($kmFocused)
                Text("km")
                    .foregroundStyle(.secondary)
            }

            // Pauschale pro Tag (sofortige Rückmeldung)
            if period.commuteKm > 0 {
                let perDay = CommuterConstants.deductionPerDay(distanceKm: period.commuteKm)
                HStack {
                    Text("Pauschale pro Bürotag")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(perDay, format: .currency(code: "EUR"))
                        .foregroundStyle(.blue)
                }
                .font(.subheadline)
            }
        } header: {
            Text("Grunddaten")
        } footer: {
            Text("Einfache Entfernung (kürzeste Straßenverbindung) gemäß §9 Abs. 1 Nr. 4 EStG.")
        }
    }

    private var verkehrsmittelSection: some View {
        Section {
            Picker("Verkehrsmittel", selection: $period.transportMode) {
                ForEach(TransportMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.navigationLink)

            // Rechtlicher Hinweis zum gewählten Verkehrsmittel
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: period.transportMode.capExempt ? "checkmark.seal.fill" : "info.circle")
                    .foregroundStyle(period.transportMode.capExempt ? .green : .secondary)
                    .font(.footnote)
                    .padding(.top, 1)
                Text(period.transportMode.legalNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(period.transportMode.capExempt ? Color.green.opacity(0.06) : Color.clear)
        } header: {
            Text("Verkehrsmittel")
        } footer: {
            if period.transportMode.capExempt {
                Text("PKW/Motorrad: Der Jahreshöchstbetrag von 4.500 € gilt nicht — der volle Pauschalbetrag wird angesetzt (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG).")
                    .foregroundStyle(.green)
            } else if period.transportMode == .transit {
                Text("ÖPNV: Jahreshöchstbetrag 4.500 € gilt. Alternativ können tatsächliche Ticketkosten angesetzt werden, wenn diese höher sind — bitte mit Steuerberater abstimmen.")
            } else {
                Text("Fahrrad/zu Fuß: Jahreshöchstbetrag 4.500 € gilt (kein motorisiertes Fahrzeug).")
            }
        }
    }

    private var adressenSection: some View {
        Section {
            HStack {
                Image(systemName: "house")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("Wohnadresse (optional)", text: $period.homeAddress)
                    .focused($homeAddressFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }

            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("Arbeitsadresse (optional)", text: $period.workAddress)
                    .focused($workAddressFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }

            if !period.homeAddress.isEmpty || !period.workAddress.isEmpty {
                Button {
                    openInMaps(from: period.homeAddress, to: period.workAddress)
                } label: {
                    HStack {
                        Image(systemName: "map")
                        Text("Route in Apple Maps prüfen")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            }
        } header: {
            Text("Adressen")
        } footer: {
            Text("Nur lokal gespeichert, werden nie übertragen.")
        }
    }

    private var zeitraumSection: some View {
        Section {
            Toggle("Startdatum einschränken", isOn: $useStartDate)
                .onChange(of: useStartDate) { _, on in
                    if !on {
                        period.startDate = nil
                    } else if period.startDate == nil {
                        period.startDate = Calendar.current.date(from: DateComponents(
                            year: Calendar.current.component(.year, from: Date()),
                            month: 1, day: 1
                        ))
                    }
                }

            if useStartDate, let startDate = period.startDate {
                DatePicker(
                    "Beschäftigt ab",
                    selection: Binding(
                        get: { startDate },
                        set: { period.startDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }

            Toggle("Enddatum einschränken", isOn: $useEndDate)
                .onChange(of: useEndDate) { _, on in
                    if !on {
                        period.endDate = nil
                    } else if period.endDate == nil {
                        period.endDate = Calendar.current.date(from: DateComponents(
                            year: Calendar.current.component(.year, from: Date()),
                            month: 12, day: 31
                        ))
                    }
                }

            if useEndDate, let endDate = period.endDate {
                DatePicker(
                    "Beschäftigt bis",
                    selection: Binding(
                        get: { endDate },
                        set: { period.endDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Zeitraum")
        } footer: {
            Text("Arbeitgeberwechsel: Zeitraum pro Eintrag einschränken.\nMehrere Dienstverhältnisse gleichzeitig: Einträge ohne Zeitraum anlegen und Bürotage manuell angeben.")
        }
    }

    private var buerotageSection: some View {
        Section {
            Toggle("Bürotage manuell angeben", isOn: $useManualDays)
                .onChange(of: useManualDays) { _, on in
                    if !on {
                        period.manualOfficeDays = nil
                    } else if period.manualOfficeDays == nil {
                        period.manualOfficeDays = 0
                    }
                }

            if useManualDays {
                HStack {
                    Text("Bürotage im Jahr")
                    Spacer()
                    TextField("0", value: Binding(
                        get: { period.manualOfficeDays ?? 0 },
                        set: { period.manualOfficeDays = max(0, $0) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .focused($manualDaysFocused)
                    Text("Tage")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Bürotage")
        } footer: {
            if useManualDays {
                Text("Manuell: Ideal bei mehreren gleichzeitigen Dienstverhältnissen, wenn der Kalender die Tage pro Arbeitgeber nicht getrennt erfasst.")
            } else {
                Text("Automatisch: Die App zählt deine Bürotage aus dem Kalender im gewählten Zeitraum.")
            }
        }
    }

    // MARK: - Maps Deep Link

    private func openInMaps(from home: String, to work: String) {
        var components = URLComponents(string: "maps://")!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "dirflg", value: "d")]
        if !home.isEmpty { queryItems.append(URLQueryItem(name: "saddr", value: home)) }
        if !work.isEmpty { queryItems.append(URLQueryItem(name: "daddr", value: work)) }
        components.queryItems = queryItems
        if let url = components.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

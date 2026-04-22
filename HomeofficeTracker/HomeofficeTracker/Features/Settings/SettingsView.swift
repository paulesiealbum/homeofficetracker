import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @Environment(WorkScheduleSettings.self) private var schedule
    @State private var showPaywall = false
    @State private var editingPeriod: WorkplacePeriod? = nil
    @FocusState private var distanceFieldFocused: Bool
    @State private var notificationPermissionDenied = false

    var body: some View {
        NavigationStack {
            Form {
                workingDaysSection
                homefficeDaysSection
                pendlerSection
                reminderSection
                feiertagSection
                exportSection
                dataSection
                appearanceSection
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Fertig") {
                            distanceFieldFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $editingPeriod) { period in
                WorkplacePeriodEditView(period: period) { updated in
                    if let idx = schedule.workplacePeriods.firstIndex(where: { $0.id == updated.id }) {
                        schedule.workplacePeriods[idx] = updated
                    } else {
                        schedule.workplacePeriods.append(updated)
                    }
                }
            }
        }
    }

    private var workingDaysSection: some View {
        Section {
            ForEach(WorkScheduleSettings.allWeekdays, id: \.iso) { day in
                Toggle(day.label, isOn: Binding(
                    get: { schedule.workingDays.contains(day.iso) },
                    set: { isOn in
                        if isOn {
                            schedule.workingDays.insert(day.iso)
                        } else {
                            schedule.workingDays.remove(day.iso)
                            schedule.homefficeDays.remove(day.iso)
                        }
                    }
                ))
            }
        } header: {
            Text("An welchen Tagen arbeitest du?")
        } footer: {
            Text("Nicht ausgewählte Tage werden im Kalender ausgeblendet.")
        }
    }

    private var pendlerSection: some View {
        Section {
            if AppConfig.shared.isPremium {
                // Premium: Liste aller Arbeitsstätten-Perioden
                if schedule.workplacePeriods.isEmpty {
                    Button {
                        editingPeriod = WorkplacePeriod()
                    } label: {
                        Label("Arbeitsstätte hinzufügen", systemImage: "plus.circle")
                    }
                } else {
                    ForEach(schedule.workplacePeriods) { period in
                        Button {
                            editingPeriod = period
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(period.displayLabel)
                                        .foregroundStyle(.primary)
                                    if let desc = period.periodDescription {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(period.commuteKm) km")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                    if period.commuteKm > 0 {
                                        let perDay = CommuterConstants.deductionPerDay(distanceKm: period.commuteKm)
                                        Text(perDay, format: .currency(code: "EUR"))
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .tint(.primary)
                    }
                    .onDelete { indexSet in
                        schedule.workplacePeriods.remove(atOffsets: indexSet)
                    }

                    Button {
                        editingPeriod = WorkplacePeriod()
                    } label: {
                        Label("Weitere Arbeitsstätte", systemImage: "plus.circle")
                    }
                }
            } else {
                // Free: einfaches km-Feld ohne Berechnung
                HStack {
                    Text("Entfernung Wohnung – Büro")
                    Spacer()
                    TextField("0", value: Binding(
                        get: { schedule.commuterDistanceKm },
                        set: { schedule.commuterDistanceKm = max(0, min(500, $0)) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .focused($distanceFieldFocused)
                    Text("km")
                        .foregroundStyle(.secondary)
                }

                if schedule.commuterDistanceKm > 0 {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Text("Pauschale berechnen")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Pendlerpauschale")
        } footer: {
            if AppConfig.shared.isPremium {
                Text("Berechnung gemäß § 9 Abs. 1 Satz 3 Nr. 4 EStG: 0,30 €/km bis 20 km, 0,38 €/km ab 21 km (ab 2022). Mehrere Arbeitsstätten möglich – für Arbeitgeberwechsel (Zeitraum) oder mehrere Dienstverhältnisse gleichzeitig. Kein Ersatz für Steuerberatung.")
            } else {
                Text("Einfache Entfernung eintragen. Mit Premium: Mehrere Arbeitsstätten, Zeiträume und Pauschale automatisch berechnen.")
            }
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { schedule.reminderEnabled },
                set: { enabled in
                    if enabled {
                        Task {
                            let granted = await NotificationService.shared.requestPermission()
                            if granted {
                                schedule.reminderEnabled = true
                                NotificationService.shared.scheduleReminder(
                                    hour: schedule.reminderHour,
                                    minute: schedule.reminderMinute
                                )
                            } else {
                                notificationPermissionDenied = true
                            }
                        }
                    } else {
                        schedule.reminderEnabled = false
                        NotificationService.shared.cancelReminder()
                    }
                }
            )) {
                Label("Täglicher Reminder", systemImage: "bell")
            }

            if schedule.reminderEnabled {
                DatePicker(
                    "Uhrzeit",
                    selection: Binding(
                        get: {
                            var comps = DateComponents()
                            comps.hour = schedule.reminderHour
                            comps.minute = schedule.reminderMinute
                            return Calendar.current.date(from: comps) ?? Date()
                        },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            schedule.reminderHour = comps.hour ?? 18
                            schedule.reminderMinute = comps.minute ?? 0
                            NotificationService.shared.scheduleReminder(
                                hour: schedule.reminderHour,
                                minute: schedule.reminderMinute
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Reminder")
        } footer: {
            if notificationPermissionDenied {
                Text("Benachrichtigungen sind in den Systemeinstellungen deaktiviert. Bitte unter Einstellungen → Homeoffice-Tracker → Mitteilungen aktivieren.")
                    .foregroundStyle(.red)
            } else {
                Text("Tägliche Erinnerung zum Erfassen deines Homeoffice-Tags. Kostenlos.")
            }
        }
        .alert("Benachrichtigungen deaktiviert", isPresented: $notificationPermissionDenied) {
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Bitte Mitteilungen für Homeoffice-Tracker in den Systemeinstellungen erlauben.")
        }
    }

    // MARK: - Feiertags-Section

    private var feiertagSection: some View {
        Section {
            Picker("Bundesland / Land", selection: Binding(
                get: { schedule.federalState },
                set: { schedule.federalState = $0 }
            )) {
                Section("Deutschland") {
                    ForEach(FederalState.germanStates) { state in
                        Text(state.displayName).tag(state.rawValue)
                    }
                }
                Section("DACH") {
                    Text(FederalState.at.displayName).tag(FederalState.at.rawValue)
                    Text(FederalState.ch.displayName).tag(FederalState.ch.rawValue)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Feiertagskalender")
        } footer: {
            if schedule.federalState == FederalState.at.rawValue || schedule.federalState == FederalState.ch.rawValue {
                Text("Österreich und Schweiz: Feiertage werden korrekt angezeigt. Die Steuerberechnung und der Export basieren jedoch auf deutschem Recht (EStG) und sind für AT/CH nicht anwendbar.")
                    .foregroundStyle(.orange)
            } else {
                Text("Feiertage werden im Kalender automatisch markiert und beim Auto-Fill übersprungen.")
            }
        }
    }

    private var exportSection: some View {
        Section {
            HStack {
                Text("Name")
                Spacer()
                TextField("Für PDF-Export", text: Binding(
                    get: { schedule.userName },
                    set: { schedule.userName = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
            }

            NavigationLink {
                ExportView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export")
                        Text("PDF & CSV für Steuerberater")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Steuerjahr-Export")
        } footer: {
            Text("Dein Name erscheint im PDF-Nachweis für das Finanzamt. Exportiere deine Homeoffice-Tage als CSV oder PDF für den Steuerberater.")
        }
    }

    private var homefficeDaysSection: some View {
        Section {
            let activeDays = WorkScheduleSettings.allWeekdays.filter {
                schedule.workingDays.contains($0.iso)
            }
            if activeDays.isEmpty {
                Text("Bitte zuerst Arbeitstage auswählen.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeDays, id: \.iso) { day in
                    Toggle(day.label, isOn: Binding(
                        get: { schedule.homefficeDays.contains(day.iso) },
                        set: { isOn in
                            if isOn {
                                schedule.homefficeDays.insert(day.iso)
                            } else {
                                schedule.homefficeDays.remove(day.iso)
                            }
                        }
                    ))
                }
            }
        } header: {
            Text("An welchen Tagen bist du normalerweise im Homeoffice?")
        } footer: {
            Text("Diese Tage werden beim Hinzufügen neuer Einträge als Standard vorbelegt.")
        }
    }
}

// MARK: - Data & Privacy Section

extension SettingsView {
    private var dataSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: cloudKitStatus.icon)
                    .font(.title3)
                    .foregroundStyle(cloudKitStatus.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(cloudKitStatus.title)
                        .font(.subheadline.bold())
                    Text(cloudKitStatus.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .listRowBackground(cloudKitStatus.color.opacity(0.06))
        } header: {
            Text("Datensicherung & Sync")
        } footer: {
            Text("Deine Daten bleiben ausschließlich auf deinem Gerät bzw. in deinem persönlichen iCloud-Account (CloudKit). Es werden keine Daten an Dritte übertragen.")
        }
    }

    /// Aggregierter iCloud/CloudKit-Status für die UI.
    private var cloudKitStatus: CloudKitStatusInfo {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            // Nutzer nicht in iCloud eingeloggt
            return CloudKitStatusInfo(
                icon: "icloud.slash",
                color: .orange,
                title: "iCloud nicht verbunden",
                detail: "Du bist nicht bei iCloud angemeldet. Deine Daten werden nur lokal gespeichert. Beim Löschen der App oder Gerätewechsel gehen alle Einträge verloren. Bitte in den iPhone-Einstellungen mit Apple ID anmelden."
            )
        }
        // iCloud vorhanden → CloudKit-Sync läuft
        return CloudKitStatusInfo(
            icon: "icloud.fill",
            color: .blue,
            title: "iCloud Sync aktiv",
            detail: "Deine Homeoffice-Tage werden über CloudKit automatisch auf allen deinen Apple-Geräten synchronisiert und gesichert."
        )
    }

    private struct CloudKitStatusInfo {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }
}

// MARK: - Appearance Section

extension SettingsView {
    private var appearanceSection: some View {
        Section {
            Picker("Farbmodus", selection: Binding(
                get: { schedule.colorSchemePreference },
                set: { schedule.colorSchemePreference = $0 }
            )) {
                Label("System", systemImage: "circle.lefthalf.filled")
                    .tag("system")
                Label("Hell", systemImage: "sun.max")
                    .tag("light")
                Label("Dunkel", systemImage: "moon")
                    .tag("dark")
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Erscheinungsbild")
        }
    }
}

// MARK: - Onboarding Sheet

struct OnboardingView: View {
    @Environment(WorkScheduleSettings.self) private var schedule
    @Environment(StoreKitService.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Steps: 0=Welcome, 1=Eligibility, 2=Arbeitstage, 3=Homeoffice-Tage, 4=Pendelweg, 5=Abschluss
    @State private var step: Int = 0
    @State private var showPaywall = false
    @State private var showEligibilityHint = false
    @State private var commuterKm: Int = 0

    private let totalSteps = 6

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0:  welcomeScreen
                case 1:  eligibilityScreen
                case 2:  workingDaysPicker
                case 3:  homefficeDaysPicker
                case 4:  commuterScreen
                default: finishScreen
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    // "Weiter"-Button nur auf Steps ohne eigenen CTA
                    if step == 2 || step == 3 {
                        Button("Weiter") { step += 1 }
                            .fontWeight(.semibold)
                    }
                }
            }
            .animation(.easeInOut, value: step)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: store.isPurchased) { _, purchased in
            if purchased {
                schedule.hasCompletedOnboarding = true
                dismiss()
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeScreen: some View {
        let cfg = LegalConfiguration.current
        return ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    AppLogoView(size: 96)
                        .padding(.top, 48)

                    VStack(spacing: 6) {
                        Text("HomeofficeTracker")
                            .font(.title.bold())
                        // Beträge aus LegalConfiguration — nie hardcoded
                        Text("Bis zu \(cfg.maxAmountFormatted) Steuerersparnis — einfach tracken.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                VStack(spacing: 0) {
                    WelcomeFeatureRow(
                        icon: "house.fill", color: .green,
                        title: "Homeoffice tracken",
                        subtitle: "Tage mit einem Tipp eintragen – schnell und einfach"
                    )
                    Divider().padding(.leading, 56)
                    WelcomeFeatureRow(
                        icon: "eurosign.circle.fill", color: .green,
                        title: "Steuerersparnis im Blick",
                        // Beträge dynamisch aus LegalConfiguration
                        subtitle: "\(cfg.dailyRateFormatted) pro Tag, max. \(cfg.maxDays) Tage – automatisch berechnet"
                    )
                    Divider().padding(.leading, 56)
                    WelcomeFeatureRow(
                        icon: "pencil.circle", color: .blue,
                        title: "Mehrere Tage auf einmal",
                        subtitle: "Stift ✎ neben dem Monatsnamen tippen, dann Tage wischen"
                    )
                    Divider().padding(.leading, 56)
                    WelcomeFeatureRow(
                        icon: "doc.text.fill", color: .orange,
                        title: "Exportieren leicht gemacht",
                        subtitle: "CSV & PDF für deinen Steuerberater auf Knopfdruck"
                    )
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                // Haftungshinweis (kurz, Pflicht gem. RECHTSLAGE.md)
                Text("Die App hilft beim Tracken — die steuerliche Prüfung liegt bei dir oder deinem Steuerberater.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Button {
                    step += 1
                } label: {
                    Text("Jetzt einrichten")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.emerald)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
    }

    // MARK: - Step 1: Eligibility-Check (für Selbstständige und Unsichere)

    private var eligibilityScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Für wen gilt die Pauschale?")
                        .font(.title2.bold())
                    Text("Kurze Frage, damit die App dir korrekte Hinweise geben kann.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Auswahl-Optionen
                VStack(spacing: 0) {
                    ForEach(EmploymentType.allCases) { type in
                        Button {
                            schedule.employmentType = type
                            showEligibilityHint = type.eligibilityHint != nil
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: schedule.employmentType == type
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .font(.title3)
                                    .foregroundStyle(schedule.employmentType == type ? Color.accentColor : .secondary)
                                Text(type.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        if type != EmploymentType.allCases.last {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                // Hinweis-Banner für Selbstständige / Unsichere
                if showEligibilityHint, let hint = schedule.employmentType.eligibilityHint {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .padding(.top, 1)
                        Text(hint)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    step += 1
                } label: {
                    Text("Weiter")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Wer bist du?")
    }

    // MARK: - Step 2: Arbeitstage

    private var workingDaysPicker: some View {
        Form {
            Section {
                ForEach(WorkScheduleSettings.allWeekdays, id: \.iso) { day in
                    Toggle(day.label, isOn: Binding(
                        get: { schedule.workingDays.contains(day.iso) },
                        set: { isOn in
                            if isOn {
                                schedule.workingDays.insert(day.iso)
                            } else {
                                schedule.workingDays.remove(day.iso)
                                schedule.homefficeDays.remove(day.iso)
                            }
                        }
                    ))
                }
            } header: {
                Text("An welchen Tagen arbeitest du?")
            }
        }
        .navigationTitle("Arbeitstage")
    }

    // MARK: - Step 3: Standard-Homeoffice-Tage

    private var homefficeDaysPicker: some View {
        Form {
            Section {
                let activeDays = WorkScheduleSettings.allWeekdays.filter {
                    schedule.workingDays.contains($0.iso)
                }
                ForEach(activeDays, id: \.iso) { day in
                    Toggle(day.label, isOn: Binding(
                        get: { schedule.homefficeDays.contains(day.iso) },
                        set: { isOn in
                            if isOn {
                                schedule.homefficeDays.insert(day.iso)
                            } else {
                                schedule.homefficeDays.remove(day.iso)
                            }
                        }
                    ))
                }
            } header: {
                Text("An welchen Tagen bist du normalerweise im Homeoffice?")
            } footer: {
                Text("Vergangene Tage kannst du jederzeit im Kalender nachtragen — tippe einfach auf das Datum.")
            }
        }
        .navigationTitle("Standard Homeoffice")
    }

    // MARK: - Step 4: Pendelweg (skippable)

    private var commuterScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Header ────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "car.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 8)

                    Text("Fährst du auch ins Büro?")
                        .font(.title2.bold())
                    Text("Für jeden Bürotag gibt es zusätzlich die Entfernungspauschale nach §9 EStG.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // ── km-Eingabe ────────────────────────────────────────────────
                VStack(spacing: 0) {
                    HStack {
                        Text("Entfernung Wohnung – Büro")
                        Spacer()
                        TextField("0", value: $commuterKm, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if commuterKm > 0 {
                        Divider().padding(.leading, 16)
                        let perDay = CommuterConstants.deductionPerDay(distanceKm: commuterKm)
                        let yearEstimate = perDay * 100
                        HStack(spacing: 8) {
                            Image(systemName: "eurosign.circle")
                                .foregroundStyle(Color.emerald)
                            Text("Etwa \(yearEstimate.formatted(.currency(code: "EUR"))) mehr pro Jahr")
                                .font(.subheadline)
                                .foregroundStyle(Color.emerald)
                            Spacer()
                            Text("~100 Bürotage")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                if commuterKm > 0 {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                        Text("Die genaue Berechnung basiert auf deinen tatsächlichen Bürotagen im Kalender — verfügbar mit Premium.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // ── CTAs ──────────────────────────────────────────────────────
                VStack(spacing: 12) {
                    Button {
                        saveCommuterKm()
                        step += 1
                    } label: {
                        Text(commuterKm > 0 ? "Speichern & weiter" : "Weiter")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.emerald)

                    Button { step += 1 } label: {
                        Text("Ich fahre nicht ins Büro")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Pendelweg")
        .scrollDismissesKeyboard(.interactively)
    }

    private func saveCommuterKm() {
        guard commuterKm > 0 else { return }
        schedule.commuterDistanceKm = commuterKm
        let period = WorkplacePeriod(commuteKm: commuterKm)
        if schedule.workplacePeriods.isEmpty {
            schedule.workplacePeriods = [period]
        } else if schedule.workplacePeriods[0].commuteKm == 0 {
            schedule.workplacePeriods[0].commuteKm = commuterKm
        }
    }

    // MARK: - Step 5: Abschluss (kein Paywall-Zwang)

    private var finishScreen: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.emerald.opacity(0.12))
                            .frame(width: 96, height: 96)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.emerald)
                    }
                    Text("Alles bereit.")
                        .font(.title2.bold())
                    Text("Tippe auf einen Tag um ihn zu loggen. Deine Ersparnis aktualisiert sich sofort.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Premium dezent erwähnen — kein Kaufzwang
                VStack(spacing: 0) {
                    PremiumFeatureRow(
                        icon: "doc.text.fill", color: .blue,
                        title: "CSV & PDF Export (Premium)",
                        subtitle: "Für Steuerberater — einmalig \(store.subscriptionProduct?.displayPrice ?? "2,99 €") freischalten"
                    )
                    Divider().padding(.leading, 56)
                    PremiumFeatureRow(
                        icon: "car.fill", color: .blue,
                        title: "Pendlerpauschale-Rechner (Premium)",
                        subtitle: "Bürotage × Entfernung = automatisch berechnet"
                    )
                    Divider().padding(.leading, 56)
                    PremiumFeatureRow(
                        icon: "checkmark.seal.fill", color: .orange,
                        title: "Einmaliger Kauf — kein Abo",
                        subtitle: "Einmalig freischalten, für immer nutzen"
                    )
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 12) {
                    // Primärer CTA: App starten (nicht Kauf!)
                    Button {
                        schedule.hasCompletedOnboarding = true
                        dismiss()
                    } label: {
                        Text("App starten")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.emerald)

                    // Sekundär: Premium-Option dezent anbieten
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Premium freischalten")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Los geht's")
        .task { await store.load() }
    }
}

// MARK: - Welcome Feature Row

private struct WelcomeFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

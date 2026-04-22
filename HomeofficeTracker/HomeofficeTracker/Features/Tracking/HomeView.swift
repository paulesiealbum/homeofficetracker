import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkScheduleSettings.self) private var schedule
    @Query(filter: #Predicate<WorkDay> { _ in true })
    private var allDays: [WorkDay]

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date()).startOfMonth
    @State private var isPlanningMode: Bool = false
    @State private var cellFrames: [Date: CGRect] = [:]
    @State private var dragSelectedDates: Set<Date> = []
    @State private var multiSelectDates: [Date] = []
    @State private var selectedDay: DayEntry?

    @AppStorage("backfillNudgeDismissedYear") private var nudgeDismissedYear: Int = 0
    @AppStorage("backfillNudgeSnoozedUntil") private var nudgeSnoozedUntil: Double = 0
    @AppStorage("calendarTipsShown") private var calendarTipsShown: Bool = false
    @State private var showCalendarTips = false
    @State private var showPendlerPaywall = false
    @State private var showAutoFillPaywall = false
    @State private var showAutoFillConfirm = false

    /// Undo-Stack: Snapshots der letzten Kalenderaktionen (max. 5 Schritte).
    @State private var undoStack: [UndoBatch] = []

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    private var today: WorkDay? {
        allDays.first { Calendar.current.isDateInToday($0.date) }
    }

    private var isHomeofficeToday: Bool {
        today?.isHomeoffice ?? false
    }

    /// Hero-Card für AT/CH: Tracking funktioniert, Steuerberechnung nicht angezeigt.
    private var nonGermanHeroSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("App optimiert für deutsches Steuerrecht")
                        .font(.subheadline.bold())
                    Text("Du hast \(regionLabel) als Feiertagskalender gewählt. Die Steuerberechnung basiert auf dem deutschen EStG und gilt nicht für \(regionLabel). Das Tracken deiner Tage funktioniert weiterhin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(hoCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.emerald)
                    Text("HO-Tage \(currentYear)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(officeCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Bürotage \(currentYear)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard(tint: .blue, tintOpacity: 0.15, radius: 20)
        .shadow(color: Color.blue.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// True wenn heute explizit als Bürotag eingetragen (nicht einfach leer)
    private var isBureoToday: Bool {
        today?.isHomeoffice == false && today?.specialType == nil
    }

    /// True wenn heute ein Wochenendtag ist.
    private var isTodayWeekend: Bool {
        Calendar.current.isDateInWeekend(Date())
    }

    /// True wenn heute ein gesetzlicher Feiertag ist (gemäß konfiguriertem Bundesland).
    private var isTodayHoliday: Bool {
        guard let state = FederalState(rawValue: schedule.federalState) else { return false }
        let map = HolidayService.holidayMap(month: Date(), state: state)
        return map[Calendar.current.startOfDay(for: Date())] != nil
    }

    /// Label für den "Kein Homeoffice"-Zustand inkl. Begründung in Klammern.
    private var keinHomeofficeLabel: String {
        if isTodayWeekend { return "Heute: Kein Homeoffice (Wochenende)" }
        if isTodayHoliday { return "Heute: Kein Homeoffice (Feiertag)" }
        return "Heute: Kein Homeoffice"
    }

    /// Pendlerpauschale für einen Bürotag heute, basierend auf konfigurierter Entfernung.
    /// Funktioniert für Free- und Premium-User (zeigt den Wert, Premium steuert nur Gesamtanzeige).
    private var commuterDeductionToday: Double {
        // Premium: passende Periode für heute suchen
        if AppConfig.shared.isPremium {
            let now = Date()
            if let period = schedule.workplacePeriods.first(where: { p in
                p.commuteKm > 0 &&
                (p.startDate == nil || p.startDate! <= now) &&
                (p.endDate == nil || p.endDate! >= now)
            }) {
                return CommuterConstants.deductionPerDay(distanceKm: period.commuteKm)
            }
        }
        // Free oder kein passender Zeitraum: Legacy-Wert oder erster Perioden-Wert
        let km = schedule.commuterDistanceKm > 0
            ? schedule.commuterDistanceKm
            : (schedule.workplacePeriods.first(where: { $0.commuteKm > 0 })?.commuteKm ?? 0)
        return km > 0 ? CommuterConstants.deductionPerDay(distanceKm: km) : 0
    }

    private var hoCount: Int {
        let year = Calendar.current.component(.year, from: Date())
        return allDays.filter {
            $0.isHomeoffice &&
            $0.specialType == nil &&   // konsistent mit PDF/CSV-Export
            Calendar.current.component(.year, from: $0.date) == year
        }.count
    }

    /// Tatsächliche Bürotage (kein HO, kein Urlaub/Krankheit etc.) im laufenden Jahr
    private var officeCount: Int {
        let year = Calendar.current.component(.year, from: Date())
        return allDays.filter {
            !$0.isHomeoffice &&
            $0.specialType == nil &&
            Calendar.current.component(.year, from: $0.date) == year
        }.count
    }

    private var remainingDays: Int {
        max(0, TaxConstants.maxDaysPerYear - hoCount)
    }

    private var remainingSavings: Double {
        savings(days: remainingDays)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// True wenn Nutzer ein nicht-deutsches DACH-Land gewählt hat.
    /// Berechnungen basieren auf deutschem EStG — für AT/CH nicht anwendbar.
    private var isNonGermanRegion: Bool {
        schedule.federalState == FederalState.at.rawValue ||
        schedule.federalState == FederalState.ch.rawValue
    }

    private var regionLabel: String {
        schedule.federalState == FederalState.at.rawValue ? "Österreich" : "Schweiz"
    }

    /// Monate im aktuellen Jahr (vor dem aktuellen Monat) ohne einen einzigen Eintrag
    private var untrackedPastMonths: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        var result: [Date] = []
        for month in 1..<currentMonth {
            var comps = DateComponents()
            comps.year = currentYear
            comps.month = month
            comps.day = 1
            guard let monthStart = calendar.date(from: comps),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            let hasEntries = allDays.contains { interval.contains($0.date) }
            if !hasEntries { result.append(monthStart) }
        }
        return result
    }

    /// Annähernde Anzahl Arbeitstage (Mo–Fr) in den unerfassten Monaten
    private var untrackedWorkingDaysApprox: Int {
        let calendar = Calendar.current
        return untrackedPastMonths.reduce(0) { count, monthStart in
            guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { return count }
            var date = interval.start
            var days = 0
            while date < interval.end {
                let weekday = calendar.component(.weekday, from: date)
                if weekday != 1 && weekday != 7 { days += 1 }
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? interval.end
            }
            return count + days
        }
    }

    private var showBackfillNudge: Bool {
        nudgeDismissedYear != currentYear &&
        Date().timeIntervalSince1970 > nudgeSnoozedUntil &&
        !untrackedPastMonths.isEmpty
    }

    @ViewBuilder
    private var heroSection: some View {
        // AT/CH: Steuerberechnung basiert auf deutschem EStG — nicht anzeigen
        if isNonGermanRegion {
            nonGermanHeroSection
        } else {
            germanHeroSection
        }
    }

    /// Hero-Card für deutsche Bundesländer: Steuerersparnis + Fortschritt.
    private var germanHeroSection: some View {
        let hoSavings = savings(days: hoCount)
        let periods = schedule.workplacePeriods

        let pendlerSavings: Double = {
            guard AppConfig.shared.isPremium else { return 0 }
            if !periods.isEmpty {
                return CommuterConstants.totalDeduction(periods: periods, allDays: allDays)
            } else {
                return CommuterConstants.totalDeduction(
                    distanceKm: schedule.commuterDistanceKm,
                    officeDays: officeCount
                )
            }
        }()

        let showPendler = AppConfig.shared.isPremium &&
            (!periods.filter { $0.commuteKm > 0 }.isEmpty || schedule.commuterDistanceKm > 0)

        // Teaser-Berechnung für Free-User mit konfigurierter Entfernung
        let teaserKm: Int = {
            if let p = periods.first(where: { $0.commuteKm > 0 }) { return p.commuteKm }
            return schedule.commuterDistanceKm
        }()
        let showPendlerTeaser = !AppConfig.shared.isPremium && teaserKm > 0
        let pendlerTeaserAmount = showPendlerTeaser
            ? CommuterConstants.totalDeduction(distanceKm: teaserKm, officeDays: max(officeCount, 100))
            : 0.0

        let totalSavings = hoSavings + pendlerSavings
        let progress = min(Double(hoCount) / Double(TaxConstants.maxDaysPerYear), 1.0)

        return VStack(spacing: 12) {
            // Haupt-Betrag
            VStack(spacing: 4) {
                Text(totalSavings, format: .currency(code: "EUR"))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.emerald)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: hoCount)

                Text("gespart \(currentYear)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if showPendler {
                    HStack(spacing: 12) {
                        Label(hoSavings.formatted(.currency(code: "EUR")), systemImage: "house.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label(pendlerSavings.formatted(.currency(code: "EUR")), systemImage: "car.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            // Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.18))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.emerald.opacity(0.7), Color.emerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 10)
                            .animation(.spring(duration: 0.5), value: hoCount)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(hoCount) von \(TaxConstants.maxDaysPerYear) Tagen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if remainingDays > 0 {
                        Text("noch \(remainingSavings.formatted(.currency(code: "EUR"))) möglich")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Maximum erreicht 🎉")
                            .font(.caption)
                            .foregroundStyle(Color.emerald)
                    }
                }
            }

            // ── Pendler-Teaser (nur Free-User mit gespeicherter Entfernung) ──
            if showPendlerTeaser {
                Button { showPendlerPaywall = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("+ ~\(pendlerTeaserAmount.formatted(.currency(code: "EUR"))) Pendlerpauschale")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text("Mit Premium freischalten")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("Premium")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.10), in: Capsule())
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard(tint: .emerald, tintOpacity: 0.28, radius: 20)
        .shadow(color: Color.emerald.opacity(0.10), radius: 18, y: 6)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Hero: Steuerersparnis + Fortschritt
                    heroSection

                    // Heute-Card
                    todayCard

                    // Backfill-Nudge (wenn vergangene Monate fehlen)
                    backfillNudgeCard
                        .animation(.spring(duration: 0.35), value: showBackfillNudge)

                    Divider()
                        .padding(.horizontal)

                    // Kalender
                    monthHeader
                        .padding(.horizontal)
                        .padding(.top, 4)

                    weekdayHeader
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                            if let date {
                                DayCell(
                                    date: date,
                                    workDay: workDay(for: date),
                                    isWorkingDay: schedule.isWorkingDay(date),
                                    isPlanningMode: isPlanningMode,
                                    isSelected: dragSelectedDates.contains(date.startOfDay),
                                    holidayName: holidaysInDisplayedMonth[date.startOfDay],
                                    onTap: { tappedDate in
                                        toggleDay(date: tappedDate)
                                    },
                                    onLongPress: { tappedDate in
                                        openDetailSheet(for: tappedDate)
                                    }
                                )
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: CellFrameKey.self,
                                            value: [date.startOfDay: geo.frame(in: .named("calendarGrid"))]
                                        )
                                    }
                                )
                            } else {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .coordinateSpace(name: "calendarGrid")
                    .onPreferenceChange(CellFrameKey.self) { cellFrames = $0 }
                    .simultaneousGesture(calendarDragGesture)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AppLogoView(size: 30)
                }
            }
            .onAppear {
                if schedule.hasCompletedOnboarding && !calendarTipsShown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showCalendarTips = true
                    }
                }
            }
            .onChange(of: schedule.hasCompletedOnboarding) { _, completed in
                if completed && !calendarTipsShown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showCalendarTips = true
                    }
                }
            }
        }
        .sheet(isPresented: $showCalendarTips) {
            CalendarTipsView {
                calendarTipsShown = true
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedDay) { entry in
            DayDetailSheet(
                date: entry.date,
                existingWorkDay: entry.workDay,
                defaultIsHomeoffice: entry.defaultIsHomeoffice,
                isWorkingDay: schedule.isWorkingDay(entry.date)
            ) { isHO, note, specialType in
                saveDay(date: entry.date, isHomeoffice: isHO, note: note, specialType: specialType, existing: entry.workDay)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(
            get: { !multiSelectDates.isEmpty },
            set: { if !$0 { multiSelectDates = [] } }
        )) {
            MultiDayEditSheet(dates: multiSelectDates) { isHO, specialType in
                for date in multiSelectDates {
                    saveDay(date: date, isHomeoffice: isHO, note: "", specialType: specialType, existing: workDay(for: date))
                }
                multiSelectDates = []
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPendlerPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showAutoFillPaywall) {
            PaywallView()
        }
        .confirmationDialog(
            "Wochenmuster anwenden",
            isPresented: $showAutoFillConfirm,
            titleVisibility: .visible
        ) {
            Button("Ausfüllen (\(autoFillCandidateCount) Tage)") {
                autoFillDisplayedMonth()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle leeren Arbeitstage in \(monthTitle) werden gemäß deinem Homeoffice-Wochenmuster eingetragen. Feiertage werden übersprungen.")
        }
    }

    // MARK: - Drag Gesture

    private var calendarDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("calendarGrid"))
            .onChanged { value in
                guard isPlanningMode else { return }
                if let hit = cellFrames.first(where: { $0.value.contains(value.location) }) {
                    let date = hit.key
                    let isFuture = date > Calendar.current.startOfDay(for: Date())
                    if !isFuture || isPlanningMode {
                        dragSelectedDates.insert(date)
                    }
                }
            }
            .onEnded { _ in
                guard isPlanningMode else { return }
                let dates = dragSelectedDates.sorted()
                dragSelectedDates = []
                guard dates.count > 1 else {
                    if let only = dates.first {
                        openDetailSheet(for: only)
                    }
                    return
                }
                multiSelectDates = dates
            }
    }

    // MARK: - Backfill Nudge Card

    @ViewBuilder
    private var backfillNudgeCard: some View {
        if showBackfillNudge {
            let months = untrackedPastMonths
            let formatter: DateFormatter = {
                let f = DateFormatter()
                f.dateFormat = "MMMM"
                f.locale = Locale(identifier: "de_DE")
                return f
            }()
            let monthLabel: String = {
                if months.count == 1 {
                    return formatter.string(from: months[0])
                } else {
                    return "\(formatter.string(from: months[0])) – \(formatter.string(from: months[months.count - 1]))"
                }
            }()
            let potentialSavings = savings(days: untrackedWorkingDaysApprox)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(monthLabel) noch nicht erfasst", systemImage: "calendar.badge.exclamationmark")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("Bis zu \(potentialSavings.formatted(.currency(code: "EUR"))) könnten dir fehlen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        nudgeSnoozedUntil = Date().timeIntervalSince1970 + 7 * 24 * 3600
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        isPlanningMode = true
                        if let firstMonth = months.first {
                            displayedMonth = firstMonth
                        }
                        nudgeDismissedYear = currentYear
                    } label: {
                        Text("Jetzt nachtragen")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        nudgeSnoozedUntil = Date().timeIntervalSince1970 + 7 * 24 * 3600
                    } label: {
                        Text("Später")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(14)
            .background(Color.orange.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.22), lineWidth: 1)
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        HStack(spacing: 8) {

            // ── Haupt-Tap-Bereich ────────────────────────────────────────────
            Button {
                toggleToday()
            } label: {
                HStack(spacing: 10) {

                    // Kompakter Kreis
                    ZStack {
                        Circle()
                            .fill(
                                isHomeofficeToday
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.emerald, Color.emerald.opacity(0.76)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                  ))
                                : isBureoToday
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.blue.opacity(0.75), Color.blue.opacity(0.55)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                  ))
                                : AnyShapeStyle(Color(.secondarySystemFill))
                            )
                            .frame(width: 34, height: 34)
                            .shadow(
                                color: isHomeofficeToday
                                    ? Color.emerald.opacity(0.35)
                                    : isBureoToday
                                    ? Color.blue.opacity(0.20)
                                    : Color.clear,
                                radius: 6, x: 0, y: 2
                            )

                        Image(systemName: isHomeofficeToday ? "house.fill" : (isBureoToday ? "building.2.fill" : "building.2"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isHomeofficeToday || isBureoToday ? Color.white : Color.secondary)
                            .symbolEffect(.bounce, value: isHomeofficeToday)
                    }
                    .animation(.spring(response: 0.42, dampingFraction: 0.64), value: isHomeofficeToday)
                    .animation(.spring(response: 0.42, dampingFraction: 0.64), value: isBureoToday)

                    // Label
                    VStack(alignment: .leading, spacing: 1) {
                        Text(isHomeofficeToday ? "Homeoffice" : (isBureoToday ? "Büro" : keinHomeofficeLabel))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(
                                isHomeofficeToday ? Color.emerald
                                : isBureoToday ? Color.blue.opacity(0.85)
                                : .primary
                            )

                        if isHomeofficeToday {
                            Text("+ \(savings(days: 1).formatted(.currency(code: "EUR"))) heute")
                                .font(.caption)
                                .foregroundStyle(Color.emerald.opacity(0.80))
                        } else if isBureoToday && commuterDeductionToday > 0 {
                            Text("+ \(commuterDeductionToday.formatted(.currency(code: "EUR"))) Pendlerpauschale")
                                .font(.caption)
                                .foregroundStyle(Color.blue.opacity(0.65))
                        } else if today == nil {
                            Text("Tippe zum Erfassen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHomeofficeToday)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isBureoToday)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // ── Reset-Button: nur sichtbar wenn Eintrag für heute existiert ──
            if today != nil {
                Button {
                    clearToday()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.secondary.opacity(0.55))
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
                .help("Eintrag für heute zurücksetzen")
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .glassCard(
            tint: isHomeofficeToday ? .emerald : (isBureoToday ? .blue : .primary),
            tintOpacity: isHomeofficeToday ? 0.28 : (isBureoToday ? 0.15 : 0.06),
            radius: 12
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: today == nil)
        .padding(.horizontal)
        .sensoryFeedback(.impact(weight: .medium), trigger: isHomeofficeToday)
    }

    // MARK: - Subviews

    private var monthHeader: some View {
        HStack(spacing: 0) {
            // Monatsnavigation
            HStack(spacing: 2) {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                Text(monthTitle)
                    .font(.headline)
                    .padding(.horizontal, 4)
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
            }

            Spacer()

            HStack(spacing: 6) {
                // Undo-Button
                Button {
                    performUndo()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.title3)
                        .foregroundStyle(undoStack.isEmpty ? Color.secondary.opacity(0.28) : Color.secondary)
                }
                .disabled(undoStack.isEmpty)
                .accessibilityLabel("Rückgängig")
                .sensoryFeedback(.impact(weight: .light), trigger: undoStack.count)

                // Auto-Fill Button (Premium)
                Button {
                    if AppConfig.shared.isPremium {
                        if autoFillCandidateCount > 0 {
                            showAutoFillConfirm = true
                        }
                    } else {
                        showAutoFillPaywall = true
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                        .foregroundStyle(Color.emerald.opacity(autoFillCandidateCount > 0 ? 1.0 : 0.28))
                }
                .accessibilityLabel("Wochenmuster anwenden")
                .disabled(!AppConfig.shared.isPremium && false) // immer tippbar (öffnet Paywall)

                // Mehrfach-Auswahl-Modus direkt beim Kalender
                Button {
                    isPlanningMode.toggle()
                    if !isPlanningMode { dragSelectedDates = [] }
                } label: {
                    Image(systemName: isPlanningMode ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(isPlanningMode ? Color.emerald : .secondary)
                        .symbolEffect(.bounce, value: isPlanningMode)
                }
                .accessibilityLabel(isPlanningMode ? "Bearbeitung beenden" : "Mehrere Tage auswählen")
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - State for sheet

    struct DayEntry: Identifiable {
        let id = UUID()
        let date: Date
        let workDay: WorkDay?
        let defaultIsHomeoffice: Bool
    }

    // MARK: - Undo-Typen

    /// Ein Batch von Tages-Snapshots für eine einzelne Undo-Aktion.
    struct UndoBatch {
        struct Snapshot {
            let date: Date
            let wasPresent: Bool        // false → Tag wurde neu angelegt (Undo löscht ihn)
            let wasHomeoffice: Bool
            let wasNote: String?
            let wasSpecialType: String?
        }
        let snapshots: [Snapshot]
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: displayedMonth)
    }

    private var calendarDays: [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current

        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstDay = monthInterval.start

        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let offset = (weekdayOfFirst - 2 + 7) % 7
        for _ in 0..<offset { days.append(nil) }

        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func workDay(for date: Date) -> WorkDay? {
        allDays.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func toggleDay(date: Date) {
        guard date <= Date() || isPlanningMode else { return }
        if let existing = workDay(for: date) {
            guard existing.specialType == nil else { return }
            let snap = UndoBatch.Snapshot(date: date, wasPresent: true,
                                          wasHomeoffice: existing.isHomeoffice,
                                          wasNote: existing.note,
                                          wasSpecialType: existing.specialType)
            pushUndo([snap])
            existing.isHomeoffice.toggle()
        } else {
            let snap = UndoBatch.Snapshot(date: date, wasPresent: false,
                                          wasHomeoffice: false, wasNote: nil, wasSpecialType: nil)
            pushUndo([snap])
            let newDay = WorkDay(date: date, isHomeoffice: true)
            modelContext.insert(newDay)
        }
    }

    private func openDetailSheet(for date: Date) {
        guard date <= Date() || isPlanningMode else { return }
        selectedDay = DayEntry(
            date: date,
            workDay: workDay(for: date),
            defaultIsHomeoffice: schedule.isDefaultHomeoffice(date)
        )
    }

    private func saveDay(date: Date, isHomeoffice: Bool, note: String, specialType: String?, existing: WorkDay?) {
        let snap = UndoBatch.Snapshot(
            date: date,
            wasPresent: existing != nil,
            wasHomeoffice: existing?.isHomeoffice ?? false,
            wasNote: existing?.note,
            wasSpecialType: existing?.specialType
        )
        pushUndo([snap])
        if let existing {
            existing.isHomeoffice = isHomeoffice
            existing.note = note.isEmpty ? nil : note
            existing.specialType = specialType
        } else {
            let newDay = WorkDay(date: date, isHomeoffice: isHomeoffice, note: note.isEmpty ? nil : note, specialType: specialType)
            modelContext.insert(newDay)
        }
    }

    private func toggleToday() {
        if let existing = today {
            let snap = UndoBatch.Snapshot(date: existing.date, wasPresent: true,
                                          wasHomeoffice: existing.isHomeoffice,
                                          wasNote: existing.note,
                                          wasSpecialType: existing.specialType)
            pushUndo([snap])
            existing.isHomeoffice.toggle()
        } else {
            let date = Calendar.current.startOfDay(for: Date())
            let snap = UndoBatch.Snapshot(date: date, wasPresent: false,
                                          wasHomeoffice: false, wasNote: nil, wasSpecialType: nil)
            pushUndo([snap])
            let newDay = WorkDay(date: Date(), isHomeoffice: true)
            modelContext.insert(newDay)
        }
    }

    /// Löscht den heutigen Eintrag vollständig (Reset auf „kein Eintrag").
    private func clearToday() {
        guard let existing = today else { return }
        let snap = UndoBatch.Snapshot(
            date: existing.date, wasPresent: true,
            wasHomeoffice: existing.isHomeoffice,
            wasNote: existing.note,
            wasSpecialType: existing.specialType
        )
        pushUndo([snap])
        modelContext.delete(existing)
    }

    // MARK: - Undo

    /// Schiebt eine Gruppe von Snapshots auf den Undo-Stack (max. 5 gespeichert).
    private func pushUndo(_ snapshots: [UndoBatch.Snapshot]) {
        undoStack.append(UndoBatch(snapshots: snapshots))
        if undoStack.count > 5 { undoStack.removeFirst() }
    }

    /// Stellt den letzten Batch von Kalenderänderungen wieder her.
    private func performUndo() {
        guard let batch = undoStack.last else { return }
        undoStack.removeLast()
        for snap in batch.snapshots {
            if snap.wasPresent {
                // Vorherigen Zustand wiederherstellen
                if let existing = workDay(for: snap.date) {
                    existing.isHomeoffice = snap.wasHomeoffice
                    existing.note = snap.wasNote
                    existing.specialType = snap.wasSpecialType
                }
            } else {
                // Neu eingefügten Tag wieder löschen
                if let inserted = workDay(for: snap.date) {
                    modelContext.delete(inserted)
                }
            }
        }
    }

    // MARK: - Feiertagskalender

    /// Feiertage im aktuell angezeigten Monat als [normalisiertes Datum: Name].
    private var holidaysInDisplayedMonth: [Date: String] {
        guard let state = FederalState(rawValue: schedule.federalState) else { return [:] }
        return HolidayService.holidayMap(month: displayedMonth, state: state)
    }

    // MARK: - Auto-Fill (#5)

    /// Anzahl leerer künftiger Arbeitstage im angezeigten Monat (ohne Feiertage).
    private var autoFillCandidateCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let holidays = holidaysInDisplayedMonth
        return calendarDays.compactMap { $0 }.filter { date in
            date >= today &&
            schedule.isWorkingDay(date) &&
            workDay(for: date) == nil &&
            holidays[date.startOfDay] == nil
        }.count
    }

    /// Füllt alle leeren künftigen Arbeitstage im angezeigten Monat
    /// gemäß dem homefficeDays-Wochenmuster. Feiertage werden übersprungen.
    private func autoFillDisplayedMonth() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let holidays = holidaysInDisplayedMonth
        var snapshots: [UndoBatch.Snapshot] = []

        for date in calendarDays.compactMap({ $0 }) {
            guard date >= todayStart else { continue }
            guard schedule.isWorkingDay(date) else { continue }
            guard workDay(for: date) == nil else { continue }
            guard holidays[date.startOfDay] == nil else { continue }

            snapshots.append(UndoBatch.Snapshot(date: date, wasPresent: false,
                                                wasHomeoffice: false, wasNote: nil, wasSpecialType: nil))
            let isHO = schedule.isDefaultHomeoffice(date)
            let newDay = WorkDay(date: date, isHomeoffice: isHO)
            modelContext.insert(newDay)
        }
        if !snapshots.isEmpty { pushUndo(snapshots) }
    }
}

// MARK: - Date extension

private extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - Cell Frame PreferenceKey

private struct CellFrameKey: PreferenceKey {
    static var defaultValue: [Date: CGRect] = [:]
    static func reduce(value: inout [Date: CGRect], nextValue: () -> [Date: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let workDay: WorkDay?
    let isWorkingDay: Bool
    let isPlanningMode: Bool
    let isSelected: Bool
    let holidayName: String?
    let onTap: (Date) -> Void
    let onLongPress: (Date) -> Void

    init(
        date: Date,
        workDay: WorkDay?,
        isWorkingDay: Bool,
        isPlanningMode: Bool,
        isSelected: Bool,
        holidayName: String? = nil,
        onTap: @escaping (Date) -> Void,
        onLongPress: @escaping (Date) -> Void
    ) {
        self.date = date
        self.workDay = workDay
        self.isWorkingDay = isWorkingDay
        self.isPlanningMode = isPlanningMode
        self.isSelected = isSelected
        self.holidayName = holidayName
        self.onTap = onTap
        self.onLongPress = onLongPress
    }

    private var isFuture: Bool { date > Calendar.current.startOfDay(for: Date()) }
    private var isInteractable: Bool { !isFuture || isPlanningMode }
    private var dayNumber: String { "\(Calendar.current.component(.day, from: date))" }

    /// Vom Nutzer manuell gesetzter SpecialType
    private var specialType: SpecialDayType? {
        guard let raw = workDay?.specialType else { return nil }
        return SpecialDayType(rawValue: raw)
    }

    /// Systemseitig erkannter Feiertag (kein WorkDay-Eintrag nötig)
    private var isSystemHoliday: Bool {
        holidayName != nil && workDay == nil
    }

    private var background: Color {
        if isSelected { return Color.emerald.opacity(0.22) }
        // Manuell gesetzter SpecialType hat Vorrang
        if let special = specialType {
            switch special {
            case .vacation: return Color.orange.opacity(0.25)
            case .sick: return Color.red.opacity(0.2)
            case .publicHoliday: return Color.purple.opacity(0.2)
            case .other: return Color.blue.opacity(0.15)
            }
        }
        // System-Feiertag ohne WorkDay-Eintrag
        if isSystemHoliday { return Color.purple.opacity(0.10) }
        guard isWorkingDay, let wd = workDay else { return .clear }
        return wd.isHomeoffice ? Color.emerald.opacity(0.28) : Color(.systemFill)
    }

    private var dotColor: Color? {
        if let special = specialType {
            switch special {
            case .vacation: return .orange
            case .sick: return .red
            case .publicHoliday: return .purple
            case .other: return .blue
            }
        }
        // System-Feiertag: lila Punkt
        if isSystemHoliday { return .purple }
        guard isWorkingDay, let wd = workDay else { return nil }
        return wd.isHomeoffice ? .emerald : Color(white: 0.5)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(background)

            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.emerald, lineWidth: 2)
            } else if Calendar.current.isDateInToday(date) {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.emerald.opacity(0.85), lineWidth: 2)
            } else if isSystemHoliday {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.purple.opacity(0.30), lineWidth: 1)
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.callout.weight(Calendar.current.isDateInToday(date) ? .bold : .regular))
                    .foregroundStyle(
                        isFuture && !isPlanningMode
                            ? .tertiary
                            : (isWorkingDay || specialType != nil || isSystemHoliday ? .primary : .tertiary)
                    )
                if let dot = dotColor {
                    Circle()
                        .fill(dot)
                        .frame(width: 5, height: 5)
                }
                if isFuture && isPlanningMode && specialType == nil && !isSelected && !isSystemHoliday {
                    Circle()
                        .fill(Color.emerald.opacity(0.4))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isInteractable else { return }
            onTap(date)
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            guard isInteractable else { return }
            onLongPress(date)
        }
        .help(holidayName ?? "") // Tooltip auf macOS / VoiceOver-Hint auf iOS
    }
}

// MARK: - Multi Day Edit Sheet

private struct MultiDayEditSheet: View {
    let dates: [Date]
    let onSave: (Bool, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isHomeoffice: Bool = false
    @State private var selectedSpecialType: SpecialDayType?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("\(dates.count) Tage ausgewählt", systemImage: "calendar")
                        .foregroundStyle(.secondary)
                    if let first = dates.first, let last = dates.last {
                        Text("\(dateString(first)) – \(dateString(last))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if selectedSpecialType == nil {
                    Section {
                        Toggle("Homeoffice", isOn: $isHomeoffice)
                    }
                }

                Section("Besonderer Tag") {
                    ForEach(SpecialDayType.allCases) { type in
                        specialTypeRow(type)
                    }
                }
            }
            .navigationTitle("Tage bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(isHomeoffice, selectedSpecialType?.rawValue)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func specialTypeRow(_ type: SpecialDayType) -> some View {
        Button {
            if selectedSpecialType == type {
                selectedSpecialType = nil
            } else {
                selectedSpecialType = type
                isHomeoffice = false
            }
        } label: {
            HStack {
                Image(systemName: type.icon)
                    .frame(width: 24)
                    .foregroundStyle(iconColor(for: type))
                Text(type.label)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSpecialType == type {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func iconColor(for type: SpecialDayType) -> Color {
        switch type {
        case .vacation: return .orange
        case .sick: return .red
        case .publicHoliday: return .purple
        case .other: return .blue
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

// MARK: - Day Detail Sheet

private struct DayDetailSheet: View {
    let date: Date
    let existingWorkDay: WorkDay?
    let defaultIsHomeoffice: Bool
    let isWorkingDay: Bool
    let onSave: (Bool, String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isHomeoffice: Bool
    @State private var note: String
    @State private var selectedSpecialType: SpecialDayType?

    init(
        date: Date,
        existingWorkDay: WorkDay?,
        defaultIsHomeoffice: Bool = false,
        isWorkingDay: Bool = true,
        onSave: @escaping (Bool, String, String?) -> Void
    ) {
        self.date = date
        self.existingWorkDay = existingWorkDay
        self.defaultIsHomeoffice = defaultIsHomeoffice
        self.isWorkingDay = isWorkingDay
        self.onSave = onSave
        _isHomeoffice = State(initialValue: existingWorkDay?.isHomeoffice ?? defaultIsHomeoffice)
        _note = State(initialValue: existingWorkDay?.note ?? "")
        _selectedSpecialType = State(initialValue: existingWorkDay?.specialType.flatMap { SpecialDayType(rawValue: $0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                if isWorkingDay && selectedSpecialType == nil {
                    Section {
                        Toggle("Homeoffice", isOn: $isHomeoffice)
                    }
                }

                Section("Besonderer Tag") {
                    ForEach(SpecialDayType.allCases) { type in
                        specialTypeRow(type)
                    }
                }

                Section("Notiz (optional)") {
                    TextField("z. B. Jahresurlaub", text: $note)
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(isHomeoffice, note, selectedSpecialType?.rawValue)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func specialTypeRow(_ type: SpecialDayType) -> some View {
        Button {
            if selectedSpecialType == type {
                selectedSpecialType = nil
            } else {
                selectedSpecialType = type
                isHomeoffice = false
            }
        } label: {
            HStack {
                Image(systemName: type.icon)
                    .frame(width: 24)
                    .foregroundStyle(iconColor(for: type))
                Text(type.label)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSpecialType == type {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func iconColor(for type: SpecialDayType) -> Color {
        switch type {
        case .vacation: return .orange
        case .sick: return .red
        case .publicHoliday: return .purple
        case .other: return .blue
        }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd. MMMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Tips View

struct CalendarTipsView: View {
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.emerald)
                    .padding(.top, 28)
                Text("So bedienst du den Kalender")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)

            // Tip rows
            VStack(spacing: 0) {
                TipRow(
                    icon: "hand.tap",
                    iconColor: .emerald,
                    title: "Kurz tippen",
                    subtitle: "Homeoffice-Tag ein- oder austragen"
                )
                Divider().padding(.leading, 56)
                TipRow(
                    icon: "hand.tap.fill",
                    iconColor: .blue,
                    title: "Lang drücken",
                    subtitle: "Details bearbeiten: Notiz, Urlaub, Krankheit …"
                )
                Divider().padding(.leading, 56)
                TipRow(
                    icon: "pencil.circle",
                    iconColor: .orange,
                    title: "Stift neben dem Monatsnamen",
                    subtitle: "Aktiviert die Mehrfach-Auswahl — dann Tage wischen"
                )
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)

            Spacer()

            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Verstanden")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.emerald)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

private struct TipRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
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

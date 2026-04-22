import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkScheduleSettings.self) private var schedule
    @Query(filter: #Predicate<WorkDay> { _ in true })
    private var allDays: [WorkDay]

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date()).startOfMonth
    @State private var isPlanningMode: Bool = false

    // Multi-select drag
    @State private var cellFrames: [Date: CGRect] = [:]
    @State private var dragSelectedDates: Set<Date> = []
    @State private var multiSelectDates: [Date] = []

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.horizontal)
                    .padding(.bottom, 8)

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
                                onTap: { tappedDate in
                                    handleTap(on: tappedDate)
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

                Spacer()
            }
            .navigationTitle(monthTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPlanningMode.toggle()
                        if !isPlanningMode {
                            dragSelectedDates = []
                        }
                    } label: {
                        Label("Planung", systemImage: isPlanningMode ? "calendar.badge.checkmark" : "calendar.badge.plus")
                            .foregroundStyle(isPlanningMode ? Color.accentColor : .secondary)
                    }
                }
            }
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
                        handleTap(on: only)
                    }
                    return
                }
                multiSelectDates = dates
            }
    }

    // MARK: - Subviews

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
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

    @State private var selectedDay: DayEntry?

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

        // ISO weekday: Monday = 2, so offset = (weekday - 2 + 7) % 7
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

    private func handleTap(on date: Date) {
        guard date <= Date() || isPlanningMode else { return }
        selectedDay = DayEntry(
            date: date,
            workDay: workDay(for: date),
            defaultIsHomeoffice: schedule.isDefaultHomeoffice(date)
        )
    }

    private func saveDay(date: Date, isHomeoffice: Bool, note: String, specialType: String?, existing: WorkDay?) {
        if let existing {
            existing.isHomeoffice = isHomeoffice
            existing.note = note.isEmpty ? nil : note
            existing.specialType = specialType
        } else {
            let newDay = WorkDay(date: date, isHomeoffice: isHomeoffice, note: note.isEmpty ? nil : note, specialType: specialType)
            modelContext.insert(newDay)
        }
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
    let onTap: (Date) -> Void

    private var isFuture: Bool { date > Calendar.current.startOfDay(for: Date()) }
    private var dayNumber: String { "\(Calendar.current.component(.day, from: date))" }

    private var specialType: SpecialDayType? {
        guard let raw = workDay?.specialType else { return nil }
        return SpecialDayType(rawValue: raw)
    }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.2) }
        if let special = specialType {
            switch special {
            case .vacation: return Color.orange.opacity(0.25)
            case .sick: return Color.red.opacity(0.2)
            case .publicHoliday: return Color.purple.opacity(0.2)
            case .other: return Color.blue.opacity(0.15)
            }
        }
        guard isWorkingDay, let wd = workDay else { return .clear }
        return wd.isHomeoffice ? Color.green.opacity(0.25) : Color.gray.opacity(0.2)
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
        guard isWorkingDay, let wd = workDay else { return nil }
        return wd.isHomeoffice ? .green : .gray
    }

    var body: some View {
        Button {
            onTap(date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background)

                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                } else if Calendar.current.isDateInToday(date) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                }

                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.callout)
                        .foregroundStyle(isFuture && !isPlanningMode ? .tertiary : (isWorkingDay || specialType != nil ? .primary : .tertiary))
                    if let dot = dotColor {
                        Circle()
                            .fill(dot)
                            .frame(width: 5, height: 5)
                    }
                    if isFuture && isPlanningMode && specialType == nil && !isSelected {
                        Circle()
                            .fill(Color.accentColor.opacity(0.4))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .disabled(isFuture && !isPlanningMode)
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

// MARK: - Date extension

private extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}

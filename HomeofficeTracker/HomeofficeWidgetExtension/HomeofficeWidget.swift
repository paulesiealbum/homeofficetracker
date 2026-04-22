import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - WorkDay Model
//
// ⚠️ Diese Datei spiegelt WorkDay aus dem Haupt-Target.
//    Schema-Änderungen dort MÜSSEN hier synchron gemacht werden,
//    damit Widget und App dieselbe SQLite-Tabelle lesen.

@Model
final class WorkDay {
    var date: Date = Date.distantPast
    var isHomeoffice: Bool = false
    var note: String?
    var specialType: String?

    init(date: Date, isHomeoffice: Bool = false, note: String? = nil, specialType: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isHomeoffice = isHomeoffice
        self.note = note
        self.specialType = specialType
    }
}

// MARK: - Shared Container

/// Baut den ModelContainer auf dem App Group SQLite Store auf —
/// derselbe Store, den auch die Haupt-App verwendet.
@MainActor
let widgetModelContainer: ModelContainer = {
    let appGroupID = "group.com.paulweigt.homeofficetracker"
    let schema = Schema([WorkDay.self])

    if let storeURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
        .appendingPathComponent("homeoffice.sqlite"),
       let container = try? ModelContainer(
           for: schema,
           configurations: ModelConfiguration(schema: schema, url: storeURL)
       ) {
        return container
    }

    // Fallback: In-Memory (Widget zeigt Null-Werte, besser als Crash)
    return try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    )
}()

// MARK: - Tax Constants (gespiegelt — synchron mit TaxConstants im Haupt-Target halten)

private enum WidgetTax {
    static let ratePerDay: Double = 6.0
    static let maxDays: Int = 210

    static func savings(days: Int) -> Double {
        Double(min(days, maxDays)) * ratePerDay
    }
}

// MARK: - Emerald Color (lokal — kein Import aus Haupt-Target)

private extension Color {
    /// #34D399 — Hauptakzent, identisch mit AppTheme.swift
    static let emerald = Color(red: 0.204, green: 0.827, blue: 0.600)
}

// MARK: - Timeline Entry

struct HomeofficeEntry: TimelineEntry {
    let date: Date
    let isHomeofficeToday: Bool
    let hoCountThisYear: Int
    let savingsThisYear: Double
    let remainingDays: Int

    static let preview = HomeofficeEntry(
        date: .now,
        isHomeofficeToday: true,
        hoCountThisYear: 42,
        savingsThisYear: 252.0,
        remainingDays: 168
    )

    static let previewOff = HomeofficeEntry(
        date: .now,
        isHomeofficeToday: false,
        hoCountThisYear: 42,
        savingsThisYear: 252.0,
        remainingDays: 168
    )
}

// MARK: - Timeline Provider

struct HomeofficeProvider: TimelineProvider {

    func placeholder(in context: Context) -> HomeofficeEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeofficeEntry) -> Void) {
        Task { @MainActor in completion(makeEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeofficeEntry>) -> Void) {
        Task { @MainActor in
            let entry = makeEntry()
            // Nächste Aktualisierung kurz nach Mitternacht (Tageswechsel)
            let midnight = Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 0, minute: 1),
                matchingPolicy: .nextTime
            ) ?? Date().addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(midnight)))
        }
    }

    @MainActor
    private func makeEntry() -> HomeofficeEntry {
        let ctx = widgetModelContainer.mainContext
        let all = (try? ctx.fetch(FetchDescriptor<WorkDay>())) ?? []
        let year = Calendar.current.component(.year, from: Date())

        let todayIsHO = all.first {
            Calendar.current.isDateInToday($0.date)
        }?.isHomeoffice ?? false

        let count = all.filter {
            $0.isHomeoffice &&
            $0.specialType == nil &&
            Calendar.current.component(.year, from: $0.date) == year
        }.count

        return HomeofficeEntry(
            date: Date(),
            isHomeofficeToday: todayIsHO,
            hoCountThisYear: count,
            savingsThisYear: WidgetTax.savings(days: count),
            remainingDays: max(0, WidgetTax.maxDays - count)
        )
    }
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: HomeofficeEntry

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        entry.isHomeofficeToday
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color.emerald, Color.emerald.opacity(0.75)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(.systemGray4), Color(.systemGray5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: entry.isHomeofficeToday ? "house.fill" : "building.2.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text(entry.isHomeofficeToday ? "Homeoffice" : "Kein HO")
                .font(.caption.bold())
                .foregroundStyle(entry.isHomeofficeToday ? Color.emerald : .secondary)
                .lineLimit(1)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 4)

            HStack(spacing: 0) {
                VStack(spacing: 1) {
                    Text("\(entry.hoCountThisYear)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.emerald)
                    Text("Tage")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 1) {
                    Text(
                        entry.savingsThisYear,
                        format: .currency(code: "EUR").precision(.fractionLength(0))
                    )
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.emerald)
                    .minimumScaleFactor(0.75)
                    Text("gespart")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: HomeofficeEntry

    var body: some View {
        HStack(spacing: 0) {

            // Linkes Panel: heutiger Status + Toggle-Button
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            entry.isHomeofficeToday
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color.emerald, Color.emerald.opacity(0.75)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                              ))
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: entry.isHomeofficeToday ? "house.fill" : "building.2.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(entry.isHomeofficeToday ? "Homeoffice" : "Kein HO")
                    .font(.caption.bold())
                    .foregroundStyle(entry.isHomeofficeToday ? Color.emerald : .secondary)

                // Interaktiver Toggle (iOS 17+ Widget-Button)
                Button(intent: ToggleHomeofficIntent()) {
                    Text(entry.isHomeofficeToday ? "Entfernen" : "Eintragen")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            entry.isHomeofficeToday
                            ? Color.red.opacity(0.75)
                            : Color.emerald
                        )
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Rechtes Panel: Ersparnis + Fortschrittsbalken
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        entry.savingsThisYear,
                        format: .currency(code: "EUR").precision(.fractionLength(0))
                    )
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.emerald)

                    Text("gespart \(Calendar.current.component(.year, from: entry.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.emerald)
                                .frame(
                                    width: geo.size.width * min(Double(entry.hoCountThisYear) / 210.0, 1.0),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)

                    Text("\(entry.hoCountThisYear) / 210 Tage")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 12)
        }
        .padding(14)
    }
}

// MARK: - Entry View (Router)

struct HomeofficeWidgetView: View {
    let entry: HomeofficeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct HomeofficeWidget: Widget {
    let kind = "HomeofficeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeofficeProvider()) { entry in
            HomeofficeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Homeoffice Tracker")
        .description("Heutiger HO-Status und Jahresersparnis.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle Entry Point

@main
struct HomeofficeWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeofficeWidget()
    }
}

// MARK: - Previews

#Preview("Small – HO", as: .systemSmall) {
    HomeofficeWidget()
} timeline: {
    HomeofficeEntry.preview
}

#Preview("Small – Kein HO", as: .systemSmall) {
    HomeofficeWidget()
} timeline: {
    HomeofficeEntry.previewOff
}

#Preview("Medium – HO", as: .systemMedium) {
    HomeofficeWidget()
} timeline: {
    HomeofficeEntry.preview
}

#Preview("Medium – Kein HO", as: .systemMedium) {
    HomeofficeWidget()
} timeline: {
    HomeofficeEntry.previewOff
}

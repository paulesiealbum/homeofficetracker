import AppIntents
import SwiftData
import WidgetKit

/// Schaltet den heutigen Homeoffice-Status um.
///
/// Wird vom interaktiven Button im Medium-Widget aufgerufen.
/// Schreibt direkt in den App Group SwiftData Store und löst
/// danach ein Widget-Reload aus, damit die UI sofort aktuell ist.
struct ToggleHomeofficIntent: AppIntent {

    static var title: LocalizedStringResource = "Homeoffice umschalten"
    static var description = IntentDescription("Heutigen Homeoffice-Tag ein- oder austragen.")

    /// Nicht in der Shortcuts-App anzeigen — rein für Widget-interne Nutzung.
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let ctx = widgetModelContainer.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        let all = (try? ctx.fetch(FetchDescriptor<WorkDay>())) ?? []

        if let existing = all.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existing.isHomeoffice.toggle()
        } else {
            ctx.insert(WorkDay(date: today, isHomeoffice: true))
        }
        try? ctx.save()

        // Widget sofort neu rendern
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

import Foundation

/// Eine Arbeitsstätten-Periode für die Pendlerpauschale.
///
/// Deckt zwei steuerliche Szenarien ab:
/// - **Arbeitgeberwechsel**: Zwei Einträge mit nicht-überlappenden Zeiträumen (startDate/endDate)
/// - **Mehrere Dienstverhältnisse gleichzeitig**: Mehrere Einträge ohne Zeitraum-Einschränkung;
///   jedes Dienstverhältnis berechtigt zur eigenen vollen Pendlerpauschale
///   (§9 Abs. 4 Satz 5 EStG: „je Dienstverhältnis höchstens eine erste Tätigkeitsstätte").
struct WorkplacePeriod: Codable, Identifiable {
    var id: UUID
    /// Optionaler Name, z.B. „Hauptarbeitgeber", „Nebenjob"
    var label: String
    /// Einfache Entfernung Wohnung – Büro in km (kürzeste Straßenverbindung gemäß EStG)
    var commuteKm: Int
    /// Wohnadresse (nur lokal, wird nie übertragen)
    var homeAddress: String
    /// Arbeitsadresse (nur lokal, wird nie übertragen)
    var workAddress: String
    /// Beginn der Beschäftigung in diesem Steuerjahr (nil = ab Jahresbeginn)
    var startDate: Date?
    /// Ende der Beschäftigung in diesem Steuerjahr (nil = bis Jahresende / laufend)
    var endDate: Date?
    /// Manuelle Bürotage-Eingabe (nil = automatisch aus Kalender zählen)
    /// Sinnvoll bei mehreren gleichzeitigen Dienstverhältnissen, wenn der Kalender
    /// die Tage pro Arbeitgeber nicht getrennt erfasst.
    var manualOfficeDays: Int?

    /// Verwendetes Verkehrsmittel — entscheidend für den Jahreshöchstbetrag.
    /// PKW/Motorrad (.car): kein Cap (§9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG).
    /// ÖPNV (.transit): Cap 4.500 € oder tatsächliche Ticketkosten.
    /// Fahrrad/Fuß (.bicycle): Cap 4.500 € gilt.
    /// Default: .car (konservativster Fall, da Cap dann NICHT gilt — höchste Absetzbarkeit).
    var transportMode: TransportMode

    init(
        id: UUID = UUID(),
        label: String = "",
        commuteKm: Int = 0,
        homeAddress: String = "",
        workAddress: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        manualOfficeDays: Int? = nil,
        transportMode: TransportMode = .car
    ) {
        self.id = id
        self.label = label
        self.commuteKm = commuteKm
        self.homeAddress = homeAddress
        self.workAddress = workAddress
        self.startDate = startDate
        self.endDate = endDate
        self.manualOfficeDays = manualOfficeDays
        self.transportMode = transportMode
    }

    /// Anzeigename für die UI (Fallback wenn kein Label gesetzt)
    var displayLabel: String {
        label.isEmpty ? "Arbeitsstätte" : label
    }

    /// Zeitraum-Beschreibung für die UI, z.B. „01.01. – 30.06." oder „ab 01.07."
    var periodDescription: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM."
        formatter.locale = Locale(identifier: "de_DE")
        if let start = startDate, let end = endDate {
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        } else if let start = startDate {
            return "ab \(formatter.string(from: start))"
        } else if let end = endDate {
            return "bis \(formatter.string(from: end))"
        }
        return nil
    }
}

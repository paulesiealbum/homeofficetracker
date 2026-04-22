import Foundation

enum SpecialDayType: String, CaseIterable, Identifiable {
    case vacation = "vacation"
    case sick = "sick"
    case publicHoliday = "publicHoliday"
    case other = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vacation: return "Urlaub"
        case .sick: return "Krank"
        case .publicHoliday: return "Feiertag"
        case .other: return "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .vacation: return "beach.umbrella"
        case .sick: return "cross.case"
        case .publicHoliday: return "star"
        case .other: return "ellipsis.circle"
        }
    }
}

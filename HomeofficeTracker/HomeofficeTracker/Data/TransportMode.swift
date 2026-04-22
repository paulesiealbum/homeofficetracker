// TransportMode.swift
// Verkehrsmittel für die Entfernungspauschale.
// Rechtsgrundlage: § 9 Abs. 1 Satz 3 Nr. 4 EStG
//
// ⚠️ ENTSCHEIDEND:
// - PKW / Motorrad:  Cap 4.500 € gilt NICHT — voller Pauschalbetrag absetzbar
//   (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG: „ein höherer Betrag als 4.500 Euro
//    ist anzusetzen, soweit der Arbeitnehmer einen eigenen oder ihm zur Nutzung
//    überlassenen Kraftwagen benutzt.")
// - ÖPNV:            Cap 4.500 € gilt; alternativ tatsächliche Ticketkosten
//                    wenn diese höher sind (§ 9 Abs. 1 Satz 3 Nr. 4a EStG)
// - Fahrrad / Fuß:   Cap 4.500 € gilt — kein Kraftfahrzeug, keine Ausnahme

import Foundation

enum TransportMode: String, Codable, CaseIterable, Identifiable {

    /// PKW oder Motorrad — kein Jahreshöchstbetrag (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG)
    case car     = "car"

    /// Bus, Bahn, U-Bahn etc. — Jahreshöchstbetrag 4.500 € oder tatsächliche Kosten
    case transit = "transit"

    /// Fahrrad oder zu Fuß — Jahreshöchstbetrag 4.500 € gilt
    case bicycle = "bicycle"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .car:     return "PKW / Motorrad"
        case .transit: return "ÖPNV (Bus, Bahn, U-Bahn)"
        case .bicycle: return "Fahrrad / zu Fuß"
        }
    }

    var icon: String {
        switch self {
        case .car:     return "car.fill"
        case .transit: return "tram.fill"
        case .bicycle: return "bicycle"
        }
    }

    /// True wenn der Jahreshöchstbetrag von 4.500 € NICHT gilt.
    /// Nur bei Kraftfahrzeugen (PKW, Motorrad) per § 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG.
    var capExempt: Bool { self == .car }

    /// Rechtlicher Hinweis für PDF-Export und UI
    var legalNote: String {
        switch self {
        case .car:
            return "PKW/Motorrad: Kein Jahreshöchstbetrag — voller Pauschalbetrag absetzbar (§ 9 Abs. 1 Satz 3 Nr. 4 Satz 2 EStG)."
        case .transit:
            return "ÖPNV: Jahreshöchstbetrag 4.500 € (§ 9 Abs. 1 Satz 3 Nr. 4 EStG). Tatsächliche Ticketkosten können alternativ angesetzt werden, wenn diese höher sind (§ 9 Abs. 1 Satz 3 Nr. 4a EStG)."
        case .bicycle:
            return "Fahrrad/zu Fuß: Jahreshöchstbetrag 4.500 € gilt (kein motorisiertes Fahrzeug, keine Ausnahme nach Satz 2)."
        }
    }
}

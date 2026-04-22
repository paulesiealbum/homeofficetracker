// FederalState.swift
// Bundesland-Auswahl für regionalen Feiertagskalender (DACH).

import Foundation

enum FederalState: String, CaseIterable, Identifiable, Codable {
    // Deutschland
    case bw = "BW"
    case by = "BY"
    case be = "BE"
    case bb = "BB"
    case hb = "HB"
    case hh = "HH"
    case he = "HE"
    case mv = "MV"
    case ni = "NI"
    case nw = "NW"
    case rp = "RP"
    case sl = "SL"
    case sn = "SN"
    case st = "ST"
    case sh = "SH"
    case th = "TH"
    // Österreich
    case at = "AT"
    // Schweiz
    case ch = "CH"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bw: return "Baden-Württemberg"
        case .by: return "Bayern"
        case .be: return "Berlin"
        case .bb: return "Brandenburg"
        case .hb: return "Bremen"
        case .hh: return "Hamburg"
        case .he: return "Hessen"
        case .mv: return "Mecklenburg-Vorpommern"
        case .ni: return "Niedersachsen"
        case .nw: return "Nordrhein-Westfalen"
        case .rp: return "Rheinland-Pfalz"
        case .sl: return "Saarland"
        case .sn: return "Sachsen"
        case .st: return "Sachsen-Anhalt"
        case .sh: return "Schleswig-Holstein"
        case .th: return "Thüringen"
        case .at: return "Österreich"
        case .ch: return "Schweiz"
        }
    }

    var country: String {
        switch self {
        case .at: return "AT"
        case .ch: return "CH"
        default: return "DE"
        }
    }

    /// Alle deutschen Bundesländer, dann AT, CH
    static var germanStates: [FederalState] {
        [.bw, .by, .be, .bb, .hb, .hh, .he, .mv, .ni, .nw, .rp, .sl, .sn, .st, .sh, .th]
    }

    static var dachStates: [FederalState] {
        germanStates + [.at, .ch]
    }
}

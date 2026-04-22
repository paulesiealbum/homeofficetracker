import SwiftUI

// MARK: - Design Token System
// "Calm Finance" — Emerald + Adaptive Materials
// Alle Design-Entscheidungen zentral hier dokumentiert.

// MARK: - Color Tokens

extension Color {
    /// #34D399 — Emerald Green, Hauptakzent (Geld = Grün, modern + nicht kitschy)
    static let emerald = Color(red: 0.204, green: 0.827, blue: 0.600)
}

// MARK: - Glass Card Modifier

/// Gibt Views eine abgerundete Karte mit adaptivem Hintergrund und
/// optionalem farbigen Rahmen. Funktioniert korrekt in Light & Dark Mode.
struct GlassCardStyle: ViewModifier {
    var tint: Color
    var tintOpacity: Double
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(tint.opacity(tintOpacity), lineWidth: 1.5)
            )
    }
}

extension View {
    /// Adaptive Karte: `secondarySystemBackground` + optionaler farbiger Rahmen.
    func glassCard(
        tint: Color = .primary,
        tintOpacity: Double = 0.10,
        radius: CGFloat = 20
    ) -> some View {
        modifier(GlassCardStyle(tint: tint, tintOpacity: tintOpacity, cornerRadius: radius))
    }
}

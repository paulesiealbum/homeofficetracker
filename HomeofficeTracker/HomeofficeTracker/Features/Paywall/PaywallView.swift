import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitService.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var price: String {
        store.subscriptionProduct.map { "\($0.displayPrice)/Jahr" } ?? "2,99 €/Jahr"
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────────
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.emerald.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(Color.emerald)
                }
                .padding(.top, 28)

                Text("Premium freischalten")
                    .font(.title2.bold())
                Text("Alle Features für \(price).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)

            // ── Feature List ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                PaywallFeatureRow(icon: "doc.richtext",  color: .emerald, title: "PDF & CSV Export",       subtitle: "Finanzamtstauglich, direkt für den Steuerberater")
                Divider().padding(.leading, 52)
                PaywallFeatureRow(icon: "car.fill",       color: .blue,   title: "Pendlerpauschale",        subtitle: "Automatische Berechnung je Arbeitsstätte")
                Divider().padding(.leading, 52)
                PaywallFeatureRow(icon: "building.2",     color: .purple, title: "Mehrere Arbeitsstätten",  subtitle: "Für Arbeitgeberwechsel oder Nebenjobs")
                Divider().padding(.leading, 52)
                PaywallFeatureRow(icon: "wand.and.stars", color: .orange, title: "Wochenmuster Auto-Fill",  subtitle: "Zukünftige Tage automatisch ausfüllen")
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .padding(.bottom, 20)

            // ── Preisbox ──────────────────────────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Premium Jahres-Abo")
                        .font(.subheadline.weight(.semibold))
                    Text("Kündigung jederzeit möglich")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.emerald)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.emerald.opacity(0.07))
                    .strokeBorder(Color.emerald.opacity(0.4), lineWidth: 1.5)
            )
            .padding(.horizontal)
            .padding(.bottom, 16)

            // ── CTA ───────────────────────────────────────────────────────────
            Button {
                isPurchasing = true
                Task {
                    do {
                        try await store.purchaseSubscription()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    isPurchasing = false
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Für \(price) abonnieren")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.emerald)
            .disabled(isPurchasing)
            .padding(.horizontal)

            // ── Restore & Cancel ──────────────────────────────────────────────
            HStack(spacing: 16) {
                Button("Kauf wiederherstellen") {
                    Task { await store.restore() }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Text("·").foregroundStyle(.tertiary)

                Button("Vielleicht später") { dismiss() }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .task { await store.load() }
        .onChange(of: store.hasAnyPremium) { _, active in
            if active { dismiss() }
        }
        .alert("Fehler", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Der Kauf konnte nicht abgeschlossen werden.")
        }
    }
}

// MARK: - Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

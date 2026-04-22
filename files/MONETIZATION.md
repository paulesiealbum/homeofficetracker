# MONETIZATION.md — Homeoffice-Tracker

## Preismodell

**Jahres-Abo: 2,99 €/Jahr** (Auto-Renewable Subscription)

Kein Einmalkauf. Das Jahres-Abo passt ideal zum jährlichen Steuerkontext der App und vermeidet jegliche Verwirrung beim Nutzer: ein klarer Preis, ein klares Modell, Kündigung jederzeit möglich.

---

## Premium-Features (hinter Paywall)

| Feature | Beschreibung |
|---|---|
| PDF & CSV Export | Steuerdokument für Steuerberater / Finanzamt |
| Pendlerpauschale | Automatische Berechnung je Arbeitsstätte (§9 Abs. 1 Nr. 4 EStG) |
| Mehrere Arbeitsstätten | Für Arbeitgeberwechsel oder Nebenjobs |
| Wochenmuster Auto-Fill | Zukünftige Tage automatisch nach Muster befüllen |

---

## StoreKit 2 Setup

### App Store Connect

1. In App Store Connect → Deine App → In-App-Käufe → **Abonnements** → neue Abo-Gruppe anlegen
2. Abo-Gruppe: `Homeoffice Tracker Premium` (ID: `com.Paul.HomeofficeTracker.premium`)
3. Neues Abonnement innerhalb der Gruppe:
   - **Product ID:** `com.Paul.HomeofficeTracker.premium.annual`
   - **Laufzeit:** 1 Jahr
   - **Preis:** Stufe 3 (2,99 €/Jahr)
   - **Lokalisierung DE:** „Premium Jahres-Abo" / „Schaltet alle Premium-Features frei. Kündigung jederzeit."
4. Abo-Review-Screenshot bereitstellen (Paywall-Screenshot)

### Xcode: StoreKit Configuration File (für Sandbox-Testing)

1. `HomeofficeTracker.storekit` ist bereits konfiguriert
2. Schema auswählen → Edit Scheme → Run → Options → **StoreKit Configuration** → `HomeofficeTracker.storekit`

### Swift Implementation

```swift
// Core/Constants.swift
enum TaxConstants {
    /// Premium Jahres-Abo: 2,99 €/Jahr — alle Features inklusive.
    static let subscriptionID = "com.Paul.HomeofficeTracker.premium.annual"
}

// Features/Paywall/StoreKitService.swift
import StoreKit
import Observation

@Observable
final class StoreKitService {
    static let shared = StoreKitService()
    private init() {}

    var isSubscribed = false
    var subscriptionProduct: Product?

    var hasAnyPremium: Bool { isSubscribed }

    func load() async {
        let products = try? await Product.products(for: [TaxConstants.subscriptionID])
        subscriptionProduct = products?.first
        await checkStatus()
    }

    func checkStatus() async {
        var subscribed = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == TaxConstants.subscriptionID {
                if let expiry = tx.expirationDate {
                    subscribed = expiry > Date() && tx.revocationDate == nil
                } else {
                    subscribed = tx.revocationDate == nil
                }
            }
        }
        isSubscribed = subscribed
    }

    func purchaseSubscription() async throws {
        guard let sub = subscriptionProduct else { return }
        let result = try await sub.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            isSubscribed = true
            await tx.finish()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await checkStatus()
    }
}
```

### PaywallView (Karte)

```swift
// Preisanzeige mit "/Jahr"-Suffix aus StoreKit
private var price: String {
    store.subscriptionProduct?.displayPrice.map { "\($0)/Jahr" } ?? "2,99 €/Jahr"
}

// Preisbox zeigt: "Premium Jahres-Abo · Kündigung jederzeit möglich"
// CTA-Button: "Für 2,99 €/Jahr abonnieren"
// Restore-Button: "Kauf wiederherstellen" (Apple-Pflicht)
```

---

## Revenue-Projektion

| Szenario | Downloads/Monat | Conversion | Revenue/Monat |
|---|---|---|---|
| Konservativ | 200 | 15% | ~90 € |
| Realistisch | 600 | 20% | ~360 € |
| Stark | 2.000 | 25% | ~1.500 € |

> **Saisoneffekt:** Steuersaison Januar–Mai generiert 3–4× normalen Traffic.
> Launch idealerweise **Dezember/Januar** zur Steuersaison.
> **Abo-Renewal:** Bestehende Abonnenten verlängern automatisch — stabiler Basisumsatz ab Jahr 2.

---

## App Store Pricing

- **Preisstufe:** Tier 3 = 2,99 € (App Store Connect wählt AT/CH-Preise automatisch)
- **Modell:** Auto-Renewable Subscription, Jahresintervall
- **Kündigung:** Jederzeit über iOS-Einstellungen → keine Support-Anfragen

---

## Paywall-UX Regeln

- Paywall wird **nicht** beim App-Start gezeigt (kein Aggressive-Gating)
- Paywall erscheint beim **ersten Versuch** eine Premium-Funktion zu nutzen
- "Vielleicht später" immer sichtbar (App Store Guideline 3.1.1)
- **Restore-Button** immer vorhanden (App Review Pflicht bei Abos)
- Preis dynamisch via `subscriptionProduct.displayPrice` aus StoreKit laden — nie hardcoded

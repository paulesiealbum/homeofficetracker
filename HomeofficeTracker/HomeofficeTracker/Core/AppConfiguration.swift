import Foundation
import Observation

/// Central feature switch for Free/Premium tier.
/// Combines compile-time build flag (FREE_TIER) with StoreKit runtime status.
///
/// ⚠️ Build Config für App Store Submission:
///   - App Store Submit → "Release" Config verwenden (kein Flag gesetzt, StoreKit-Runtime entscheidet)
///   - "Free" Config    → FREE_TIER fest = false  → NUR für interne Builds ohne Kauf-Flow
///   - "Premium" Config → PREMIUM_TIER fest = true → NUR für TestFlight-Tester / interne QA
///
/// Usage in SwiftUI:
/// ```swift
/// if AppConfig.shared.isPremium {
///     PremiumView()
/// } else {
///     FreeView()
/// }
/// ```
@Observable
final class AppConfig {
    static let shared = AppConfig()
    private init() {}

    /// True when premium features are available.
    /// Basiert ausschließlich auf dem aktiven Jahres-Abo (2,99 €/Jahr).
    var isPremium: Bool {
        #if FREE_TIER
        return false
        #elseif PREMIUM_TIER
        return true
        #else
        return StoreKitService.shared.isSubscribed
        #endif
    }

    /// True when this binary was compiled as the Free tier.
    static var isFreeTierBuild: Bool {
        #if FREE_TIER
        return true
        #else
        return false
        #endif
    }
}

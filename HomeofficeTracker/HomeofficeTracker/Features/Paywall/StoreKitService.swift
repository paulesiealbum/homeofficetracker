import StoreKit
import Observation

@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    private init() {}

    /// Aktives Premium-Jahres-Abo (2,99 €/Jahr).
    var isSubscribed = false
    var subscriptionProduct: Product?

    var hasAnyPremium: Bool { isSubscribed }

    /// Muss einmalig beim App-Start aufgerufen werden.
    /// Lauscht auf Transaction.updates (Renewals, Rückerstattungen, Käufe von anderen Geräten).
    @discardableResult
    func startTransactionListener() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    if tx.productID == TaxConstants.subscriptionID {
                        if let expiry = tx.expirationDate {
                            self.isSubscribed = expiry > Date() && tx.revocationDate == nil
                        } else {
                            self.isSubscribed = tx.revocationDate == nil
                        }
                        await tx.finish()
                    }
                }
            }
        }
    }

    func load() async {
        do {
            let products = try await Product.products(for: [TaxConstants.subscriptionID])
            subscriptionProduct = products.first
        } catch {
            print("StoreKit load error: \(error)")
        }
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
        switch result {
        case .success(let verification):
            if case .verified(let tx) = verification {
                isSubscribed = true
                await tx.finish()
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await checkStatus()
    }

    var isPremium: Bool {
        AppConfig.shared.isPremium
    }

    // Legacy-Kompatibilität (wird von SettingsView referenziert)
    var isPurchased: Bool { false }
}

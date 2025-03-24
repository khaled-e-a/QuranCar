import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isSubscribed = false
    @Published private(set) var isTrialEligible = true

    private let productID = "elm.qurancar.premiummonthly"
    private var updates: Task<Void, Never>? = nil

    init() {
        // Start transaction updates
        updates = observeTransactionUpdates()

        // Load product immediately
        Task {
            Logger.debug("StoreManager: Starting initial product fetch")
            await fetchProduct()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updates?.cancel()
    }

    // Fetch premium product
    func fetchProduct() async {
        do {
            Logger.debug("StoreManager: Fetching subscription product for ID: \(productID)")

            let products = try await Product.products(for: [productID])
            Logger.debug("StoreManager: Found \(products.count) products")

            for product in products {
                Logger.debug("StoreManager: Available product - ID: \(product.id), Type: \(product.type), Name: \(product.displayName)")
            }

            await MainActor.run {
                self.premiumProduct = products.first { product in
                    // Verify it's our subscription product
                    product.id == productID && product.type == .autoRenewable
                }

                if let product = self.premiumProduct {
                    Logger.debug("StoreManager: Loaded premium product: \(product.displayName) - \(product.displayPrice)")
                } else {
                    Logger.debug("StoreManager: No matching product found for ID: \(productID)")
                }
            }
        } catch {
            Logger.error("StoreManager: Failed to load product: \(error)")
            Logger.error("StoreManager: Error details - \(String(describing: error))")
        }
    }

    // Purchase premium subscription
    func purchase() async {
        guard let product = premiumProduct else {
            Logger.debug("StoreManager: No product available")
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    // Update subscription status
                    isSubscribed = true
                    // Finish the transaction
                    await transaction.finish()
                }
            case .pending:
                Logger.debug("StoreManager: Purchase pending")
            case .userCancelled:
                Logger.debug("StoreManager: Purchase cancelled")
            @unknown default:
                break
            }
        } catch {
            Logger.error("StoreManager: Purchase failed: \(error)")
        }
    }

    // Observe transaction updates
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verification in Transaction.updates {
                if let transaction = try? verification.payloadValue {
                    // Update subscription status
                    isSubscribed = true
                    // Finish the transaction
                    await transaction.finish()
                }
            }
        }
    }

    // Check subscription status
    private func checkSubscriptionStatus() async {
        for await result in await Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                if transaction.productID == productID {
                    isSubscribed = true
                    break
                }
            }
        }

        // Check if user is eligible for trial
        if let product = premiumProduct,
           let subscription = product.subscription {
            isTrialEligible = await subscription.isEligibleForIntroOffer
        }
    }
}

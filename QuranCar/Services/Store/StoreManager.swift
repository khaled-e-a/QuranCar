import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isSubscribed = false
    @Published private(set) var isTrialEligible = true
    @Published private(set) var hadiyaExpiryDate: Date?

    var isPremiumActive: Bool {
        return isSubscribed || (hadiyaExpiryDate != nil && hadiyaExpiryDate! > Date())
    }

    private let productID = "elm.qurancar.premiummonthly"
    private var updates: Task<Void, Never>? = nil
    private let defaults = UserDefaults.standard

    private enum UserDefaultsKeys {
        static let hadiyaGrantDate = "hadiyaGrantDate"
        static let hadiyaExpiryDate = "hadiyaExpiryDate"
    }

    init() {
        // Load Hadiya status
        if let expiryTime = defaults.object(forKey: UserDefaultsKeys.hadiyaExpiryDate) as? Double {
            self.hadiyaExpiryDate = Date(timeIntervalSince1970: expiryTime)
        }

        // Start transaction updates
        updates = observeTransactionUpdates()

        // Load product immediately
        Task {
            Logger.debug("StoreManager: Starting initial product fetch")
            await fetchProduct()
            await checkSubscriptionStatus()
            await checkHadiyaStatus()
        }
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - Hadiya Program

    func grantHadiyaSubscription() {
        let now = Date()
        let calendar = Calendar.current
        guard let expiryDate = calendar.date(byAdding: .year, value: 1, to: now) else {
            Logger.error("StoreManager: Failed to calculate Hadiya expiry date")
            return
        }

        defaults.set(now.timeIntervalSince1970, forKey: UserDefaultsKeys.hadiyaGrantDate)
        defaults.set(expiryDate.timeIntervalSince1970, forKey: UserDefaultsKeys.hadiyaExpiryDate)
        
        self.hadiyaExpiryDate = expiryDate
        Logger.info("StoreManager: Hadiya granted until \(expiryDate)")
    }

    func checkHadiyaStatus() async {
        if let expiryDate = hadiyaExpiryDate, expiryDate <= Date() {
            Logger.info("StoreManager: Hadiya has expired")
            await MainActor.run {
                self.hadiyaExpiryDate = nil
            }
        }
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

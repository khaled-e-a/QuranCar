import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var supportProduct: Product?
    @Published private(set) var isSubscribed = false

    private let productID = "elm.qurancar.subscription.support"
    private var updates: Task<Void, Never>? = nil

    init() {
        // Start transaction updates
        updates = observeTransactionUpdates()

        // Load product immediately
        Task {
            print("StoreManager: Starting initial product fetch")
            await fetchProduct()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updates?.cancel()
    }

    // Fetch support product
    func fetchProduct() async {
        do {
            print("StoreManager: Fetching subscription product for ID: \(productID)")

            let products = try await Product.products(for: [productID])
            print("StoreManager: Found \(products.count) products")

            for product in products {
                print("StoreManager: Available product - ID: \(product.id), Type: \(product.type), Name: \(product.displayName)")
            }

            await MainActor.run {
                self.supportProduct = products.first { product in
                    // Verify it's our subscription product
                    product.id == productID && product.type == .nonRenewable
                }

                if let product = self.supportProduct {
                    print("StoreManager: Loaded support product: \(product.displayName) - \(product.displayPrice)")
                } else {
                    print("StoreManager: No matching product found for ID: \(productID)")
                }
            }
        } catch {
            print("StoreManager: Failed to load product: \(error)")
            print("StoreManager: Error details - \(String(describing: error))")
        }
    }

    // Purchase support
    func purchase() async {
        guard let product = supportProduct else {
            print("StoreManager: No product available")
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    // Update subscription status
                    isSubscribed = true
                    // Save purchase date
                    UserDefaults.standard.set(transaction.purchaseDate, forKey: "support_purchase_date")
                    // Finish the transaction
                    await transaction.finish()
                }
            case .pending:
                print("StoreManager: Purchase pending")
            case .userCancelled:
                print("StoreManager: Purchase cancelled")
            @unknown default:
                break
            }
        } catch {
            print("StoreManager: Purchase failed: \(error)")
        }
    }

    // Observe transaction updates
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verification in Transaction.updates {
                if let transaction = try? verification.payloadValue {
                    // Update subscription status
                    isSubscribed = true
                    // Save purchase date
                    UserDefaults.standard.set(transaction.purchaseDate, forKey: "support_purchase_date")
                    // Finish the transaction
                    await transaction.finish()
                }
            }
        }
    }

    // Check subscription status
    private func checkSubscriptionStatus() async {
        // For non-renewing subscriptions, we'll consider them "subscribed" if they've ever purchased
        if let _ = UserDefaults.standard.object(forKey: "support_purchase_date") {
            isSubscribed = true
        }
    }
}

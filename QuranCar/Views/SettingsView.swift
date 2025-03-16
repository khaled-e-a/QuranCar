import SwiftUI

struct SettingsView: View {
    @StateObject private var storeManager = StoreManager.shared
    @State private var showingThankYou = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 32) {
                // Support Development Section
                SupportDevelopmentCard()
                    .padding(.horizontal)

                // Coming Soon Section
                ComingSoonCard()
                    .padding(.horizontal)

                // Privacy Policy Section
                VStack(spacing: 0) {
                    Link(destination: URL(string: "https://elm.academy/qurancar/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.textBody)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(Color.textBodySubtle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.background2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .padding(.bottom, 20)
        }
        .background(Color.background1)
        .navigationTitle("Settings")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Thank You!", isPresented: $showingThankYou) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for supporting QuranCar! Your contribution helps us continue developing and improving the app.")
        }
    }
}

struct SupportDevelopmentCard: View {
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            // Title
            Text("Support QuranCar")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text("Help us continue developing and improving QuranCar. Jazakum Allah Khairan!")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            if let product = storeManager.supportProduct {
                if storeManager.isSubscribed {
                    Text("Jazakum Allah Khairan for your support! ❤️")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                } else {
                    Button {
                        Task {
                            await storeManager.purchase()
                        }
                    } label: {
                        HStack {
                            Text("Support Development")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text(product.displayPrice)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                if isRetrying {
                    ProgressView()
                        .tint(.white)
                } else {
                    Button {
                        isRetrying = true
                        Task {
                            await storeManager.fetchProduct()
                            isRetrying = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry Loading")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryNormal,
                    Color.primaryHover
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(radius: 8, y: 2)
        .onAppear {
            if storeManager.supportProduct == nil {
                Task {
                    await storeManager.fetchProduct()
                }
            }
        }
    }
}

struct ComingSoonCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(.white)

            // Title
            Text("More Features Coming Soon!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bookmark.fill", text: "Save memorization loops")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                FeatureRow(icon: "person.2.fill", text: "Share with friends")
                FeatureRow(icon: "ellipsis.circle.fill", text: "And more to come...")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryNormal,
                    Color.primaryHover
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(radius: 8, y: 2)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

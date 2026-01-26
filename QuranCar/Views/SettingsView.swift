import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingThankYou = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @State private var showingOnboarding = false
    @State private var showingPermissionAlert = false
    @Binding var selectedTab: Tab

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 32) {
                // Premium Subscription Section
                VStack(spacing: 24) {
                    PremiumSubscriptionCard()
                    ComingSoonCard()
                }
                .padding(.horizontal)

                // Notifications Section
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(Color.textBodySubtle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminder Notifications")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.textBody)
                            Text("Get reminded to continue your memorization")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textBodySubtle)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { notificationManager.isNotificationEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        let granted = await notificationManager.enableNotifications()
                                        if !granted {
                                            showingPermissionAlert = true
                                        }
                                    }
                                } else {
                                    notificationManager.disableNotifications()
                                }
                            }
                        ))
                        .tint(Color.primaryNormal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.background2)
                    .contentShape(Rectangle())

                    // Permission status
                    if notificationManager.authorizationStatus == .denied {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.warningNormal)
                            Text("Notifications are disabled in Settings")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textBodySubtle)
                            Spacer()
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.primaryNormal)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.background2)
                    }

                    Divider()
                        .background(Color.stroke1)

                    // Tutorial Section
                    Button(action: {
                        if hasSeenOnboarding {
                            selectedTab = .memorize
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: .showCoachMarks,
                                    object: nil
                                )
                            }
                        } else {
                            showingOnboarding = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color.textBodySubtle)
                            Text("Restart Tutorial")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.textBody)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(Color.textBodySubtle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.background2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .background(Color.stroke1)

                    // Privacy Policy Link
                    Link(destination: URL(string: "https://elm.academy/qurancar/privacy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(Color.textBodySubtle)
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
            Text("Thank you for subscribing to Quran Car Premium! You now have access to all reciters.")
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Please enable notifications in Settings to receive reminders about your memorization journey.")
        }
        .onAppear {
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(showOnboarding: $showingOnboarding) {
                selectedTab = .memorize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: .showCoachMarks,
                        object: nil
                    )
                }
            }
        }
    }
}

struct PremiumSubscriptionCard: View {
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            // Title
            Text("Quran Car Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text("Get access to all reciters, remove ads, and unlock the full potential of Quran Car")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            if let product = storeManager.premiumProduct {
                if storeManager.isSubscribed {
                    Text("Premium Active")
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
                            Text(storeManager.isTrialEligible ? "Start 7-Day Free Trial" : "Subscribe Now")
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
            if storeManager.premiumProduct == nil {
                Task {
                    await storeManager.fetchProduct()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView(selectedTab: .constant(.memorize))
    }
}

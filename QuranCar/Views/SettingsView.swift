import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingThankYou = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @State private var showingOnboarding = false
    @State private var showingPermissionAlert = false
    @State private var showingPremiumSheet = false
    @Binding var selectedTab: Tab

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 32) {
                // Premium Subscription Section
                VStack(spacing: 24) {
                    PremiumSubscriptionCard()
                }
                .padding(.horizontal)

                // Notifications Section
                VStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        // Text content that fills available width
                        HStack(spacing: 12) {
                            Image(systemName: "bell")
                                .foregroundColor(Color.textBodySubtle)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder Notifications")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(Color.textBody)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Get reminded to continue your memorization if you've been away for 3 days.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.textBodySubtle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 60) // Reserve space for toggle
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Toggle positioned on the right
                        Toggle("", isOn: Binding(
                            get: { notificationManager.isNotificationEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        let granted = await notificationManager.enableNotifications()
                                        if !granted && notificationManager.authorizationStatus == .denied {
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

                    // Playback Speed Section
                    Button(action: {
                        if !storeManager.isPremiumActive {
                            showingPremiumSheet = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "speedometer")
                                .foregroundColor(Color.textBodySubtle)
                                .frame(width: 24)

                            Text("Playback Speed")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.textBody)

                            if !storeManager.isPremiumActive {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textBodySubtle)
                            }

                            Spacer()

                            if storeManager.isPremiumActive {
                                Menu {
                                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                                        Button(action: {
                                            audioManager.setPlaybackSpeed(Float(speed))
                                        }) {
                                            HStack {
                                                Text(String(format: "%.2fx", speed))
                                                if Float(speed) == audioManager.playbackSpeed {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(String(format: "%.2fx", audioManager.playbackSpeed))
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(Color.primaryNormal)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.textBodySubtle)
                                    }
                                }
                            } else {
                                Text(String(format: "%.2fx", audioManager.playbackSpeed))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(Color.textBodySubtle)
                            }
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

//                // Coming Soon Section
//                VStack(spacing: 24) {
//                    ComingSoonCard()
//                }
//                .padding(.horizontal)
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
        .sheet(isPresented: $showingPremiumSheet) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        PremiumSubscriptionCard()
                        // ComingSoonCard()
                    }
                    .padding()
                }
                .background(Color.background1)
                .navigationTitle("Premium")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingPremiumSheet = false
                        }
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color.primaryNormal)
                    }
                }
            }
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
    @EnvironmentObject private var storeManager: StoreManager
    @State private var isRetrying = false
    @State private var showingHadiyaSheet = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            // Title
            Text("Quran Car Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text("Support the development of this app, get access to all reciters, and unlock the full potential of Quran Car")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            if let product = storeManager.premiumProduct {
                if storeManager.isPremiumActive {
                    VStack(spacing: 8) {
                        Text("Premium Active")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(8)

                        if let expiry = storeManager.hadiyaExpiryDate {
                            Text("Gift period ends \(expiry.formatted(date: .long, time: .omitted))")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else {
                    VStack(spacing: 16) {
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

                        Button {
                            showingHadiyaSheet = true
                        } label: {
                            VStack(spacing: 2) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 14))
                                    Text("Hadiya (Gift) Program")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text("For those who cannot afford to pay")
                                    .font(.system(size: 12, weight: .regular))
                                    .opacity(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
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
        .sheet(isPresented: $showingHadiyaSheet) {
            HadiyaConfirmationSheet()
        }
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

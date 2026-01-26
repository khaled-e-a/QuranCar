//
//  ContentView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    @State private var showingCoachMarks = false
    @State private var mainViewReady = false

    var body: some View {
        ZStack {
            if showingSplash {
                SplashView {
                    withAnimation {
                        showingSplash = false
                        if !hasSeenOnboarding {
                            showingOnboarding = true
                        }
                    }
                }
                .transition(.opacity)
            } else if showingOnboarding {
                OnboardingView(showOnboarding: $showingOnboarding) {
                    // When onboarding completes, show coach marks and set hasSeenOnboarding
                    hasSeenOnboarding = true
                    showingCoachMarks = true
                    // Request notification authorization after onboarding
                    Task {
                        await NotificationManager.shared.checkAuthorizationStatus()
                        if NotificationManager.shared.authorizationStatus == .notDetermined {
                            _ = await NotificationManager.shared.requestAuthorization()
                        }
                    }
                }
                .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
                    .onAppear {
                        // Mark MainView as ready after a brief delay to ensure all views are laid out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            mainViewReady = true
                        }
                        // Request notification authorization if user skipped onboarding
                        if hasSeenOnboarding {
                            Task {
                                await NotificationManager.shared.checkAuthorizationStatus()
                                if NotificationManager.shared.authorizationStatus == .notDetermined {
                                    _ = await NotificationManager.shared.requestAuthorization()
                                }
                            }
                        }
                    }
                    .overlay {
                        if showingCoachMarks && mainViewReady {
                            CoachMarkView(showCoachMarks: $showingCoachMarks)
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.5), value: showingSplash)
        .animation(.easeOut(duration: 0.5), value: showingOnboarding)
        .animation(.easeOut(duration: 0.5), value: showingCoachMarks)
        .task {
            // Get token when app launches
            await QuranAuthManager.shared.refreshTokenIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}

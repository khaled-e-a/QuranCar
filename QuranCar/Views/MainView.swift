import SwiftUI
import NoorUI

struct MainView: View {
    @State private var selectedTab = Tab.memorize
    @State private var showingCoachMarks = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Logo and CarPlay Status
                CarPlayStatusBar()

                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)

                // Content
                TabView(selection: $selectedTab) {
                    BookView()
                        .tag(Tab.memorize)
                        .onAppear {
                            Logger.debug("MainView: BookView tab appeared")
                        }

                    SettingsView(selectedTab: $selectedTab)
                        .tag(Tab.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.background1) // Updated from Color(hex:)
            .navigationBarHidden(true)  // Hide the navigation bar
            .overlay {
                if showingCoachMarks {
                    CoachMarkView(showCoachMarks: $showingCoachMarks)
                }
            }
        }
        .navigationViewStyle(.stack)  // Prevent split view on iPad
        .onReceive(NotificationCenter.default.publisher(for: .showCoachMarks)) { _ in
            showingCoachMarks = true
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 32) {
            TabButton(
                title: "Memorize",
                isSelected: selectedTab == .memorize,
                action: { selectedTab = .memorize }
            )

            TabButton(
                title: "More",
                isSelected: selectedTab == .settings,
                action: { selectedTab = .settings }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.background1)
        .overlay(alignment: .bottom) {
            // Selected tab indicator
            GeometryReader { geometry in
                let width = geometry.size.width / 2 - 16
                Rectangle()
                    .fill(Color.primaryNormal)
                    .frame(width: width, height: 2)
                    .offset(x: selectedTab == .memorize ? 16 : width + 48)
                    .animation(.spring(response: 0.3), value: selectedTab)
            }
            .frame(height: 2)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isSelected ? Color.textTitle : Color.textBodySubtle)
        }
    }
}

struct CarPlayStatusBar: View {
    @StateObject private var carPlayManager = CarPlayConnectionManager.shared

    var body: some View {
        HStack {
            Text("Quran Car")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textTitle)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: carPlayManager.isConnected ? "car.fill" : "car")
                    .foregroundColor(carPlayManager.isConnected ? Color.primaryNormal : Color.textBodySubtle)
                Text(carPlayManager.isConnected ? "Connected to CarPlay" : "Ready to Connect")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.textBodySubtle)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(height: 60)
        .background(Color.background1)
    }
}

// MARK: - Supporting Types

enum Tab {
    case memorize
    case settings
}

// MARK: - Preview

#Preview {
    MainView()
}

extension Notification.Name {
    static let showCoachMarks = Notification.Name("showCoachMarks")
}

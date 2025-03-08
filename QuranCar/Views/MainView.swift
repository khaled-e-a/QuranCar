import SwiftUI
import NoorUI

struct MainView: View {
    @State private var selectedTab = Tab.memorize

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

                    SettingsView()
                        .tag(Tab.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.background1) // Updated from Color(hex:)
            .navigationBarHidden(true)  // Hide the navigation bar
        }
        .navigationViewStyle(.stack)  // Prevent split view on iPad
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
                title: "Settings",
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
    var body: some View {
        HStack {
            Text("Quran Car")
                .font(.system(size: 28, weight: .bold)) // H2 style
                .foregroundColor(Color.textTitle) // Title color

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "car.fill")
                    .foregroundColor(Color.primaryNormal) // Primary Normal
                Text("Connected to CarPlay")
                    .font(.system(size: 15, weight: .regular)) // Caption style
                    .foregroundColor(Color.textBodySubtle) // Body-subtle color
            }
        }
        .padding(.horizontal)
        .padding(.top, 16) // Add top padding
        .padding(.bottom, 12) // Add bottom padding
        .frame(height: 60) // Set a fixed height
        .background(Color.background1) // Background 1
        // .shadow(radius: 8, y: 2)
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

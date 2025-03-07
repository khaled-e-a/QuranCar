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
            .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            // Selected tab indicator
            GeometryReader { geometry in
                let width = geometry.size.width / 2 - 16
                Rectangle()
                    .fill(Color.blue)
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
                .font(.headline)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
}

struct CarPlayStatusBar: View {
    var body: some View {
        HStack {
            Text("Quran Car")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "car.fill")
                Text("Connected to CarPlay")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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

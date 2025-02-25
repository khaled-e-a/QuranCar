import SwiftUI
import NoorUI

struct MainView: View {
    @State private var selectedTab = Tab.book

    var body: some View {
        TabView(selection: $selectedTab) {
            BookView()
                .tabItem {
                    Label("Book", systemImage: "book")
                }
                .tag(Tab.book)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)

            CarView()
                .tabItem {
                    Label("Car", systemImage: "car")
                }
                .tag(Tab.car)
        }
        .onAppear {
            print("MainView: View appeared")
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            print("MainView: Configured tab bar appearance")
        }
    }
}

// MARK: - Supporting Types

enum Tab {
    case book
    case settings
    case car
}

// MARK: - Preview

#Preview {
    MainView()
}

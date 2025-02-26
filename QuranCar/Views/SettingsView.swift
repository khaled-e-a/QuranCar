import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Account") {
                    NavigationLink("Profile") {
                        Text("Profile Details")
                    }
                    NavigationLink("Preferences") {
                        Text("User Preferences")
                    }
                }

                Section("App Settings") {
                    NavigationLink("Theme") {
                        Text("Theme Settings")
                    }
                    NavigationLink("Language") {
                        Text("Language Settings")
                    }
                    NavigationLink("Notifications") {
                        Text("Notification Settings")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("Help & Support") {
                        Text("Help & Support")
                    }
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
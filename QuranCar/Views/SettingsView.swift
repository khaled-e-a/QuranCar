import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    Text("Profile")
                    Text("Preferences")
                }

                Section("App Settings") {
                    Text("Theme")
                    Text("Language")
                    Text("Notifications")
                }

                Section("About") {
                    Text("Version 1.0")
                    Text("Help & Support")
                    Text("Privacy Policy")
                }
            }
        }
    }
}
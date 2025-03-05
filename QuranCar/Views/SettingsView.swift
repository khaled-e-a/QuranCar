import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            // Coming Soon Section
            Section {
                ComingSoonCard()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Privacy Policy Section
            Section {
                Link(destination: URL(string: "https://elm.academy/qurancar/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
    }
}

struct ComingSoonCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.white)

            // Title
            Text("More Features Coming Soon!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bookmark.fill", text: "Save memorization loops")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                FeatureRow(icon: "person.2.fill", text: "Share with friends")
                FeatureRow(icon: "star.fill", text: "Favorite verses")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.9))

            Text(text)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
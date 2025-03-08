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
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.textBody)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(Color.textBodySubtle)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
        .background(Color.background1)
    }
}

struct ComingSoonCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(Color(Color.textBody))

            // Title
            Text("More Features Coming Soon!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(Color.textBody))
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
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(Color.background1))

            Text(text)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(Color.textBody))
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

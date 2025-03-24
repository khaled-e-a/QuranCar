import SwiftUI

struct ComingSoonCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(.white)

            // Title
            Text("More Features Coming Soon!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bookmark.fill", text: "Save memorization loops")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                FeatureRow(icon: "person.2.fill", text: "Share with friends")
                FeatureRow(icon: "ellipsis.circle.fill", text: "And more to come...")
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
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
        }
    }
}
import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    let completion: () -> Void

    var body: some View {
        ZStack {
            // Background Pattern
            Image("islamic_pattern")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)

            // Semi-transparent overlay
            Color.primaryNormal
                .opacity(0.15)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Logo
                Image("quran_car_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .cornerRadius(20)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1 : 0)

                // App Name
                Text("Quran Car")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                // Tagline
                Text("Memorize while you drive")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.background1)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    completion()
                }
            }
        }
    }
}
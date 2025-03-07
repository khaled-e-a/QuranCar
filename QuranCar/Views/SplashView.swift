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

            // Semi-transparent overlay to ensure text readability
            Color.blue
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Logo
                Image("quran_car_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1 : 0)

                // App Name
                Text("Quran Car")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                // Tagline
                Text("Memorize while you drive")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }

            // Dismiss splash screen after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    completion()
                }
            }
        }
    }
}
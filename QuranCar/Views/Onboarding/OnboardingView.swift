import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    let onCompletion: () -> Void

    let pages = [
        OnboardingPage(
            title: "Welcome to QuranCar",
            description: "Your companion for memorizing Quran while driving. Designed specifically for safe and distraction-free use with CarPlay.",
            imageName: "car.fill",
            accentColor: Color.primaryNormal
        ),
        OnboardingPage(
            title: "Set Up Your Memorization",
            description: "Use the app to configure your memorization settings, then connect to CarPlay to start memorizing while you drive.",
            imageName: "gearshape.fill",
            accentColor: Color.primaryNormal
        )
    ]

    var body: some View {
        ZStack {
            Color.background1.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Control
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.primaryNormal : Color.textBodySubtle)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Page View
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            showOnboarding = false
                            onCompletion()
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Skip")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primaryNormal)
                            .cornerRadius(12)
                    }

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.primaryNormal)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.accentColor)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.textTitle)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(Color.textBodySubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true)) {}
}
import SwiftUI
import QuranKit

struct CarView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Car Mode")
                    // Using H1 style from guidelines
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color.textTitle)

                // Add your car mode interface here
                // This should be optimized for use while driving

                Spacer()
            }
            .padding(24) // XXL spacing
            .background(Color.background1) // Background 1
        }
    }
}

#Preview {
    CarView()
}
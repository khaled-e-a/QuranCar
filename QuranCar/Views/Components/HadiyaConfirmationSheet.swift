import SwiftUI

struct HadiyaConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryNormal.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "gift.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.primaryNormal)
            }

            VStack(spacing: 12) {
                Text("Hadiya (Gift) Program")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.textTitle)
                    .multilineTextAlignment(.center)

                Text("We believe everyone should have access to the Quran. If you truly cannot afford the subscription, we are honored to gift you one year of Premium access.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("This program is based on trust. Please only use it if you are unable to pay.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textBodySubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            VStack(spacing: 16) {
                Button(action: {
                    storeManager.grantHadiyaSubscription()
                    dismiss()
                }) {
                    Text("I am unable to pay, thank you")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryNormal)
                        .cornerRadius(12)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color.textBodySubtle)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.vertical, 32)
        .background(Color.background1)
    }
}

#Preview {
    HadiyaConfirmationSheet()
        .environmentObject(StoreManager.shared)
}

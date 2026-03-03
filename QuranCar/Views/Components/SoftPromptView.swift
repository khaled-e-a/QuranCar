import SwiftUI

struct SoftPromptView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryNormal.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.primaryNormal)
            }
            
            VStack(spacing: 12) {
                Text("Keep your journey alive")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.textTitle)
                    .multilineTextAlignment(.center)
                
                Text("Quran Car can remind you to continue your memorization if you've been away for a few days.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.textBodySubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        _ = await notificationManager.requestAuthorization()
                        notificationManager.showingSoftPrompt = false
                    }
                }) {
                    Text("Enable Reminders")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryNormal)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    notificationManager.showingSoftPrompt = false
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
    SoftPromptView()
}

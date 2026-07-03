import SwiftUI
import UserNotifications

struct NotificationsOnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()

                // Phone Frame with Stacked Notifications Mockup
                PhoneNotificationMockupView()
                    .padding(.bottom, 24)

                Spacer()

                // Text Content (Left-Aligned to match mockup)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get Notified when\nDevices are Detected")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Notifications include alerts about surveillance devices, trackers, and nearby wearables.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Action Buttons (Allow notifications / Not right now)
                VStack(spacing: 12) {
                    Button {
                        UNUserNotificationCenter.current().requestAuthorization(options: [
                            .alert, .sound, .badge,
                        ]) { _, _ in
                            DispatchQueue.main.async {
                                withAnimation {
                                    hasSeenOnboarding = true
                                }
                            }
                        }
                    } label: {
                        Text("Allow notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primary)
                            .clipShape(Capsule())
                    }

                    Button {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    } label: {
                        Text("Not right now")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                Text(
                    "By continuing, you agree to our [Terms of Service](https://github.com/HenriquesPontes/Near/blob/main/TERMS.md) and [Privacy Policy](https://github.com/HenriquesPontes/Near/blob/main/PRIVACY.md)."
                )
                .tint(.blue)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct PhoneNotificationMockupView: View {
    var body: some View {
        ZStack {
            // Mock Phone Frame
            Image("Device")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color.primary.opacity(0.12))
                .aspectRatio(contentMode: .fit)
                .frame(width: 320, height: 260)
                // Mask with gradient to fade out bottom edge within container bounds
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.4),
                            .init(color: .clear, location: 0.75)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 40)
            
            VStack(spacing: 12) {
                // First Notification Banner
                NotificationBannerView(
                    iconName: "N",
                    title: "Smart Glasses Detected",
                    time: "Just now",
                    subtitle: "Ray-Ban Meta detected nearby."
                )
                
                // Second Notification Banner
                NotificationBannerView(
                    iconName: "N",
                    title: "Unknown Tracker Nearby",
                    time: "10m ago",
                    subtitle: "An unidentified beacon is moving with you."
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .frame(height: 240)
    }
}

struct NotificationBannerView: View {
    let iconName: String
    let title: String
    let time: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            // App Logo Icon
            Text(iconName)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .frame(width: 38, height: 38)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(time)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
}

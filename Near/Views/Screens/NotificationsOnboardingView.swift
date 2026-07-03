import SwiftUI
import UserNotifications

struct NotificationsOnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    
    @State private var banner1Visible: Bool = false
    @State private var banner2Visible: Bool = false
    @State private var banner3Visible: Bool = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()

                // Phone Frame with Stacked Notifications Mockup
                PhoneNotificationMockupView(
                    banner1Visible: banner1Visible,
                    banner2Visible: banner2Visible,
                    banner3Visible: banner3Visible
                )
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

                VStack(spacing: 12) {
                    Button {
                        alertOnNewDevices = true
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
                        alertOnNewDevices = false
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
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(0.5)) {
                banner1Visible = true
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(1.2)) {
                banner2Visible = true
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(1.9)) {
                banner3Visible = true
            }
        }
    }
}

struct PhoneNotificationMockupView: View {
    let banner1Visible: Bool
    let banner2Visible: Bool
    let banner3Visible: Bool

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
            
            VStack(spacing: 8) {
                // First Notification Banner
                NotificationBannerView(
                    title: "Smart Glasses Detected",
                    time: "Just now",
                    subtitle: "Ray-Ban Meta detected nearby."
                )
                .opacity(banner1Visible ? 1.0 : 0.0)
                .offset(y: banner1Visible ? 0 : -20)
                
                // Second Notification Banner
                NotificationBannerView(
                    title: "Unknown Tracker Nearby",
                    time: "10m ago",
                    subtitle: "An unidentified beacon is moving with you."
                )
                .opacity(banner2Visible ? 1.0 : 0.0)
                .offset(y: banner2Visible ? 0 : -20)
                
                // Third Notification Banner
                NotificationBannerView(
                    title: "Smart Glasses in Range",
                    time: "1h ago",
                    subtitle: "A smart wearable is close by."
                )
                .opacity(banner3Visible ? 1.0 : 0.0)
                .offset(y: banner3Visible ? 0 : -20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .frame(height: 240)
    }
}

struct NotificationBannerView: View {
    let title: LocalizedStringKey
    let time: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            // App Logo Icon: Bell icon inside a light grey background tile
            Image(systemName: "bell.fill")
                .font(.system(size: 16))
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

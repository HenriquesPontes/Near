import SwiftUI
import UserNotifications

struct MockNotification: Identifiable, Equatable {
    let id: Int
    let title: LocalizedStringKey
    let time: LocalizedStringKey
    let subtitle: LocalizedStringKey
}

let mockNotifications = [
    MockNotification(id: 1, title: "Smart Glasses Detected", time: "Just now", subtitle: "Ray-Ban Meta detected nearby."),
    MockNotification(id: 2, title: "Unknown Tracker Nearby", time: "10m ago", subtitle: "An unidentified beacon is moving with you."),
    MockNotification(id: 3, title: "Smart Glasses in Range", time: "1h ago", subtitle: "A smart wearable is close by.")
]

struct NotificationsOnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    
    @State private var visibleBanners: [MockNotification] = []
    @State private var activeIndex = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()

                // Phone Frame with Stacked Notifications Mockup
                PhoneNotificationMockupView(visibleBanners: visibleBanners)
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
            // Step 1: Initial Cascade Slide-In
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.75)) {
                    visibleBanners.append(mockNotifications[0])
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.75)) {
                    visibleBanners.append(mockNotifications[1])
                }
            }
            
            // Step 2: Continuous loop showing 2 at a time
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    withAnimation(.spring(response: 0.65, dampingFraction: 0.75)) {
                        activeIndex = (activeIndex + 1) % 3
                        visibleBanners = [
                            mockNotifications[activeIndex],
                            mockNotifications[(activeIndex + 1) % 3]
                        ]
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct PhoneNotificationMockupView: View {
    let visibleBanners: [MockNotification]

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
            
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    ForEach(visibleBanners) { banner in
                        NotificationBannerView(
                            title: banner.title,
                            time: banner.time,
                            subtitle: banner.subtitle
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .offset(y: 10)
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

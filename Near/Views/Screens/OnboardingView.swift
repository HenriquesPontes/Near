import SwiftUI
import UserNotifications

enum OnboardingStep: Int, Hashable {
    case features = 1
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                welcomeStep
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                    switch step {
                    case .features:
                        featuresStep
                    }
                }
                // Custom back button in toolbar to match health app
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            path.removeLast()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            // Diagonal masonry collage of smart devices
            ZStack(alignment: .bottom) {
                HStack(spacing: 16) {
                    // Column 1
                    VStack(spacing: 16) {
                        Image("welcome_laptop")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 200)
                            .cornerRadius(28)
                            .clipped()
                        
                        Image("welcome_speaker")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 200)
                            .cornerRadius(28)
                            .clipped()
                    }
                    
                    // Column 2 (Offset to create a staggered masonry effect)
                    VStack(spacing: 16) {
                        Image("welcome_smartwatch")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 200)
                            .cornerRadius(28)
                            .clipped()
                        
                        Image("welcome_glasses")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 200)
                            .cornerRadius(28)
                            .clipped()
                    }
                    .offset(y: 40)
                }
                .rotationEffect(.degrees(-15))
                .scaleEffect(1.1)
                .frame(maxWidth: .infinity, maxHeight: 380)
                .offset(y: -40)
                
                // Soft fade gradient transition into the background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground).opacity(0.0),
                        Color(UIColor.systemBackground).opacity(0.8),
                        Color(UIColor.systemBackground).opacity(1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
            }
            .frame(height: 380)
            .clipped()
            
            Spacer()
            
            // Text Content
            VStack(spacing: 12) {
                Text("Welcome to Near")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This app brings your awareness and privacy tools together in one place.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Continue Button
            Button {
                path.append(OnboardingStep.features)
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Features & Permissions Step
    private var featuresStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Features & Notifications")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 32) {
                        FeatureRow(
                            icon: "Wifi_High", title: "Signal Detection",
                            subtitle:
                                "Detects Bluetooth emissions from popular smart glasses like Ray-Ban Meta and other smart glasses.",
                            iconColor: .blue)
                        FeatureRow(
                            icon: "Bell_Notification", title: "Alerts & Notifications",
                            subtitle:
                                "Get notified when potential surveillance devices are nearby.",
                            iconColor: .orange)
                        FeatureRow(
                            icon: "Shield_Check", title: "Privacy First",
                            subtitle:
                                "NearbyGlasses doesn't collect your data. Everything happens entirely on your device.",
                            iconColor: .green)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }

            ZStack(alignment: .bottom) {
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
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                
                Text(
                    "By continuing, you agree to our [Terms of Service](https://github.com/HenriquesPontes/Near/blob/main/TERMS.md) and [Privacy Policy](https://github.com/HenriquesPontes/Near/blob/main/PRIVACY.md)."
                )
                .tint(.blue)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .offset(y: 38)
            }
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var iconColor: Color = .blue

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

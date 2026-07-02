import SwiftUI
import UserNotifications

enum OnboardingStep: Int, Hashable {
    case features = 1
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var path = NavigationPath()
    @State private var iconPositions: [IconPosition] = []
    @State private var isAnimating: Bool = false

    let backgroundIcons = [
        "Wifi_High", "Camera", "Desktop", "Shield_Warning", "Help",
        "Terminal", "Qr_Code", "Devices", "Bell_Notification", "Phone",
        "Shield_Check", "Info", "Data", "Code", "Mobile", "Tablet",
    ]

    let iconColors: [Color] = [.blue, .purple, .orange, .red, .green, .cyan, .pink, .indigo]

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
        .onAppear {
            if iconPositions.isEmpty {
                generatePositions()
            }
            isAnimating = true
        }
    }

    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Radar Animation
            OnboardingRadarView()
                .frame(height: 300)
                .padding(.bottom, 40)

            // Text Content
            VStack(spacing: 12) {
                Text("Welcome to Near")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("This app brings your awareness and privacy tools together in one place.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

            }

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

    // MARK: - Helpers
    private func generatePositions() {
        var newPositions: [IconPosition] = []
        let count = 12
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi
            let radius = CGFloat.random(in: 80...130)

            let xOffset = (cos(angle) * radius) / 350.0
            let yOffset = (sin(angle) * radius) / 300.0

            let icon = backgroundIcons.randomElement() ?? "Wifi_High"
            let color = iconColors.randomElement() ?? .blue
            let scale = CGFloat.random(in: 0.8...1.2)
            let rotation = Double.random(in: -45...45)

            newPositions.append(
                IconPosition(
                    icon: icon,
                    color: color,
                    x: 0.5 + xOffset,
                    y: 0.5 + yOffset,
                    scale: scale,
                    rotation: rotation,
                    opacity: 1.0,
                    duration: Double.random(in: 2...4),
                    delay: Double.random(in: 0...2),
                    yOffset: CGFloat.random(in: 10...25)
                ))
        }
        iconPositions = newPositions
    }
}

struct IconPosition: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let rotation: Double
    let opacity: Double
    let duration: Double
    let delay: Double
    let yOffset: CGFloat
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

struct OnboardingRadarView: View {
    var body: some View {
        TimelineView(.animation) { timelineContext in
            let time = timelineContext.date.timeIntervalSinceReferenceDate
            let progress = (time.truncatingRemainder(dividingBy: 3.0) / 3.0)
            let waveScale = 0.3 + (progress * 1.1)
            let waveOpacity = 1.0 - progress
            let angle = (time.truncatingRemainder(dividingBy: 4.0) / 4.0) * 360.0
            
            ZStack {
                // Concentric circles
                ForEach(1...4, id: \.self) { ring in
                    Circle()
                        .stroke(Color.blue.opacity(0.18), lineWidth: 1.5)
                        .frame(width: CGFloat(ring) * 200 / 4, height: CGFloat(ring) * 200 / 4)
                }
                
                // Crosshair lines
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 100))
                    path.addLine(to: CGPoint(x: 190, y: 100))
                    path.move(to: CGPoint(x: 100, y: 10))
                    path.addLine(to: CGPoint(x: 100, y: 190))
                }
                .stroke(Color.blue.opacity(0.1), lineWidth: 1.5)
                
                // Pulse Wave
                Circle()
                    .stroke(Color.blue.opacity(0.4), lineWidth: 3)
                    .scaleEffect(waveScale)
                    .opacity(waveOpacity)
                    .frame(width: 200, height: 200)
                
                // Sweep angle sector
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(90)
                        )
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(angle))
                
                // Center node
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.blue, radius: 8)
                
                // Simulated glowing device pings
                // Position 1: top right
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.blue, radius: 4)
                    .position(x: 140, y: 60)
                    .opacity(0.8)
                
                // Position 2: bottom left
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.blue, radius: 4)
                    .position(x: 60, y: 130)
                    .opacity(0.5)
                
                // Position 3: top left
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.blue, radius: 4)
                    .position(x: 50, y: 60)
                    .opacity(0.3)
            }
            .frame(width: 200, height: 200)
        }
    }
}

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
                .navigationBarBackButtonHidden(true)
            }
        }
        .onAppear {
            if iconPositions.isEmpty {
                generatePositions()
            }
            isAnimating = true
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Radar Animation
            OnboardingRadarView()
                .frame(height: 300)

            Spacer()

            // Text Content
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Nearby")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.primary)
                }
                .multilineTextAlignment(.center)

                Text("This app brings your awareness and privacy\ntools together in one place.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            .padding(.bottom, 32)

            // Next Button
            Button {
                path.append(OnboardingStep.features)
            } label: {
                Text("Next")
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

    private var featuresStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Notification Radar Graphic
            NotificationRadarGraphicView()
                .frame(height: 300)

            Spacer()

            // Text Content
            VStack(spacing: 16) {
                Text("Get Notified when\nDevices are Detected")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("Notifications include alerts about surveillance\ndevices, trackers, and nearby wearables.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            .padding(.bottom, 32)

            // Action Button
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
                Text("Enable Notifications")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary)
                    .clipShape(Capsule())
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
            let waveScale = 0.5 + (progress * 0.5)
            let waveOpacity = 0.8 * (1.0 - progress)
            let angle = (time.truncatingRemainder(dividingBy: 4.0) / 4.0) * 360.0
            
            ZStack {
                // Concentric circles matching ScanRadarView rings
                ForEach(1...4, id: \.self) { ring in
                    Circle()
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        .frame(width: CGFloat(ring) * 280 / 4, height: CGFloat(ring) * 280 / 4)
                }
                
                // Crosshair lines matching ScanRadarView
                Path { path in
                    path.move(to: CGPoint(x: 20, y: 140))
                    path.addLine(to: CGPoint(x: 260, y: 140))
                    path.move(to: CGPoint(x: 140, y: 20))
                    path.addLine(to: CGPoint(x: 140, y: 260))
                }
                .stroke(Color.blue.opacity(0.08), lineWidth: 1)
                
                // Pulse Wave matching ScanRadarView
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .scaleEffect(waveScale)
                    .opacity(waveOpacity)
                    .frame(width: 280, height: 280)
                
                // 360 degree Sweep angle sector matching ScanRadarView
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.0)
                            ]),
                            center: .center,
                            angle: .degrees(0)
                        )
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(angle))
                
                // Center node matching ScanRadarView scanner core
                Circle()
                    .fill(Color.blue)
                    .frame(width: 14, height: 14)
                    .shadow(color: Color.blue, radius: 8)
                
                // High fidelity pulsating device pings in different colors
                OnboardingPingNode(x: 196, y: 84, delay: 0.0, color: .green)
                OnboardingPingNode(x: 84, y: 182, delay: 0.8, color: .red)
                OnboardingPingNode(x: 70, y: 84, delay: 1.5, color: .purple)
            }
            .frame(width: 280, height: 280)
        }
    }
}

struct OnboardingPingNode: View {
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 2)
                .scaleEffect(scale)
                .opacity(opacity)
                .frame(width: 24, height: 24)
                .onAppear {
                    withAnimation(
                        Animation.easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(delay)
                    ) {
                        scale = 2.2
                        opacity = 0.0
                    }
                }
            
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color, radius: 4)
        }
        .position(x: x, y: y)
    }
}

struct NotificationRadarGraphicView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var sweepAngle: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient: Deep navy/dark indigo matching the scan view background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 10/255, green: 17/255, blue: 40/255),
                        Color(red: 26/255, green: 43/255, blue: 76/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Concentric radar rings matching the dashboard sweep style
                ForEach(1...4, id: \.self) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        .frame(width: CGFloat(index) * 60, height: CGFloat(index) * 60)
                }
                
                // Crosshairs
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 1, height: 260)
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 260, height: 1)
                
                // Active Radar Sweep animation
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.25),
                                Color.blue.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(90)
                        )
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(sweepAngle))
                
                // Simulated device ping indicators with glowing alert rings
                // Green Ping (Safe)
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15 * pulseScale))
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                .position(x: geometry.size.width * 0.35, y: geometry.size.height * 0.32)
                
                // Purple Ping (Wearable)
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15 * pulseScale))
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 7, height: 7)
                }
                .position(x: geometry.size.width * 0.72, y: geometry.size.height * 0.42)
                
                // Red Ping (Alert/Glasses)
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2 * pulseScale))
                        .frame(width: 36, height: 36)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                        .shadow(color: .red, radius: 4)
                }
                .position(x: geometry.size.width * 0.52, y: geometry.size.height * 0.65)
                
                // Floating mockup notification banner at the bottom
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 36, height: 36)
                                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Nearby Alert")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Smart glasses detected nearby.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("now")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                sweepAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.5
            }
        }
    }
}

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

            // Notification Preview Card
            NotificationPreviewCard()

            Spacer()

            // Text Content
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Get Notified when")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Devices are Detected")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

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

struct StylizedMapView: View {
    @State private var travelProgress: CGFloat = 0.0
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.8
    
    // Path points for A to B route
    let p0 = CGPoint(x: 60, y: 180)
    let p1 = CGPoint(x: 120, y: 200)
    let p2 = CGPoint(x: 160, y: 120)
    let p3 = CGPoint(x: 240, y: 130)
    
    var body: some View {
        ZStack {
            // Dark Map Background
            Color(red: 0.07, green: 0.07, blue: 0.07)
            
            // Map grid roads (simulated thin street lines)
            GeometryReader { geo in
                Path { path in
                    // Vertical streets
                    for x in stride(from: CGFloat(-20), to: geo.size.width + 40, by: 45) {
                        path.move(to: CGPoint(x: x, y: -20))
                        path.addLine(to: CGPoint(x: x + geo.size.height * 0.25, y: geo.size.height + 20))
                    }
                    // Horizontal/diagonal streets
                    for y in stride(from: CGFloat(-20), to: geo.size.height + 40, by: 50) {
                        path.move(to: CGPoint(x: -20, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width + 20, y: y + geo.size.width * 0.08))
                    }
                }
                .stroke(Color(red: 0.16, green: 0.16, blue: 0.16), lineWidth: 1.5)
            }
            
            // Route Path Line from Point A to B
            Path { path in
                path.move(to: p0)
                path.addCurve(to: p3, control1: p1, control2: p2)
            }
            .stroke(
                LinearGradient(
                    colors: [Color.orange.opacity(0.4), Color.red],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            
            // Point A (Start)
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .position(p0)
            
            // Point B (End Target)
            ZStack {
                // Pulsating Halo
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
            }
            .position(p3)
            
            // Traveling Dot (Dot moving from A to B)
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .shadow(color: .white, radius: 2)
                .position(bezierPoint(t: travelProgress, p0: p0, p1: p1, p2: p2, p3: p3))
            
            // Floating Label "Device nearby • 1m" near Point B
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text("Device nearby • 1m")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .position(x: p3.x, y: p3.y + 24)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                travelProgress = 1.0
            }
            
            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                ringScale = 2.0
                ringOpacity = 0.0
            }
        }
    }
    
    private func bezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1.0 - t
        let tt = t * t
        let uu = u * u
        let uuu = uu * u
        let ttt = tt * t
        
        var p = CGPoint.zero
        p.x = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x
        p.y = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y
        return p
    }
}

struct NotificationPreviewCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            // Stylized Map
            StylizedMapView()
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Floating Notification Banner overlaying the map at the top
            HStack(spacing: 12) {
                // App Icon / Bell Icon
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 38, height: 38)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby Alert")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Smart glasses detected nearby.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(height: 240)
        .padding(.horizontal, 24)
    }
}

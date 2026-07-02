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

            // Dark Map View
            DarkMapView()

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

struct DarkMapView: View {
    @State private var routeProgress: CGFloat = 0
    @State private var pointBPulse: CGFloat = 1.0
    @State private var showCallout: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            ZStack {
                // Map Base Background
                Color(red: 0.08, green: 0.08, blue: 0.08)
                
                // Abstract Water / Coastline Shape
                WaterShape()
                    .fill(Color(red: 0.05, green: 0.06, blue: 0.08))
                
                // Abstract Grid / Roads
                RoadNetworkShape()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                
                // Major highways/streets
                HighwayNetworkShape()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3.5)
                
                // Animated Orange Route Path
                RoutePathShape()
                    .trim(from: 0, to: routeProgress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [4, 4]))
                    .shadow(color: .orange.opacity(0.5), radius: 3)
                
                // Point A (User Location)
                UserLocationDot()
                    .position(x: w * 0.25, y: h * 0.65)
                
                // Point B (Orange Alert Device Location)
                DeviceAlertPin(pulse: pointBPulse, showCallout: showCallout)
                    .position(x: w * 0.7, y: h * 0.3)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .onAppear {
            animateSequence()
        }
    }
    
    private func animateSequence() {
        routeProgress = 0
        showCallout = false
        
        // Route draws over 2.2 seconds
        withAnimation(.easeOut(duration: 2.2)) {
            routeProgress = 1.0
        }
        
        // Show callout banner after route finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showCallout = true
            }
        }
        
        // Trigger pulse loop
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pointBPulse = 1.4
        }
        
        // Cycle sequence every 5.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            animateSequence()
        }
    }
}

struct WaterShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width, y: rect.height * 0.4))
        path.addCurve(
            to: CGPoint(x: 0, y: rect.height * 0.85),
            control1: CGPoint(x: rect.width * 0.6, y: rect.height * 0.5),
            control2: CGPoint(x: rect.width * 0.4, y: rect.height * 0.8)
        )
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct RoadNetworkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Horizontal roads
        path.move(to: CGPoint(x: 0, y: rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.2))
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.5))
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.8))
        
        // Vertical roads
        path.move(to: CGPoint(x: rect.width * 0.15, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height))
        
        path.move(to: CGPoint(x: rect.width * 0.45, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height))
        
        path.move(to: CGPoint(x: rect.width * 0.75, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height))
        
        return path
    }
}

struct HighwayNetworkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.2))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.75),
            control1: CGPoint(x: rect.width * 0.4, y: rect.height * 0.1),
            control2: CGPoint(x: rect.width * 0.5, y: rect.height * 0.9)
        )
        
        path.move(to: CGPoint(x: rect.width * 0.2, y: 0))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height),
            control1: CGPoint(x: rect.width * 0.3, y: rect.height * 0.5),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.5)
        )
        return path
    }
}

struct RoutePathShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.65))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.3),
            control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.45),
            control2: CGPoint(x: rect.width * 0.55, y: rect.height * 0.4)
        )
        return path
    }
}

struct UserLocationDot: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
        }
    }
}

struct DeviceAlertPin: View {
    var pulse: CGFloat
    var showCallout: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                .frame(width: 36 * pulse, height: 36 * pulse)
                .opacity(2.0 - Double(pulse))
            
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                .frame(width: 64 * pulse, height: 64 * pulse)
                .opacity(2.0 - Double(pulse))
            
            Circle()
                .fill(Color.orange)
                .frame(width: 14, height: 14)
                .shadow(color: .orange.opacity(0.6), radius: 4)
            
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            
            if showCallout {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        Text("Device nearby • 1m")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 3)
                    
                    Triangle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 6)
                }
                .offset(y: -42)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

import SwiftUI

struct WelcomeOnboardingView: View {
    @Binding var path: NavigationPath
    @State private var iconPositions: [IconPosition] = []
    @State private var isAnimating: Bool = false

    let backgroundIcons = [
        "Wifi_High", "Camera", "Desktop", "Shield_Warning", "Help",
        "Terminal", "Qr_Code", "Devices", "Bell_Notification", "Phone",
        "Shield_Check", "Info", "Data", "Code", "Mobile", "Tablet",
    ]

    let iconColors: [Color] = [.blue, .purple, .orange, .red, .green, .cyan, .pink, .indigo]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
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
        .onAppear {
            if iconPositions.isEmpty {
                generatePositions()
            }
            isAnimating = true
        }
    }

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

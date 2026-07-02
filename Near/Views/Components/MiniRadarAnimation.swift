import SwiftUI

struct MiniRadarAnimation: View {
    var isActive: Bool
    
    @State private var rotation: Double = 0
    @State private var rippleScale: CGFloat = 0.1
    @State private var rippleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 44, height: 44)
            
            if isActive {
                TimelineView(.animation) { timelineContext in
                    let time = timelineContext.date.timeIntervalSinceReferenceDate
                    let waveProgress = (time.truncatingRemainder(dividingBy: 2.0) / 2.0)
                    let waveScale = 0.1 + (waveProgress * 1.4)
                    let waveOpacity = 1.0 - waveProgress
                    let sweepAngle = (time.truncatingRemainder(dividingBy: 2.0) / 2.0) * 360.0
                    
                    ZStack {
                        // Sweep
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.8)]),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(90)
                                )
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(sweepAngle))
                        
                        // Ripple
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 44, height: 44)
                            .scaleEffect(waveScale)
                            .opacity(waveOpacity)
                    }
                }
            } else {
                // Idle state
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.8)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(90)
                        )
                    )
                    .frame(width: 44, height: 44)
            }
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
        }
    }
}

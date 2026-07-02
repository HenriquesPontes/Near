import SwiftUI

struct StatusHeaderCard: View {
    var deviceCount: Int
    var isRadarActive: Bool
    var onRadarModeToggle: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onRadarModeToggle()
        }) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Radar Mode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(deviceCount)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                            
                            Text("devices")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    MiniRadarAnimation(isActive: isRadarActive, color: DesignSystem.primaryBlue)
                }
                
                if isRadarActive {
                    Text("Radar mode is actively monitoring for new devices in the background.")
                } else {
                    Text("Radar mode is paused. Tap to enable background scanning.")
                }
            }
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(
                ZStack {
                    // Stretches card background color upwards behind navigation and status bars
                    DesignSystem.cardBackground
                        .padding(.top, -1000)
                        .ignoresSafeArea()
                    
                    // Fades the bottom padding area into the background color
                    LinearGradient(
                        stops: [
                            .init(color: DesignSystem.cardBackground, location: 0.0),
                            .init(color: DesignSystem.cardBackground, location: 0.7),
                            .init(color: DesignSystem.backgroundColor, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

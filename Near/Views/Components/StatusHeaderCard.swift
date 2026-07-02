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
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(deviceCount)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                            
                            Text("devices")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    MiniRadarAnimation(isActive: isRadarActive)
                }
                
                if isRadarActive {
                    Text("Radar mode is actively monitoring for new devices in the background.")
                } else {
                    Text("Radar mode is paused. Tap to enable background scanning.")
                }
            }
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(
                DesignSystem.heroBackground
                    .padding(.top, -1000)
                    .ignoresSafeArea()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

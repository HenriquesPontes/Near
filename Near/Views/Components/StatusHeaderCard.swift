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
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Radar Mode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(deviceCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                            
                            Text("devices")
                                .font(.system(size: 16, weight: .semibold))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

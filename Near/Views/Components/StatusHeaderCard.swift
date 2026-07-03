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
                
                Group {
                    if isRadarActive {
                        ActivePromptView()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        PausedPromptView()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(
                DesignSystem.cardBackground
                    .padding(.top, -1000)
                    .ignoresSafeArea()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PausedPromptView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.8 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 12, height: 12)
            
            Text("Radar mode is paused. Tap to enable background scanning.")
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct ActivePromptView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.6 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 12, height: 12)
            
            Text("Radar mode is actively monitoring for new devices in the background.")
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}


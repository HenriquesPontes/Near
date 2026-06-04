import SwiftUI
#if os(iOS)
import UIKit
#endif

struct DeviceTrackerView: View {
    let device: DetectedDevice
    @ObservedObject var btManager = BluetoothManager.shared
    @StateObject private var smoother = RSSISmoother(alpha: 0.15) // Highly responsive EMA
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var trackingTask: Task<Void, Never>? = nil
    
    // UI state
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    // Audio and haptics
    @State private var enableHaptics = true
    
    private var distanceText: String {
        if smoother.smoothedRSSI == -100.0 { return "Searching..." }
        
        let rssi = smoother.smoothedRSSI
        if rssi >= -55 { return "Here" }
        if rssi >= -65 { return "Very Close" }
        if rssi >= -75 { return "Nearby" }
        if rssi >= -85 { return "Far" }
        return "Very Far"
    }
    
    private var instructionalText: String {
        if smoother.smoothedRSSI == -100.0 { return "Move around to establish a connection." }
        
        let rssi = smoother.smoothedRSSI
        if rssi >= -55 { return "The glasses should be within reach." }
        if rssi >= -65 { return "Getting warmer. Keep looking in this area." }
        if rssi >= -75 { return "Signal is stronger. Walk around slowly." }
        return "Signal is weak. Walk around to find a better signal."
    }
    
    private var trackingColor: Color {
        let rssi = smoother.smoothedRSSI
        if rssi >= -55 { return .red }
        if rssi >= -65 { return .orange }
        if rssi >= -75 { return .yellow }
        return .blue
    }
    
    private var ringCount: Int {
        let rssi = smoother.smoothedRSSI
        if rssi == -100.0 { return 1 }
        if rssi >= -55 { return 4 }
        if rssi >= -65 { return 3 }
        if rssi >= -75 { return 2 }
        return 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Device Icon
                    DeviceIconView(icon: iconForType(device.type), color: trackingColor)
                        .frame(width: 80, height: 80)
                        .padding(.bottom, 20)
                    
                    Text(distanceText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(instructionalText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Radar Rings
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .stroke(trackingColor.opacity(index < ringCount ? 0.8 : 0.2), lineWidth: index < ringCount ? 4 : 2)
                                .frame(width: CGFloat(100 + (index * 60)), height: CGFloat(100 + (index * 60)))
                                .scaleEffect(index == ringCount - 1 ? pulseScale : 1.0)
                                .opacity(index == ringCount - 1 ? pulseOpacity : 1.0)
                        }
                    }
                    .frame(height: 300)
                    
                    Spacer()
                }
            }
            .navigationTitle("Tracing Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { enableHaptics.toggle() }) {
                        Image(systemName: enableHaptics ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                            .foregroundColor(enableHaptics ? .green : .gray)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .onAppear {
            startTracking()
        }
        .onDisappear {
            stopTracking()
        }
        .onChange(of: ringCount) { _ in
            triggerHaptic(style: .heavy)
        }
    }
    
    #if os(iOS)
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enableHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    #else
    private func triggerHaptic(style: Int) {
        // No-op for macOS
    }
    #endif
    
    private func startTracking() {
        // Animate Rings
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            pulseOpacity = 0.3
        }
        
        trackingTask = Task {
            while !Task.isCancelled {
                // Poll BluetoothManager for the latest raw RSSI of this device
                if let activeDev = btManager.detectedDevices.first(where: { $0.deviceId == device.deviceId }) {
                    smoother.add(rssi: activeDev.rssi)
                }
                
                // Trigger continuous haptics if very close
                if enableHaptics && smoother.smoothedRSSI >= -60 && smoother.smoothedRSSI != -100.0 {
                    #if os(iOS)
                    triggerHaptic(style: .light)
                    #endif
                }
                
                let interval: Double
                let rssi = smoother.smoothedRSSI
                if rssi >= -60 { interval = 0.3 }
                else if rssi >= -75 { interval = 0.6 }
                else { interval = 1.0 }
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    private func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }
}

import WidgetKit
import SwiftUI
import AppIntents

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

struct ToggleScanIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Scanning"
    static var description = IntentDescription("Starts or stops Bluetooth scanning.")
    
    init() {}
    
    func perform() throws -> some IntentResult {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.luvlu.Near") {
            let current = sharedDefaults.bool(forKey: "isScanning")
            sharedDefaults.set(!current, forKey: "isScanning")
            sharedDefaults.synchronize()
        }
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), scanning: false, detectedCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let defaults = UserDefaults(suiteName: "group.com.luvlu.Near")
        let scanning = defaults?.bool(forKey: "isScanning") ?? false
        let count = defaults?.integer(forKey: "detectedCount") ?? 0
        let entry = SimpleEntry(date: Date(), scanning: scanning, detectedCount: count)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let defaults = UserDefaults(suiteName: "group.com.luvlu.Near")
        let scanning = defaults?.bool(forKey: "isScanning") ?? false
        let count = defaults?.integer(forKey: "detectedCount") ?? 0
        let entry = SimpleEntry(date: Date(), scanning: scanning, detectedCount: count)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let scanning: Bool
    let detectedCount: Int
}

struct RadarHUDView: View {
    let scanning: Bool
    
    var body: some View {
        ZStack {
            // Concentric Circles
            ForEach(1...4, id: \.self) { ring in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: CGFloat(ring) * 76 / 4, height: CGFloat(ring) * 76 / 4)
            }
            
            // Crosshairs
            Path { path in
                path.move(to: CGPoint(x: 4, y: 38))
                path.addLine(to: CGPoint(x: 72, y: 38))
                path.move(to: CGPoint(x: 38, y: 4))
                path.addLine(to: CGPoint(x: 38, y: 72))
            }
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
            
            if scanning {
                // Sweep angle
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(-60),
                            endAngle: .degrees(120)
                        )
                    )
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(30))
                
                // Sweep line
                Path { path in
                    path.move(to: CGPoint(x: 38, y: 38))
                    path.addLine(to: CGPoint(x: 38 + 26.8, y: 38 - 26.8)) // 45 degree angle line
                }
                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                
                // Center point
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.white, radius: 3)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 76, height: 76)
    }
}

struct NearWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }
    
    private var mediumLayout: some View {
        HStack(spacing: 24) {
            Spacer()
            
            RadarHUDView(scanning: entry.scanning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Devices Found")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(entry.detectedCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(entry.detectedCount == 0 ? "No devices detected yet" : (entry.detectedCount == 1 ? "1 device nearby" : "\(entry.detectedCount) devices nearby"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .containerBackground(for: .widget) {
            ZStack {
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 26/255, green: 43/255, blue: 76/255, alpha: 1)
                        : UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
                })
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .padding(1)
            }
        }
    }
    
    private var smallLayout: some View {
        VStack(spacing: 12) {
            Spacer()
            
            RadarHUDView(scanning: entry.scanning)
                .scaleEffect(0.8)
                .frame(width: 60, height: 60)
            
            VStack(spacing: 2) {
                Text("\(entry.detectedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(entry.detectedCount == 1 ? "device" : "devices")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
            }
            
            Spacer()
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ZStack {
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 26/255, green: 43/255, blue: 76/255, alpha: 1)
                        : UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
                })
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .padding(1)
            }
        }
    }
}

struct NearWidget: Widget {
    let kind: String = "NearWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NearWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Near Radar")
        .description("Shows the current scanning status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MiniRadarHUDView: View {
    let scanning: Bool
    let hasDetections: Bool
    var size: CGFloat = 28
    
    var color: Color {
        if hasDetections {
            return .red
        } else if scanning {
            return .green
        } else {
            return .gray
        }
    }
    
    var body: some View {
        ZStack {
            // Concentric Circles
            ForEach(1...3, id: \.self) { ring in
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 1)
                    .frame(width: CGFloat(ring) * size / 3, height: CGFloat(ring) * size / 3)
            }
            
            // Crosshairs
            Path { path in
                path.move(to: CGPoint(x: 2, y: size / 2))
                path.addLine(to: CGPoint(x: size - 2, y: size / 2))
                path.move(to: CGPoint(x: size / 2, y: 2))
                path.addLine(to: CGPoint(x: size / 2, y: size - 2))
            }
            .stroke(color.opacity(0.2), lineWidth: 0.8)
            
            if scanning {
                // Sweep angle
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.0),
                                color.opacity(0.6),
                                color.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(-60),
                            endAngle: .degrees(120)
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(30))
                
                // Center point
                Circle()
                    .fill(color)
                    .frame(width: max(3, size / 7), height: max(3, size / 7))
                    .shadow(color: color, radius: 2)
            } else {
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: max(3, size / 7), height: max(3, size / 7))
            }
        }
        .frame(width: size, height: size)
    }
}

struct NearLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NearActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 26/255, green: 43/255, blue: 76/255))
                        .frame(width: 48, height: 48)
                    
                    MiniRadarHUDView(
                        scanning: context.state.isScanning,
                        hasDetections: context.state.detectedCount > 0,
                        size: 34
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("NEAR RADAR")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Button(intent: ToggleScanIntent()) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(context.state.isScanning ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                                Text(context.state.isScanning ? "ACTIVE" : "PAUSED")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(context.state.isScanning ? .green : .orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let name = context.state.nearestDeviceName {
                        HStack(spacing: 6) {
                            Text(name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if let dist = context.state.nearestDeviceDistance {
                                Text("~\(String(format: "%.1f", dist))m")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            if let threat = context.state.threatLevel {
                                Text(threat.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(threat == "High" ? Color.red : Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        Text(context.state.detectedCount == 0 ? "Scanning • No devices nearby" : "\(context.state.detectedCount) devices in range")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 18/255, green: 30/255, blue: 55/255))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        MiniRadarHUDView(
                            scanning: context.state.isScanning,
                            hasDetections: context.state.detectedCount > 0,
                            size: 26
                        )
                        Text("Near")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: ToggleScanIntent()) {
                        HStack(spacing: 4) {
                            Text("\(context.state.detectedCount)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Image(systemName: "eyeglasses")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if let name = context.state.nearestDeviceName {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NEAREST DEVICE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            if let dist = context.state.nearestDeviceDistance {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("ESTIMATED DISTANCE")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("~\(String(format: "%.1f", dist))m")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(dist <= 1.0 ? .red : .yellow)
                                }
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        HStack {
                            Text("Radar scanning for nearby smart glasses")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                MiniRadarHUDView(
                    scanning: context.state.isScanning,
                    hasDetections: context.state.detectedCount > 0,
                    size: 20
                )
            } compactTrailing: {
                HStack(spacing: 2) {
                    Text("\(context.state.detectedCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(context.state.detectedCount > 0 ? .red : .white)
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            } minimal: {
                MiniRadarHUDView(
                    scanning: context.state.isScanning,
                    hasDetections: context.state.detectedCount > 0,
                    size: 18
                )
            }
        }
    }
}

struct SetScanningIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Set Radar Scanning"
    static var description = IntentDescription("Starts or stops Near Bluetooth radar scanning.")
    
    @Parameter(title: "Is Scanning")
    var value: Bool
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.luvlu.Near") {
            sharedDefaults.set(value, forKey: "isScanning")
            sharedDefaults.synchronize()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@available(iOS 18.0, *)
struct NearScanControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.luvlu.Near.NearScanControl") {
            ControlWidgetToggle(
                "Near Radar",
                isOn: NearScanStateValueProvider.isScanning,
                action: SetScanningIntent()
            ) { isScanning in
                Label(
                    isScanning ? "Scanning On" : "Scanning Off",
                    systemImage: isScanning ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward"
                )
            }
            .tint(.blue)
        }
        .displayName("Near Radar Control")
        .description("Quickly toggle Near BLE radar scanning from Control Center or Action Button.")
    }
}

@available(iOS 18.0, *)
struct NearScanStateValueProvider {
    static var isScanning: Bool {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.luvlu.Near") else { return false }
        return sharedDefaults.bool(forKey: "isScanning")
    }
}

@main
struct NearWidgetBundle: WidgetBundle {
    var body: some Widget {
        NearWidget()
        NearLiveActivityWidget()
        if #available(iOS 18.0, *) {
            NearScanControlWidget()
        }
    }
}

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
                    .stroke(Color(hex: "1A66FF").opacity(0.3), lineWidth: 1)
                    .frame(width: CGFloat(ring) * 76 / 4, height: CGFloat(ring) * 76 / 4)
            }
            
            // Crosshairs
            Path { path in
                path.move(to: CGPoint(x: 4, y: 38))
                path.addLine(to: CGPoint(x: 72, y: 38))
                path.move(to: CGPoint(x: 38, y: 4))
                path.addLine(to: CGPoint(x: 38, y: 72))
            }
            .stroke(Color(hex: "1A66FF").opacity(0.15), lineWidth: 1)
            
            if scanning {
                // Sweep angle
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "1A66FF").opacity(0.0),
                                Color(hex: "3399FF").opacity(0.4),
                                Color(hex: "1A66FF").opacity(0.0)
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
                .stroke(Color(hex: "3399FF"), lineWidth: 1.5)
                
                // Center point
                Circle()
                    .fill(Color(hex: "3399FF"))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color(hex: "3399FF"), radius: 3)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Nearby")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Settings button Link
                Link(destination: URL(string: "nearbyapp://settings")!) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Middle Content: Radar & Stats
            HStack(spacing: 16) {
                RadarHUDView(scanning: entry.scanning)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Devices Found")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(entry.detectedCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(entry.detectedCount == 0 ? "No devices detected yet" : (entry.detectedCount == 1 ? "1 device nearby" : "\(entry.detectedCount) devices nearby"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Bottom Controls Row
            HStack(spacing: 12) {
                // Interactive Scan Toggle button
                Button(intent: ToggleScanIntent()) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text(entry.scanning ? "Stop Scanning" : "Start Scanning")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .frame(height: 38)
                
                // History Link button
                Link(destination: URL(string: "nearbyapp://history")!) {
                    Image(systemName: "clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "0A3580"),
                        Color(hex: "021438")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "1A66FF").opacity(0.3), lineWidth: 1.5)
                    .padding(1)
            }
        }
    }
    
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "eyeglasses")
                    .foregroundColor(.white)
                Spacer()
                if entry.scanning {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: .green, radius: 3)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.detectedCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(entry.detectedCount == 1 ? "device" : "devices")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
            }
            
            Spacer()
            
            Button(intent: ToggleScanIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .bold))
                    Text(entry.scanning ? "Stop" : "Start")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(entry.scanning ? Color.white.opacity(0.12) : Color.blue)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "0A3580"),
                        Color(hex: "021438")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "1A66FF").opacity(0.3), lineWidth: 1.5)
                    .padding(1)
            }
        }
    }
}

@main
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

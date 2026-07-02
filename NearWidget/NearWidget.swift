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

struct WidgetBackground: View {
    let scanning: Bool
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: scanning ? [
                Color(hex: "0E1A30"), // Rich navy
                Color(hex: "050B14")  // Midnight black
            ] : [
                Color(hex: "1F2124"), // Charcoal
                Color(hex: "101112")  // Muted dark
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct RadarHUDView: View {
    let scanning: Bool
    let count: Int
    
    var body: some View {
        ZStack {
            // Outer Ring
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 1.5)
                .frame(width: 80, height: 80)
            
            // Middle Dashed Ring
            Circle()
                .stroke(Color.blue.opacity(0.25), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, miterLimit: 10, dash: [4, 4], dashPhase: 0))
                .frame(width: 54, height: 54)
            
            // Inner Ring
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                .frame(width: 28, height: 28)
            
            if scanning {
                // Glow sweep
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.0),
                                Color.cyan.opacity(0.4),
                                Color.blue.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(-60),
                            endAngle: .degrees(120)
                        )
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(30))
                
                // Simulated detected device targets (little glowing dots in the radar field)
                if count > 0 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                        .offset(x: 18, y: -22)
                        .shadow(color: .green, radius: 4)
                }
                
                if count > 1 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                        .offset(x: -24, y: 12)
                        .shadow(color: .green, radius: 3)
                }
                
                // Pulsing Center dot
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: .cyan, radius: 4)
            } else {
                // Static paused dot
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
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
        HStack(spacing: 20) {
            // Left Side: App logo, status, and button
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan.opacity(0.5), radius: 4)
                    Text("Nearby")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 6) {
                    if entry.scanning {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .shadow(color: .green, radius: 3)
                        Text("Radar Active")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                        Text("Radar Paused")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 4)
                
                Button(intent: ToggleScanIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: entry.scanning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(entry.scanning ? "Pause Radar" : "Start Radar")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        entry.scanning ? Color.white.opacity(0.12) : Color.blue
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(entry.scanning ? Color.white.opacity(0.15) : Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Divider
            Spacer()
            
            // Right Side: Radar graphic and count
            VStack(spacing: 10) {
                RadarHUDView(scanning: entry.scanning, count: entry.detectedCount)
                    .frame(width: 80, height: 80)
                
                HStack(spacing: 4) {
                    Text("\(entry.detectedCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(entry.detectedCount == 1 ? "device" : "devices")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetBackground(scanning: entry.scanning)
        }
    }
    
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eyeglasses")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 4)
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
                Text(entry.detectedCount == 1 ? "device nearby" : "devices nearby")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            Spacer()
            
            Button(intent: ToggleScanIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: entry.scanning ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(entry.scanning ? "Pause" : "Scan")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(entry.scanning ? Color.white.opacity(0.12) : Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            WidgetBackground(scanning: entry.scanning)
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

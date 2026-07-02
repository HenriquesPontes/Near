import WidgetKit
import SwiftUI
import AppIntents

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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "eyeglasses")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Nearby")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text(entry.scanning ? "Scanning Active" : "Scanning Paused")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 4)
                
                Button(intent: ToggleScanIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: entry.scanning ? "pause.fill" : "play.fill")
                            .imageScale(.small)
                        Text(entry.scanning ? "Pause" : "Scan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .background(entry.scanning ? Color.red.opacity(0.12) : Color.blue.opacity(0.12))
                    .foregroundColor(entry.scanning ? .red : .blue)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            // Divider
            Divider()
                .padding(.vertical, 8)
            
            // Right Side: Radar graphic and count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        .frame(width: 76, height: 76)
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .frame(width: 20, height: 20)
                    
                    if entry.scanning {
                        // Radar sweep segment simulation
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.0), .blue.opacity(0.4)]),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(120)
                                )
                            )
                            .frame(width: 76, height: 76)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 80, height: 80)
                
                HStack(spacing: 4) {
                    Text("\(entry.detectedCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text(entry.detectedCount == 1 ? "device" : "devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
    
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "eyeglasses")
                    .foregroundColor(.blue)
                Spacer()
                if entry.scanning {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(entry.detectedCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                Text(entry.detectedCount == 1 ? "device" : "devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 6)
            }
            
            Text(entry.scanning ? "Active" : "Paused")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
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

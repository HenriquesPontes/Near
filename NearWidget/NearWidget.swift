import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), scanning: true, detectedCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), scanning: true, detectedCount: 1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // This is a simple placeholder timeline. In a real app, you would fetch data from AppGroup UserDefaults.
        let entry = SimpleEntry(date: Date(), scanning: true, detectedCount: 0)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eyeglasses")
                    .foregroundColor(.blue)
                Text("Near")
                    .font(.headline)
                Spacer()
                if entry.scanning {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(entry.scanning ? "Scanning Active" : "Scanning Paused")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if entry.detectedCount > 0 {
                Text("\(entry.detectedCount) devices detected")
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
            }
        }
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

import SwiftUI

struct DeviceRowView: View {
    let name: String
    let type: String
    let manufacturer: String?
    let rssi: Int
    let isStarred: Bool
    let timestamp: Date?
    let estimatedDistance: Double
    
    var body: some View {
        HStack(spacing: 12) {
            DeviceIconView(icon: iconForType(type), color: colorForType(type))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if isStarred {
                        Image("Star")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.yellow)
                            .accessibilityLabel("Starred")
                    }
                }
                
                let typeName = displayNameForType(type, manufacturer: manufacturer)
                let mfgName = manufacturer ?? "Unknown Manufacturer"
                let subtitle = (typeName == mfgName) ? typeName : (name.contains(typeName) ? mfgName : "\(typeName) • \(mfgName)")
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    if let timestamp = timestamp {
                        Image("Clock")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        Text(timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    
                    Image("Wifi_High")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(colorForRssi(rssi))
                        .accessibilityHidden(true)
                    Text("\(rssi) dBm")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorForRssi(rssi))
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Image("Map_Pin")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text(String(format: "%.1fm", estimatedDistance))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

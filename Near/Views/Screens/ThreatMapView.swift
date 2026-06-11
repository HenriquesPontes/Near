import SwiftUI
import MapKit
import SwiftData

struct ThreatMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    
    @State private var position: MapCameraPosition = .automatic
    
    var mapAnnotations: [DetectedDevice] {
        historicalDevices.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(mapAnnotations) { device in
                    Annotation(device.name, coordinate: CLLocationCoordinate2D(latitude: device.latitude!, longitude: device.longitude!)) {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(colorForThreat(device.threatLevel))
                                .font(.title2)
                                .background(Circle().fill(Color.white).frame(width: 30, height: 30))
                            Text(device.name)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            if mapAnnotations.isEmpty {
                VStack {
                    Spacer()
                    Text("No geographical threat data yet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.9))
                        .cornerRadius(12)
                    Spacer()
                }
            }
        }
        .navigationTitle("Geographic Threat Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            LocationManager.shared.currentLocation = LocationManager.shared.currentLocation // Trigger location manager start
        }
    }
    
    private func colorForThreat(_ threatLevel: String) -> Color {
        switch threatLevel.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .gray
        }
    }
}

#Preview {
    ThreatMapView()
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}

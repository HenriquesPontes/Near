//
//  DashboardView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData
internal import CoreLocation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @ObservedObject var btManager = BluetoothManager.shared
    @ObservedObject var trustedManager = TrustedDeviceManager.shared
    
    @AppStorage("hasAcceptedRadarModeWarning") private var hasAcceptedRadarModeWarning = false
    @State private var showRadarWarning = false
    @State private var showLocationSettingsAlert = false
    @State private var showingClearConfirmation = false
    @State private var navigateToScan = false
    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                List {
                    headerCardRow
                    
                    if historicalDevices.isEmpty && btManager.detectedDevices.isEmpty {
                        emptyStateRow
                    } else {
                        currentlyNearbySection
                        recentlyScannedSection
                        clearHistorySection
                    }
                }
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    btManager.detectedDevices.removeAll()
                    if !btManager.isScanning {
                        btManager.startScanning()
                    }
                }
                .navigationDestination(for: BluetoothDevice.self) { device in
                    let historyDevice = historicalDevices.first(where: { $0.deviceId == device.deviceId }) ?? DetectedDevice(
                        deviceId: device.deviceId,
                        name: device.name,
                        type: device.type,
                        rssi: device.rssi,
                        isStarred: false,
                        threatLevel: device.threatLevel,
                        isSimulated: device.isSimulated,
                        companyID: device.companyID,
                        manufacturer: device.manufacturer
                    )
                    DeviceDetailView(device: historyDevice)
                }
                .confirmationDialog("Are you sure you want to delete all detections?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                    Button("Delete All Detections", role: .destructive) {
                        clearSearchHistory()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 16) {
                        // Radar Status Bar
                        // Buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // SCAN Button
                                NavigationLink(destination: ScanRadarView()) {
                                    Text("Start Scanning")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(DesignSystem.heroBackground)
                                        .clipShape(Capsule())
                                }
                                
                                // HISTORY Button
                                NavigationLink(destination: AllResultsView()) {
                                    Image("Clock")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(DesignSystem.primaryBlue)
                                        .frame(width: 52, height: 52)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }

                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: DesignSystem.backgroundColor, location: 0.7),
                                .init(color: DesignSystem.backgroundColor, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Settings Button
                    NavigationLink(destination: SettingsView()) {
                        Image("Settings")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Enable Radar Mode?", isPresented: $showRadarWarning) {
                Button("Cancel", role: .cancel) {
                }
                Button("Accept") {
                    hasAcceptedRadarModeWarning = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                        btManager.continueScanInBackground = true
                    }
                }
            } message: {
                Text("The app will scan for devices in the background and app notifies you when smart glasses are nearby")
            }
            .alert("Location Access Required", isPresented: $showLocationSettingsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Radar Mode requires 'Always' location access to scan in the background. Please change this in Settings.")
            }

            // Listen to BLE Manager alerts
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewDeviceDetectedHistory"))) { notification in
                if let btDevice = notification.object as? BluetoothDevice {
                    addHistoricalLog(device: btDevice)
                }
            }
            .navigationDestination(isPresented: $navigateToScan) {
                ScanRadarView()
            }
            .onOpenURL { url in
                if url.absoluteString == "nearbyapp://scan" {
                    btManager.detectedDevices.removeAll()
                    if !btManager.isScanning {
                        btManager.startScanning()
                    }
                    navigateToScan = true
                }
            }
        }
    }
    
    private func addHistoricalLog(device: BluetoothDevice) {
        // Verify duplicate (within last 30 seconds) to avoid spamming the log list
        let checkTime = Date().addingTimeInterval(-30)
        let deviceId = device.deviceId
        
        let descriptor = FetchDescriptor<DetectedDevice>(
            predicate: #Predicate { $0.deviceId == deviceId && $0.timestamp > checkTime }
        )
        
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            // Already logged recently, just update RSSI and timestamp
            if let first = existing.first {
                first.rssi = device.rssi
                first.timestamp = Date()
                if first.manufacturer == nil {
                    first.manufacturer = device.manufacturer
                }
                if first.companyID == nil {
                    first.companyID = device.companyID
                }
                if let loc = LocationManager.shared.currentLocation {
                    first.latitude = loc.latitude
                    first.longitude = loc.longitude
                }
                try? modelContext.save()
            }
            return
        }
        
        // Stalker Detection Logic
        if let currentLoc = LocationManager.shared.currentLocation, 
           !TrustedDeviceManager.shared.isTrusted(id: device.deviceId) {
            let allDetectionsDescriptor = FetchDescriptor<DetectedDevice>(
                predicate: #Predicate { $0.deviceId == deviceId }
            )
            if let allPrevious = try? modelContext.fetch(allDetectionsDescriptor) {
                for previous in allPrevious {
                    if let prevLat = previous.latitude, let prevLon = previous.longitude {
                        let prevCLLoc = CLLocation(latitude: prevLat, longitude: prevLon)
                        let currCLLoc = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                        let distance = currCLLoc.distance(from: prevCLLoc)
                        // If detected > 500 meters away from a previous detection, and it's not a trusted device
                        if distance > 500 {
                            NotificationManager.shared.scheduleNotification(title: String(localized: "Possible Tracking Detected"), body: String(localized: "An unknown device (\(device.name)) is following you. It was detected at multiple distant locations."), identifier: "stalker_\(device.deviceId)")
                            break
                        }
                    }
                }
            }
        }
        
        let newLog = DetectedDevice(
            deviceId: device.deviceId,
            name: device.name,
            type: device.type,
            rssi: device.rssi,
            isStarred: false,
            threatLevel: device.threatLevel,
            isSimulated: device.isSimulated,
            companyID: device.companyID,
            manufacturer: device.manufacturer,
            latitude: LocationManager.shared.currentLocation?.latitude,
            longitude: LocationManager.shared.currentLocation?.longitude
        )
        
        modelContext.insert(newLog)
        try? modelContext.save()
        PersistentLogger.shared.logDetection(newLog)
    }
    
    private func deleteDevices(offsets: IndexSet) {
        PersistentLogger.shared.logActivity("User deleted \(offsets.count) history record(s) manually.")
        withAnimation {
            for index in offsets {
                modelContext.delete(historicalDevices[index])
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDevice(_ device: DetectedDevice) {
        modelContext.delete(device)
        try? modelContext.save()
    }
    
    private func clearSearchHistory() {
        for device in historicalDevices {
            modelContext.delete(device)
        }
        try? modelContext.save()
        PersistentLogger.shared.logActivity("User cleared all search history manually.")
    }
    
    @ViewBuilder
    private var headerCardRow: some View {
        StatusHeaderCard(
            deviceCount: btManager.detectedDevices.count,
            isRadarActive: btManager.continueScanInBackground,
            onRadarModeToggle: {
                if !btManager.continueScanInBackground {
                    if !hasAcceptedRadarModeWarning {
                        showRadarWarning = true
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                            btManager.continueScanInBackground = true
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                        btManager.continueScanInBackground = false
                    }
                }
            }
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var emptyStateRow: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 100)
            Image("Shield_Warning")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.secondary.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityHidden(true)
            Text("No devices detected yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary.opacity(0.8))
            Text("Tap Start Scanning below to scan for nearby devices.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .frame(maxWidth: .infinity, minHeight: 320)
    }
    
    @ViewBuilder
    private var currentlyNearbySection: some View {
        if !btManager.detectedDevices.isEmpty {
            Section(header: 
                HStack(spacing: 6) {
                    Text("Currently Nearby")
                    if btManager.isScanning {
                        ProgressView()
                            .controlSize(.mini)
                            .id(btManager.isScanning)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            ) {
                let count = btManager.detectedDevices.count
                ForEach(Array(btManager.detectedDevices.enumerated()), id: \.element.id) { index, device in
                    VStack(spacing: 0) {
                        NavigationLink(value: device) {
                            DeviceRowView(
                                name: device.name,
                                type: device.type,
                                manufacturer: device.manufacturer,
                                rssi: device.rssi,
                                isStarred: false,
                                isTrusted: trustedManager.isTrusted(id: device.deviceId),
                                timestamp: nil,
                                estimatedDistance: device.estimatedDistance
                            )
                        }
                        
                        if index < count - 1 {
                            Divider()
                                .padding(.leading, 44)
                                .padding(.top, 8)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if trustedManager.isTrusted(id: device.deviceId) {
                            Button(role: .destructive) {
                                trustedManager.untrustDevice(id: device.deviceId)
                            } label: {
                                Label("Untrust", systemImage: "xmark.shield")
                            }
                        } else {
                            Button {
                                trustedManager.trustDevice(id: device.deviceId, name: device.name)
                            } label: {
                                Label("Trust", systemImage: "checkmark.shield")
                            }
                            .tint(.green)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 28, bottom: index == count - 1 ? 8 : 0, trailing: 28))
                    .listRowBackground(
                        GroupedRowBackground(index: index, count: count)
                    )
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
    
    @ViewBuilder
    private var recentlyScannedSection: some View {
        if !historicalDevices.isEmpty {
            Section(header:
                Text("Recently Scanned")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            ) {
                let count = historicalDevices.count
                ForEach(Array(historicalDevices.enumerated()), id: \.element.id) { index, device in
                    let isTrusted = trustedManager.isTrusted(id: device.deviceId)
                    VStack(spacing: 0) {
                        NavigationLink(value: device) {
                            DeviceRowView(
                                name: device.name,
                                type: device.type,
                                manufacturer: device.manufacturer,
                                rssi: device.rssi,
                                isStarred: false,
                                isTrusted: isTrusted,
                                timestamp: device.timestamp,
                                estimatedDistance: estimatedDistance(for: device.rssi)
                            )
                        }
                        
                        if index < count - 1 {
                            Divider()
                                .padding(.leading, 44)
                                .padding(.top, 8)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if isTrusted {
                            Button(role: .destructive) {
                                trustedManager.untrustDevice(id: device.deviceId)
                            } label: {
                                Label("Untrust", systemImage: "xmark.shield")
                            }
                        } else {
                            Button {
                                trustedManager.trustDevice(id: device.deviceId, name: device.name)
                            } label: {
                                Label("Trust", systemImage: "checkmark.shield")
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteDevice(device)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 28, bottom: index == count - 1 ? 8 : 0, trailing: 28))
                    .listRowBackground(
                        GroupedRowBackground(index: index, count: count)
                    )
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteDevices)
            }
        }
    }
    
    @ViewBuilder
    private var clearHistorySection: some View {
        if !historicalDevices.isEmpty {
            let totalRows = 1
            Section {
                Button(action: {
                    showingClearConfirmation = true
                }) {
                    Text("Clear Search History")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 28, bottom: 12, trailing: 28))
                .listRowBackground(
                    GroupedRowBackground(index: totalRows - 1, count: totalRows)
                )
                .listRowSeparator(.hidden)
            }
        }
    }
}

struct AllResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @ObservedObject var trustedManager = TrustedDeviceManager.shared
    
    @State private var showingClearConfirmation = false
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var currentThreatLevel: String = "Low"
    @State private var showStarredOnly = false
    @State private var filterType: String? = nil
    @State private var filterSignal: String? = nil
    @State private var filterDeviceName: String? = nil
    
    var uniqueDeviceNames: [String] {
        Array(Set(historicalDevices.map { $0.name })).sorted()
    }
    
    var uniqueTypes: [String] {
        Array(Set(historicalDevices.map { $0.type })).sorted()
    }
    
    var isFilterActive: Bool {
        showStarredOnly || filterType != nil || filterSignal != nil || filterDeviceName != nil
    }
    
    var filteredDevices: [DetectedDevice] {
        var devices = historicalDevices
        
        if showStarredOnly {
            devices = devices.filter { $0.isStarred }
        }
        
        if let type = filterType {
            devices = devices.filter { $0.type == type }
        }
        
        if let signal = filterSignal {
            switch signal {
            case "Excellent":
                devices = devices.filter { $0.rssi > -60 }
            case "Good":
                devices = devices.filter { $0.rssi <= -60 && $0.rssi > -80 }
            case "Weak":
                devices = devices.filter { $0.rssi <= -80 }
            default: break
            }
        }
        
        if let name = filterDeviceName {
            devices = devices.filter { $0.name == name }
        }
        
        if !searchText.isEmpty {
            devices = devices.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                displayNameForType($0.type, manufacturer: $0.manufacturer).localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return devices
    }
    
    var body: some View {
        List {
            ForEach(filteredDevices) { device in
                NavigationLink(destination: DeviceDetailView(device: device)) {
                    DeviceRowView(
                        name: device.name,
                        type: device.type,
                        manufacturer: device.manufacturer,
                        rssi: device.rssi,
                        isStarred: device.isStarred,
                        isTrusted: trustedManager.isTrusted(id: device.deviceId),
                        timestamp: device.timestamp,
                        estimatedDistance: Nearbyglasses.estimatedDistance(for: device.rssi)
                    )
                }
                .swipeActions(edge: .leading) {
                    if trustedManager.isTrusted(id: device.deviceId) {
                        Button(role: .destructive) {
                            trustedManager.untrustDevice(id: device.deviceId)
                        } label: {
                            Label("Untrust", systemImage: "xmark.shield")
                        }
                    } else {
                        Button {
                            trustedManager.trustDevice(id: device.deviceId, name: device.name)
                        } label: {
                            Label("Trust", systemImage: "checkmark.shield")
                        }
                        .tint(.green)
                    }
                }
            }
            .onDelete(perform: deleteDevices)
        }
        .overlay {
            if filteredDevices.isEmpty {
                ContentUnavailableView(
                    "No Detections",
                    systemImage: "magnifyingglass",
                    description: searchText.isEmpty ? Text("No devices have been detected yet.") : Text("No devices found for \"\(searchText)\".")
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .searchable(text: $searchText, prompt: "Search detections")
        .navigationTitle("All Detections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if !historicalDevices.isEmpty {
                        Button {
                            showingClearConfirmation = true
                        } label: {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                    Menu {
                        Section("Status") {
                            Button {
                                showStarredOnly.toggle()
                            } label: {
                                if showStarredOnly {
                                    Label("Starred Only", systemImage: "checkmark")
                                } else {
                                    Text("Starred Only")
                                }
                            }
                        }
                        
                        Section("Device Channel (Type)") {
                            Button { filterType = nil } label: {
                                if filterType == nil {
                                    Label("All Channels", systemImage: "checkmark")
                                } else {
                                    Text("All Channels")
                                }
                            }
                            ForEach(uniqueTypes, id: \.self) { type in
                                Button {
                                    filterType = type
                                } label: {
                                    if filterType == type {
                                        Label(displayNameForType(type), systemImage: "checkmark")
                                    } else {
                                        Text(displayNameForType(type))
                                    }
                                }
                            }
                        }
                        
                        Section("Signal Strength") {
                            Button { filterSignal = nil } label: {
                                if filterSignal == nil {
                                    Label("All Signals", systemImage: "checkmark")
                                } else {
                                    Text("All Signals")
                                }
                            }
                            Button {
                                filterSignal = "Excellent"
                            } label: {
                                if filterSignal == "Excellent" {
                                    Label("Excellent (>-60dBm)", systemImage: "checkmark")
                                } else {
                                    Text("Excellent (>-60dBm)")
                                }
                            }
                            Button {
                                filterSignal = "Good"
                            } label: {
                                if filterSignal == "Good" {
                                    Label("Good (>-80dBm)", systemImage: "checkmark")
                                } else {
                                    Text("Good (>-80dBm)")
                                }
                            }
                            Button {
                                filterSignal = "Weak"
                            } label: {
                                if filterSignal == "Weak" {
                                    Label("Weak (<=-80dBm)", systemImage: "checkmark")
                                } else {
                                    Text("Weak (<=-80dBm)")
                                }
                            }
                        }
                        
                        Section("Device Name") {
                            Button { filterDeviceName = nil } label: {
                                if filterDeviceName == nil {
                                    Label("All Devices", systemImage: "checkmark")
                                } else {
                                    Text("All Devices")
                                }
                            }
                            // Showing up to 10 unique names to avoid an overwhelmingly large menu
                            ForEach(uniqueDeviceNames.prefix(10), id: \.self) { name in
                                Button {
                                    filterDeviceName = name
                                } label: {
                                    if filterDeviceName == name {
                                        Label(name, systemImage: "checkmark")
                                    } else {
                                        Text(name)
                                    }
                                }
                            }
                        }
                        
                        if isFilterActive {
                            Section {
                                Button("Clear All Filters", role: .destructive) {
                                    showStarredOnly = false
                                    filterType = nil
                                    filterSignal = nil
                                    filterDeviceName = nil
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Filter")
                            Image(isFilterActive ? "Filter" : "Filter_Off")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete all detections?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                clearAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func clearAll() {
        PersistentLogger.shared.logActivity("User cleared all history.")
        withAnimation {
            for device in historicalDevices {
                modelContext.delete(device)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDevices(offsets: IndexSet) {
        PersistentLogger.shared.logActivity("User deleted \(offsets.count) history record(s) manually.")
        withAnimation {
            for index in offsets {
                let device = filteredDevices[index]
                modelContext.delete(device)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct GroupedRowBackground: View {
    let index: Int
    let count: Int
    
    var body: some View {
        Group {
            if count == 1 {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(DesignSystem.cardBackground)
            } else if index == 0 {
                RoundedCorner(radius: 22, corners: [.topLeft, .topRight])
                    .fill(DesignSystem.cardBackground)
            } else if index == count - 1 {
                RoundedCorner(radius: 22, corners: [.bottomLeft, .bottomRight])
                    .fill(DesignSystem.cardBackground)
            } else {
                Rectangle()
                    .fill(DesignSystem.cardBackground)
            }
        }
        .padding(.horizontal, 16)
    }
}

//
//  SettingsView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
internal import CoreLocation
import SwiftData

struct SettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @AppStorage("selectedLanguage") var selectedLanguage: String = Bundle.main.preferredLocalizations.first ?? "en"
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @State private var versionTapCount = 0
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.2"
    }
    
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "3"
    }
    
    var body: some View {
        List {
            // SECTION 1: GENERAL
            Section(header: Text("General")) {
                // Notifications Row
                HStack(spacing: 16) {
                    Image("Bell")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("Notifications")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $btManager.alertOnNewDevices)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .labelsHidden()
                }
                
                // App Badge Row
                HStack(spacing: 16) {
                    Image(systemName: "app.badge")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("App Badge")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $btManager.enableAppBadge)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .labelsHidden()
                }
                
                // Appearance Row
                HStack(spacing: 16) {
                    Image("Swatches_Palette")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("Appearance")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Picker("", selection: $btManager.appAppearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                // Language Row
                HStack(spacing: 16) {
                    Image("Globe")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("Language")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Picker("", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                        Text("Français").tag("fr")
                        Text("Español").tag("es")
                        Text("Italiano").tag("it")
                        Text("Português").tag("pt")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                // Privacy Row
                NavigationLink {
                    PrivacySettingsView(historicalDevices: historicalDevices)
                } label: {
                    HStack(spacing: 16) {
                        Image("Stop_Sign")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Privacy")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            
            // SECTION 2: SCANNING
            Section(header: Text("Scanning")) {
                // Scan Range Row
                NavigationLink {
                    ScanRangeSettingsView()
                } label: {
                    HStack(spacing: 16) {
                        Image("Search_Magnifying_Glass")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Scan Preference")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Device Filters Row
                NavigationLink {
                    DeviceFiltersSettingsView()
                } label: {
                    HStack(spacing: 16) {
                        Image("Slider_03")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Device Channel")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Trusted Devices Row
                NavigationLink {
                    TrustedDevicesSettingsView()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.shield")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Trusted Devices")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            
            // SECTION 3: ABOUT
            Section(header: Text("About")) {
                // Version Row
                HStack(spacing: 16) {
                    Image("Text")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("Version")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("\(appVersion) (\(appBuild))")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isDeveloperModeEnabled {
                        versionTapCount += 1
                        if versionTapCount >= 5 {
                            withAnimation {
                                isDeveloperModeEnabled = true
                            }
                            versionTapCount = 0
                        }
                    }
                }
                
                // About NearbyGlasses Row
                NavigationLink {
                    AboutNearView()
                } label: {
                    HStack(spacing: 16) {
                        Image("Info")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("About Near")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Licences Row
                NavigationLink {
                    LicensesSettingsView()
                } label: {
                    HStack(spacing: 16) {
                        Image("File_Document")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Licences")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            } // Close About section
            
            if isDeveloperModeEnabled {
                // SECTION 4: DEVELOPER
                Section(header: Text("Developer")) {
                    HStack(spacing: 16) {
                        Image("Warning")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Toggle("Developer Mode", isOn: $isDeveloperModeEnabled.animation())
                            .font(.system(size: 16, weight: .medium))
                            .tint(.blue)
                    }
                    
                    HStack(spacing: 16) {
                        Image(systemName: "cpu")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Toggle("Simulation Devices", isOn: $btManager.isSimulationEnabled.animation())
                            .font(.system(size: 16, weight: .medium))
                            .tint(.blue)
                    }

                    Button(action: {
                        btManager.simulateAllNotifications()
                    }) {
                        HStack(spacing: 16) {
                            Image("Bell_Notification")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                                .frame(width: 24, height: 24)
                            Text("Simulate Detections (Test Notifications)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable Row Styling Components



// MARK: - Sub-Screens

struct TrustedDevicesSettingsView: View {
    @ObservedObject var trustedManager = TrustedDeviceManager.shared
    
    var body: some View {
        List {
            Section(header: Text("Trusted Devices"), footer: Text("These devices will be ignored and won't trigger any alerts.")) {
                if trustedManager.trustedDevices.isEmpty {
                    Text("No trusted devices")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(trustedManager.trustedDevices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("ID: \(device.deviceId)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let device = trustedManager.trustedDevices[index]
                            trustedManager.untrustDevice(id: device.deviceId)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Trusted Devices")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ScanRangeSettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCooldownSheet = false
    @State private var showTimeoutSheet = false
    @AppStorage("hasAcceptedRadarModeWarning") private var hasAcceptedRadarModeWarning = false
    @State private var showRadarWarning = false
    @State private var showLocationSettingsAlert = false
    
    var radarModeBinding: Binding<Bool> {
        Binding(
            get: { btManager.continueScanInBackground },
            set: { newValue in
                if newValue {
                    if !hasAcceptedRadarModeWarning {
                        showRadarWarning = true
                    } else {
                        btManager.continueScanInBackground = newValue
                    }
                } else {
                    btManager.continueScanInBackground = newValue
                }
            }
        )
    }
    
    var body: some View {
        List {
            // Radar Mode Toggle
            Section(
                header: Text("Radar Mode"),
                footer: Group {
                    #if os(iOS)
                    if UIApplication.shared.backgroundRefreshStatus == .denied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image("Warning")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.orange)
                                Text("Background App Refresh is disabled. Radar Mode cannot run in the background. Tap to open Settings.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    } else if UIApplication.shared.backgroundRefreshStatus == .restricted {
                        HStack(spacing: 8) {
                            Image("Warning")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.orange)
                            Text("Background App Refresh is restricted on this device. Radar Mode cannot run in the background.")
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.leading)
                        }
                    } else {
                        Text("Radar Mode scans for smart wearable signals in the background, allowing the app to send alerts when in your pocket.")
                    }
                    #else
                    Text("Radar Mode scans for smart wearable signals in the background, allowing the app to send alerts when in your pocket.")
                    #endif
                }
            ) {
                HStack(spacing: 16) {
                    Image("Wifi_High")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    Text("Radar Mode")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Toggle("", isOn: radarModeBinding)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .labelsHidden()
                }
            }
            // Notification Cooldown
            Section(header: Text("Notification Cooldown")) {
                Button {
                    showCooldownSheet = true
                } label: {
                    HStack(spacing: 16) {
                        Image("Timer")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Notification Cooldown")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if btManager.isNotificationCooldownEnabled {
                            Text("\(Int(btManager.notificationCooldown / 60000)) min")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Off")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Scan Timeout
            Section(header: Text("Scan Timeout")) {
                Button {
                    showTimeoutSheet = true
                } label: {
                    HStack(spacing: 16) {
                        Image("Timer")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Auto-Stop Scan")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if btManager.scanTimeout == 0 {
                            Text("Never")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(Int(btManager.scanTimeout / 60)) min")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Scan Preference")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCooldownSheet) {
            NavigationStack {
                CooldownSettingsView()
            }
            .presentationDetents([.height(300), .medium])
        }
        .sheet(isPresented: $showTimeoutSheet) {
            NavigationStack {
                TimeoutSettingsView()
            }
            .presentationDetents([.height(300), .medium])
        }
        .alert("Enable Radar Mode?", isPresented: $showRadarWarning) {
            Button("Cancel", role: .cancel) {
            }
            Button("Accept") {
                hasAcceptedRadarModeWarning = true
                btManager.continueScanInBackground = true
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
    }
}

struct DeviceFiltersSettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSensitivitySheet = false
    
    private var sensitivityLabel: LocalizedStringKey {
        switch btManager.rssiThreshold {
        case -60...(-40):
            return "Near (Direct proximity, ~2m)"
        case -79...(-61):
            return "Medium (Same room, ~5m)"
        default:
            return "Far (Long range, ~15m)"
        }
    }
    
    var body: some View {
        List {
            // Detection Sensitivity
            Section(header: Text("Detection Sensitivity")) {
                Button {
                    showSensitivitySheet = true
                } label: {
                    HStack(spacing: 16) {
                        Image("Slider_03")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        Text("Detection Sensitivity")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(sensitivityLabel)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Detected Glasses Channel")) {
                SettingsFilterToggleRow(
                    title: "Meta AI Glasses",
                    description: "Ray-Ban Meta, Oakley Meta, Oakley Meta Vanguard, Meta Ray-Ban Display, Project Aria, Orion",
                    icon: iconForType("rayban_meta"),
                    color: .red,
                    isOn: bindingForTypes(["rayban_meta", "oakley_meta", "oakley_meta_vanguard", "project_aria", "meta_orion", "meta_rayban_display", "other_meta_glasses"])
                )
                
                SettingsFilterToggleRow(
                    title: "Apple Devices",
                    description: "Apple electronics and wearables",
                    icon: iconForType("vision_pro"),
                    color: .purple,
                    isOn: bindingForTypes(["vision_pro"])
                )
                
                SettingsFilterToggleRow(
                    title: "Snapchat Spectacles",
                    description: "AR recording and sharing HUD",
                    icon: iconForType("snap_spectacles"),
                    color: .yellow,
                    isOn: bindingForTypes(["snap_spectacles"])
                )
                
                SettingsFilterToggleRow(
                    title: "Google AI Glasses",
                    description: "Google Glass, Gentle Monster, Warby Parker, XREAL",
                    icon: iconForType("google_glass"),
                    color: .green,
                    isOn: bindingForTypes(["google_glass", "google_gentle_monster", "google_warby_parker", "google_xreal"])
                )
                
                SettingsFilterToggleRow(
                    title: "Samsung Devices",
                    description: "Samsung electronics and wearables",
                    icon: iconForType("samsung_glasses"),
                    color: .blue,
                    isOn: bindingForTypes(["samsung_glasses"])
                )
                
                SettingsFilterToggleRow(
                    title: "Other Camera Glasses",
                    description: "OhO Sunshine, iVue, Brilliant Labs",
                    icon: iconForType("oho_sunshine"),
                    color: .teal,
                    isOn: bindingForTypes(["oho_sunshine", "ivue_glasses", "brilliant_labs"])
                )
                
                SettingsFilterToggleRow(
                    title: "Unknown Devices",
                    description: "Unidentified bluetooth emissions",
                    icon: iconForType("unknown"),
                    color: .gray,
                    isOn: bindingForTypes(["unknown"])
                )
            }
            
            Section(header: Text("Ignored Devices")) {
                if btManager.ignoredDevices.isEmpty {
                    Text("No ignored devices")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                } else {
                    let keys = Array(btManager.ignoredDevices.keys).sorted()
                    ForEach(keys, id: \.self) { id in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let deviceName = btManager.ignoredDevices[id] {
                                    Text(deviceName)
                                        .font(.system(size: 16, weight: .semibold))
                                } else {
                                    Text("Unknown Device")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text("ID: \(id)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                withAnimation {
                                    btManager.unignoreDevice(id: id)
                                }
                            } label: {
                                Text("Restore")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Device Channel")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSensitivitySheet) {
            NavigationStack {
                SensitivitySettingsView()
            }
            .presentationDetents([.height(300), .medium])
        }
    }
    
    private func bindingForTypes(_ types: [String]) -> Binding<Bool> {
        Binding(
            get: { types.allSatisfy { btManager.enabledAlertTypes.contains($0) } },
            set: { enabled in
                if enabled {
                    for type in types {
                        btManager.enabledAlertTypes.insert(type)
                    }
                } else {
                    for type in types {
                        btManager.enabledAlertTypes.remove(type)
                    }
                }
            }
        )
    }
}

struct SettingsFilterToggleRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            DeviceIconView(icon: icon, color: color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss
    let historicalDevices: [DetectedDevice]
    @Environment(\.colorScheme) var colorScheme
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        List {
            
            // Log Utilities
            Section(header: Text("Log Utilities")) {
                Button {
                    exportCSVLog()
                } label: {
                    HStack {
                        Text("Export CSV Detection Log")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image("Share_iOS_Export")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    }
                }
                
                Button {
                    exportPDFLog()
                } label: {
                    HStack {
                        Text("Export PDF Security Audit")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image("File_Document")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Privacy disclosures
            Section(header: Text("Privacy Disclosures")) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image("Shield_Warning")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                        Text("Understanding Smart Wear Risks")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Text("Most smart glasses utilize a front-facing white LED indicator that turns solid or flashes when recording is active. However, these LEDs can be obstructed or modified.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    Text("The NearbyGlasses app continuously parses Bluetooth Low Energy advertisements. Ray-Ban Meta glasses emit periodic BLE pulses to negotiate data transfers, letting us detect them even if recording is not actively running.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    private func exportCSVLog() {
        if let url = PersistentLogger.shared.exportCSV() {
            shareURL = url
            showShareSheet = true
        } else {
            print("Failed to export CSV")
        }
    }
    
    private func exportPDFLog() {
        if let url = PDFExporter.shared.exportPDF(devices: historicalDevices) {
            shareURL = url
            showShareSheet = true
        } else {
            print("Failed to export PDF")
        }
    }
}

/// UIKit wrapper for UIActivityViewController presented as a SwiftUI sheet.
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct LicensesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("NearbyGlasses Software License Agreement")) {
                Text(LocalizedStringKey("""
Copyright (c) 2026 Henriques Pontes. All rights reserved.

IMPORTANT: PLEASE READ THIS SOFTWARE LICENSE AGREEMENT ("AGREEMENT") CAREFULLY BEFORE USING THE NEAR APP ("SOFTWARE"). BY USING THE SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS LICENSE.

1. General
The Software, documentation, and any fonts accompanying this License, whether on disk, in read only memory, on any other media or in any other form, are licensed, not sold, to you by Henriques Pontes ("Licensor") for use only under the terms of this License. Licensor retains ownership of the Software itself and reserves all rights not expressly granted to you.

2. Proprietary Nature
The Software is closed-source, proprietary, and confidential. The source code, structure, organization, and algorithms of the Software are the valuable trade secrets and confidential information of the Licensor. 

3. Permitted License Uses and Restrictions
A. Subject to the terms and conditions of this License, you are granted a limited, non-exclusive, non-transferable license to install and use one copy of the Software on a single Apple-branded device that you own or control.
B. You may not, and you agree not to or enable others to, copy, decompile, reverse engineer, disassemble, attempt to derive the source code of, decrypt, modify, or create derivative works of the Software or any services provided by the Software, or any part thereof.
C. You may not rent, lease, lend, sell, redistribute, or sublicense the Software.
D. Any attempt to do so is a violation of the rights of the Licensor. If you breach this restriction, you may be subject to prosecution and damages.

4. Consent to Use of Data
You agree that Licensor may collect and use technical data and related information, including but not limited to technical information about your device, system and application software, and peripherals, that is gathered periodically to facilitate the provision of software updates, product support, and other services to you (if any) related to the Software. Licensor may use this information, as long as it is in a form that does not personally identify you, to improve its products or to provide services or technologies to you.

5. Termination
This License is effective until terminated. Your rights under this License will terminate automatically without notice from the Licensor if you fail to comply with any term(s) of this License. Upon the termination of this License, you must cease all use of the Software and destroy all copies, full or partial, of the Software.

6. Disclaimer of Warranty
YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THE SOFTWARE IS AT YOUR SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY, AND EFFORT IS WITH YOU. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE SOFTWARE IS PROVIDED "AS IS" AND "AS AVAILABLE", WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND. LICENSOR HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS WITH RESPECT TO THE SOFTWARE, EITHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF MERCHANTABILITY, OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, OF QUIET ENJOYMENT, AND OF NON-INFRINGEMENT OF THIRD-PARTY RIGHTS.

7. Limitation of Liability
TO THE EXTENT NOT PROHIBITED BY LAW, IN NO EVENT SHALL LICENSOR BE LIABLE FOR PERSONAL INJURY OR ANY INCIDENTAL, SPECIAL, INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, LOSS OF DATA, BUSINESS INTERRUPTION, OR ANY OTHER COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OR INABILITY TO USE THE SOFTWARE, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT, OR OTHERWISE) AND EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

8. Governing Law
This License will be governed by and construed in accordance with the laws of the jurisdiction in which the Licensor resides, excluding its conflict of law principles. Any dispute arising out of or in connection with this License shall be subject to the exclusive jurisdiction of the courts located in that jurisdiction.
"""))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(5)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Licences")
        .navigationBarTitleDisplayMode(.inline)

    }
}


struct CooldownSettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    
    var body: some View {
        List {
            Section(header: Text("Notification Cooldown")) {
                Toggle("Enable Cooldown", isOn: $btManager.isNotificationCooldownEnabled)
                    .tint(.blue)
                
                if btManager.isNotificationCooldownEnabled {
                    HStack {
                        Text("Cooldown interval:")
                            .font(.system(size: 15))
                        Spacer()
                        Text("\(Int(btManager.notificationCooldown / 60000)) min")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: $btManager.notificationCooldown, in: 300000...3600000, step: 60000)
                        .accentColor(.blue)
                }
            }
            
            Section(footer: Text("Minimum delay between alert notifications and active device tracking resets. A shorter cooldown makes detection highly responsive, while a longer one prevents repeating alerts.")) {
                EmptyView()
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Notification Cooldown")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimeoutSettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    
    var body: some View {
        List {
            Section(header: Text("Auto-Stop Scan")) {
                HStack {
                    Text("Timeout interval:")
                        .font(.system(size: 15))
                    Spacer()
                    if btManager.scanTimeout == 0 {
                        Text("Never")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        Text("\(Int(btManager.scanTimeout / 60)) min")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                
                Slider(value: $btManager.scanTimeout, in: 0...3600, step: 60)
                    .accentColor(.blue)
            }
            
            Section(footer: Text("Automatically stops scanning after a certain duration to save battery life. Set to 'Never' (0 min) to scan continuously without stopping.")) {
                EmptyView()
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Scan Timeout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SensitivitySettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    
    private var sensitivityLabel: LocalizedStringKey {
        switch btManager.rssiThreshold {
        case -60...(-40):
            return "Near (Direct proximity, ~2m)"
        case -79...(-61):
            return "Medium (Same room, ~5m)"
        default:
            return "Far (Long range, ~15m)"
        }
    }
    
    var body: some View {
        List {
            Section(
                header: Text("Detection Sensitivity"),
                footer: Text("Higher sensitivity alerts you even for weak/distant signals, but increases potential false triggers.")
            ) {
                HStack {
                    Text("Current sensitivity:")
                        .font(.system(size: 15))
                    Spacer()
                    Text(sensitivityLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Slider(value: Binding(
                    get: { Double(btManager.rssiThreshold) },
                    set: { btManager.rssiThreshold = Int($0) }
                ), in: -95...(-55), step: 5)
                .accentColor(.blue)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.backgroundColor)
        .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Sensitivity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.light)
}

# CLAUDE.md — Near Project Guidelines

## Project Overview

**Near** is a privacy-awareness iOS app that detects nearby smart glasses and camera-equipped wearables via Bluetooth Low Energy (BLE) scanning. It alerts users when devices like Ray-Ban Meta, Apple Vision Pro, or Snapchat Spectacles are in proximity.

- **Bundle ID**: `com.luvlu.Near`
- **Display Name**: Nearbyglasses
- **Platform**: iOS (SwiftUI, Swift 6)
- **Min Deployment**: iOS 17+
- **Data Persistence**: SwiftData (`DetectedDevice` model)
- **License**: Proprietary (Henriques Pontes)

---

## Build & Run

```bash
# Build for simulator
xcodebuild -project Near.xcodeproj -scheme Near -sdk iphonesimulator \
  -destination 'id=3B7708B3-2303-452A-90F5-A6E0739D29D7' build

# Install & launch on simulator
xcrun simctl install 3B7708B3-2303-452A-90F5-A6E0739D29D7 \
  ~/Library/Developer/Xcode/DerivedData/Near-cpavpeffdsxtplbjxmumfqyzmvca/Build/Products/Debug-iphonesimulator/Nearbyglasses.app
xcrun simctl launch 3B7708B3-2303-452A-90F5-A6E0739D29D7 com.luvlu.Near

# Screenshot
xcrun simctl io 3B7708B3-2303-452A-90F5-A6E0739D29D7 screenshot output.png
```

---

## Architecture

```
Near/
├── NearApp.swift              # @main entry, ModelContainer, locale & appearance
├── Models/
│   └── Item.swift             # DetectedDevice (@Model, SwiftData)
├── Utilities/
│   ├── BluetoothManager.swift # Singleton BLE scanner, alert logic, settings, company ID lookup
│   ├── DeviceTypeHelpers.swift# iconForType(), colorForType(), displayNameForType(), DeviceIconView,
│   │                          # estimatedDistance(for:), colorForRssi()
│   └── LogExporter.swift      # CSV export from DetectedDevice array
├── DesignSystem/
│   └── DesignSystem.swift     # Color tokens (primaryBlue, cardBackground, etc.)
├── Views/
│   ├── Components/
│   │   ├── DevicePingNode.swift    # Radar ping animation node
│   │   ├── SignalHistoryChart.swift # RSSI signal chart
│   │   ├── ToggleRows.swift        # Reusable toggle row components
│   │   └── ZCenterContainer.swift  # Full-screen centered container
│   └── Screens/
│       ├── ContentView.swift       # Root view (wraps DashboardView)
│       ├── DashboardView.swift     # Main screen: detection list w/ metadata, status bar, radar toggle
│       │                           # Also contains AllResultsView (full detection history)
│       ├── DeviceDetailView.swift  # Device detail with signal chart, .insetGrouped list layout
│       ├── ScanRadarView.swift     # Live radar visualization
│       └── SettingsView.swift      # Settings + all sub-screens (Scan Preference, Device Filters,
│                                   #   Cooldown, Privacy, Licenses, About)
├── Localizable.xcstrings      # All localized strings (xcstrings format)
├── company_identifiers.json   # Bluetooth SIG company identifier lookup (3,981 entries)
└── Assets.xcassets/           # App icons, brand icons (snapchat_icon, notification_icon, Nearby icon set)
```

### Key Patterns

- **Singleton**: `BluetoothManager.shared` — the single source of truth for scanning state, detected devices, and all user preferences.
- **Settings Storage**: `@AppStorage` for simple values (`notificationCooldown`, `rssiThreshold`, `continueScanInBackground`, `appAppearance`, `selectedLanguage`). JSON-encoded `UserDefaults` strings for complex types (`enabledAlertTypes: Set<String>`, `ignoredDevices: [String: String]`).
- **SwiftData**: `DetectedDevice` model persisted via `ModelContainer`. Historical logs are written from `DashboardView.addHistoricalLog()` triggered by `NotificationCenter` posts from `BluetoothManager`.
- **Navigation**: Single `NavigationStack` rooted in `DashboardView`. All sub-screens are pushed via `NavigationLink`.
- **Company Identifier Database**: `company_identifiers.json` (pre-processed from `company_identifiers.yaml`) is loaded at startup. Maps 16-bit BLE company IDs (hex keys like `"0x004C"`) to company names (e.g., `"Apple, Inc."`). Used to resolve manufacturer names for unknown devices.

---

## Device Types

| Type Key | Display Name | Icon | Color | Company IDs |
|---|---|---|---|---|
| `rayban_meta` | Ray-Ban Meta | `eyeglasses` (SF Symbol) | `.red` | `0x058E`, `0x01AB`, `0x0D53` |
| `vision_pro` | Apple Vision Pro | `apple.logo` (SF Symbol) | `.purple` | `0x004C` (with name match) |
| `snap_spectacles` | Snapchat Spectacles | `snapchat_icon` (asset) | `.yellow` | `0x03C2` |
| `unknown` | Unknown Device | `questionmark.circle.fill` | `.gray` | — |

Custom icons use `DeviceIconView` which renders either an SF Symbol or a custom asset image based on the icon name.

---

## List Item Layout

Dashboard and AllResultsView list rows display a rich metadata layout:

```
┌─────────────────────────────────────────────────┐
│ [Icon]  Device Name                           > │
│         🕐 9:19 AM • 📶 -67 dBm • 📍 1.5m     │
└─────────────────────────────────────────────────┘
```

- **Icon**: 20×20 inside a 32×32 container with 10% opacity brand color background and 8pt corner radius
- **Time**: `device.timestamp.formatted(date: .omitted, time: .shortened)`
- **Signal**: RSSI in dBm, color-coded via `colorForRssi()` (Red ≥-60, Orange ≥-75, Yellow ≥-88, Blue <-88)
- **Proximity**: Estimated distance via `estimatedDistance(for:)` formatted as `"%.1fm"`

---

## Local Notifications

Notifications are native iOS `UNNotificationRequest` banners dispatched from `sendPrivacyAlert(for:)`:

- **Title**: Type-specific localized string (e.g., `"Ray-Ban Meta Nearby! ⚠️"`). For unknown types with a resolved manufacturer, uses `"[Manufacturer] Device Nearby! ⚠️"` (e.g., `"Apple, Inc. Device Nearby! ⚠️"`).
- **Subtitle**: Device display name (resolved or `"Unknown Device"`).
- **Body**: Distance + type-specific caution message (e.g., `"Detected approximately 1.5 meters away. Be aware: this device can capture high-res video and audio discrete recording."`).
- **Sound**: `.default`
- **No attachment/thumbnail**: Notification banners use only the app icon (no right-side image attachment).
- **Foreground display**: `UNUserNotificationCenterDelegate` returns `[.banner, .sound, .badge]` to show banners even when the app is in the foreground.

---

## Localization

- **Format**: Xcode `.xcstrings` (JSON-based, at `Near/Localizable.xcstrings`)
- **Supported Languages**: English (base), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Portuguese (`pt`), Chinese Simplified (`zh-Hans`)
- **Adding Keys**: Use a Python script to programmatically insert into the JSON structure. Pattern:
  ```python
  import json
  path = "Near/Localizable.xcstrings"
  with open(path, "r") as f: data = json.load(f)
  data["strings"]["New Key"] = {
      "extractionState": "manual",
      "localizations": {
          "de": {"stringUnit": {"state": "translated", "value": "German"}},
          # ... other languages
      }
  }
  with open(path, "w") as f: json.dump(data, f, ensure_ascii=False, indent=2)
  ```
- **Runtime Locale**: Set via `@AppStorage("selectedLanguage")` and applied with `.environment(\.locale, ...)` on the root view.

---

## Radar / Scanning Behavior

- **Radar Mode** = `continueScanInBackground` toggle (background BLE scanning)
- **Notification Cooldown** = `notificationCooldown` (default 10,000 ms = 10s)
  - Rate-limits duplicate notifications per device
  - Auto-expires devices from the active `detectedDevices` list after cooldown elapses with no new advertisements
- **Cleanup Timer**: 1-second periodic timer (`cleanupTimer`) filters expired devices from `detectedDevices`
- **Dashboard Indicators**:
  - Antenna icon: green (scanning, no devices) → red (devices detected) → gray (scanning off)
  - Status bar: green dot + "Privacy Awareness Active" → red dot + "Smart Wearable Detected! ⚠️"

---

## Shared Helpers (`DeviceTypeHelpers.swift`)

| Function | Purpose |
|---|---|
| `iconForType(_:)` | Returns SF Symbol name or asset name for a device type |
| `colorForType(_:)` | Returns brand `Color` for a device type |
| `displayNameForType(_:)` | Returns human-readable display name for a device type |
| `estimatedDistance(for:)` | Converts RSSI → estimated distance in meters (log-distance model) |
| `colorForRssi(_:)` | Returns color based on signal strength (Red/Orange/Yellow/Blue) |
| `DeviceIconView` | SwiftUI view rendering SF Symbol or custom asset icon |

---

## Conventions

- **Typography**: `.system(size:weight:design:)` with `.rounded` design throughout
- **Settings Rows**: `HStack(spacing: 16)` with 24×24 icon frame + text + trailing control
- **Toggle Style**: `.toggleStyle(SwitchToggleStyle(tint: .green))`
- **List Style**: `.listStyle(.insetGrouped)` on all settings/list screens
- **Navigation Titles**: `.navigationBarTitleDisplayMode(.inline)`
- **Share Sheets**: Use `ActivityViewController` (`UIViewControllerRepresentable`) presented via `.sheet()`, never direct `UIViewController` presentation from root
- **Color Scheme**: Respects `appAppearance` setting (system/light/dark) via `.preferredColorScheme()`
- **List Item Rows**: VStack with device name (semibold) + HStack metadata sub-row (time • signal • distance)

---

## Important Notes

- The term **"Canary"** from older code/companion apps maps to **"Radar"** in the iOS UI. Always use "Radar" in user-facing strings.
- `BluetoothManager` is `NSObject` subclass (required for `CBCentralManagerDelegate` conformance) and also `ObservableObject`.
- Background scanning uses specific service UUIDs (`180F`, `180A`, `FEAA`) since iOS requires them for background BLE scanning. Foreground scanning uses `nil` (all devices).
- Generic accessories (keyboards, mice, headphones, AirPods, etc.) are filtered out by name in `didDiscover`.
- `company_identifiers.json` is bundled in the app target and loaded at init via `loadCompanyIdentifiers()`. The source YAML (`company_identifiers.yaml`) lives at the project root for reference but is not included in the app bundle.
- `BluetoothDevice.manufacturer` and `.companyID` are optional fields populated during BLE scan from manufacturer data bytes. If a device has name `"Unknown Device"` but a resolved manufacturer, the name is dynamically set to `"[Manufacturer] Device"`.

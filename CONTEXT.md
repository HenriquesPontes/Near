# CONTEXT.md — Near: Privacy-Awareness Smart Glasses Detector

> **Last updated**: June 4, 2026

---

## 1. What is Near?

**Near** is a native iOS app that continuously scans for Bluetooth Low Energy (BLE) signals from smart glasses and camera-equipped wearables — such as **Ray-Ban Meta**, **Apple Vision Pro**, and **Snapchat Spectacles** — and alerts you when one is nearby. It exists because these devices can record video, audio, and spatial data discreetly, and people deserve to know when they are in range of one.

- **Bundle ID**: `com.luvlu.Near`
- **Display Name**: Nearbyglasses
- **Platform**: iOS 17+ (SwiftUI, Swift 6)
- **Data Persistence**: SwiftData
- **License**: Proprietary (Henriques Pontes)
- **Repository**: [github.com/HenriquesPontes/Near](https://github.com/HenriquesPontes/Near)

---

## 2. Core Detection Approach

Smart glasses can't hide from Bluetooth. Every BLE device broadcasts **advertising frames** containing a mandatory, immutable **Company Identifier** assigned by the Bluetooth SIG. Near uses this to identify manufacturers:

| Company ID | Manufacturer | Glasses |
|---|---|---|
| `0x058E` | Meta Platforms Technologies, LLC | Ray-Ban Meta |
| `0x01AB` | Meta Platforms, Inc. | Ray-Ban Meta |
| `0x0D53` | Luxottica Group S.p.A | Ray-Ban Meta |
| `0x004C` | Apple, Inc. | Apple Vision Pro (with name match) |
| `0x03C2` | Snapchat, Inc. | Snap Spectacles |

A bundled database of **3,981 company identifiers** (`company_identifiers.json`, pre-processed from `company_identifiers.yaml`) resolves any manufacturer by their hex company ID at runtime.

> **Important**: False positives are possible. Meta makes VR headsets, Apple makes many BLE devices. Near uses name-matching heuristics alongside company IDs to reduce false positives, but they are inherent to the approach.

---

## 3. App Flow

```
┌─────────────────────────────────────────────┐
│               DASHBOARD                      │
│                                              │
│  [Detection History List]                    │
│    → Device icon + name                      │
│    → 🕐 Time • 📶 RSSI • 📍 Distance        │
│    → Tap to open Device Detail               │
│                                              │
│  [Privacy Awareness Active ●]                │
│  ┌──────────────────────────────┐            │
│  │      Start Scanning          │  ← Opens ScanRadarView
│  └──────────────────────────────┘            │
│  ┌──────────────────────────────┐            │
│  │        Settings              │  ← Opens SettingsView
│  └──────────────────────────────┘            │
└─────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────────────┐
│  Scan Radar     │  │  Settings               │
│                 │  │                          │
│  Live radar     │  │  General                 │
│  with sonar     │  │    Notifications toggle  │
│  sweep +        │  │    Appearance picker     │
│  device pings   │  │    Language picker       │
│  on concentric  │  │    Privacy sub-screen    │
│  rings          │  │                          │
│                 │  │  Scanning                │
│  Tap device →   │  │    Scan Preference       │
│  Device Detail  │  │      Radar Mode toggle   │
│                 │  │      RSSI sensitivity     │
│  Start/Stop     │  │      Notification cooldown│
│  scanning       │  │    Device Filters         │
│                 │  │      Per-type toggles     │
│  Location       │  │      Ignored devices list │
│  permission     │  │                          │
│  prompts        │  │  About                   │
└─────────────────┘  │    About Near info       │
         │           │    Version / Build        │
         ▼           │    Licences               │
┌─────────────────┐  └─────────────────────────┘
│  Device Detail  │
│                 │
│  Hot/Cold       │
│  proximity      │
│  gauge          │
│                 │
│  RSSI signal    │
│  history chart  │
│                 │
│  Threat profile │
│  breakdown      │
│                 │
│  Ignore / Star  │
│  actions        │
└─────────────────┘
```

---

## 4. Project Structure

```
Near/
├── CLAUDE.md                   # Agent coding guidelines (build commands, conventions, patterns)
├── CONTEXT.md                  # This file — project context and architecture overview
├── README.md                   # User-facing documentation and disclaimers
├── LICENSE                     # Proprietary license
├── company_identifiers.yaml    # Source data (3,981 BLE company IDs from Bluetooth SIG)
├── scripts/
│   └── update_build_number.sh  # CI build number increment script
├── .github/workflows/
│   └── objective-c-xcode.yml   # CI workflow for Xcode builds
├── Localization/               # Legacy JSON translation files (de, en, es, fr, it, zh)
│
└── Near/                       # iOS App Target
    ├── NearApp.swift           # @main entry — ModelContainer, locale, appearance
    ├── Models/
    │   └── Item.swift          # DetectedDevice SwiftData @Model
    ├── Utilities/
    │   ├── BluetoothManager.swift    # Core BLE engine (593 lines)
    │   ├── DeviceTypeHelpers.swift   # Shared UI/logic helpers
    │   └── LogExporter.swift         # CSV export utility
    ├── DesignSystem/
    │   └── DesignSystem.swift        # Color tokens
    ├── Views/
    │   ├── Components/
    │   │   ├── DevicePingNode.swift       # Radar ping animation
    │   │   ├── SignalHistoryChart.swift   # RSSI line chart
    │   │   ├── ToggleRows.swift          # Reusable toggle rows
    │   │   └── ZCenterContainer.swift    # Full-screen centered container
    │   └── Screens/
    │       ├── ContentView.swift         # Root view wrapper
    │       ├── DashboardView.swift       # Main dashboard + AllResultsView
    │       ├── DeviceDetailView.swift    # Device detail + hot/cold tracker
    │       ├── ScanRadarView.swift       # Live radar scanner
    │       └── SettingsView.swift        # Settings + 7 sub-screens
    ├── Localizable.xcstrings   # All localized strings (xcstrings format)
    ├── company_identifiers.json # Bundled company ID lookup (runtime)
    └── Assets.xcassets/
        ├── AppIcon.appiconset/
        ├── Nearby icon/
        ├── snapchat_icon.imageset/
        └── notification_icon.imageset/
```

---

## 5. Data Models

### `BluetoothDevice` (In-Memory, Live Scanning)

```swift
struct BluetoothDevice: Identifiable, Hashable {
    var id: UUID
    var deviceId: String          // peripheral.identifier.uuidString
    var name: String              // "Ray-Ban Meta" / "Apple, Inc. Device" / "Unknown Device"
    var type: String              // "rayban_meta" / "vision_pro" / "snap_spectacles" / "unknown"
    var rssi: Int                 // Signal strength in dBm
    var lastSeen: Date            // Last advertisement received
    var isStarred: Bool
    var isSimulated: Bool
    var companyID: Int?           // Resolved BLE company ID (e.g. 0x058E)
    var manufacturer: String?     // Resolved company name (e.g. "Meta Platforms Technologies, LLC")
    var threatLevel: String       // Computed: "High" or "Medium"
    var estimatedDistance: Double  // Computed from RSSI using log-distance model
}
```

### `DetectedDevice` (Persisted, SwiftData)

```swift
@Model
final class DetectedDevice {
    @Attribute(.unique) var id: UUID
    var deviceId: String
    var name: String
    var type: String
    var timestamp: Date
    var rssi: Int
    var isStarred: Bool
    var threatLevel: String
    var isSimulated: Bool
    var companyID: Int?
    var manufacturer: String?
}
```

---

## 6. BluetoothManager — The Core Engine

`BluetoothManager` is the single most important class. It is an `NSObject` + `ObservableObject` singleton (`BluetoothManager.shared`) that owns:

### Responsibilities
1. **BLE Scanning** via `CBCentralManager` — foreground uses `nil` services (all devices); background uses specific UUIDs (`180F`, `180A`, `FEAA`)
2. **Device Classification** — Parses manufacturer data, matches company IDs and device names to type categories
3. **Notification Dispatch** — Sends `UNNotificationRequest` banners with localized, type-specific titles and device-aware caution messages
4. **Rate Limiting** — `notificationCooldown` (default 10s) prevents alert spam per device
5. **Active Device Cleanup** — 1-second timer (`cleanupTimer`) removes devices from the live list whose last advertisement exceeds the cooldown period
6. **Company ID Resolution** — Loads `company_identifiers.json` at init, resolves 16-bit hex IDs → manufacturer names
7. **SwiftData History** — Posts `NewDeviceDetectedHistory` notifications; `DashboardView` inserts/updates `DetectedDevice` records
8. **Settings Persistence** — `@AppStorage` for primitives, JSON-encoded `UserDefaults` for `Set<String>` and `[String: String]`
9. **Ignored Devices** — Whitelist by `deviceId`, filtered out during `didDiscover`
10. **Foreground Notifications** — `UNUserNotificationCenterDelegate` returns `[.banner, .sound, .badge]` so banners appear even when the app is in the foreground

### Key Properties
| Property | Type | Storage | Default |
|---|---|---|---|
| `detectedDevices` | `[BluetoothDevice]` | `@Published` | `[]` |
| `isScanning` | `Bool` | `@Published` | `false` |
| `alertOnNewDevices` | `Bool` | `@AppStorage` | `true` |
| `rssiThreshold` | `Int` | `@AppStorage` | `-75` |
| `continueScanInBackground` | `Bool` | `@AppStorage` | `true` |
| `appAppearance` | `String` | `@AppStorage` | `"system"` |
| `notificationCooldown` | `Double` | `@AppStorage` | `10000.0` (ms) |
| `enabledAlertTypes` | `Set<String>` | JSON UserDefaults | all 4 types |
| `ignoredDevices` | `[String: String]` | JSON UserDefaults | `[:]` |

---

## 7. Notification System

Notifications are **native iOS banners** (`UNNotificationRequest`), not custom UI. The flow:

```
BLE Advertisement received
  → didDiscover: classify device type
  → checkAndTriggerAlert: check RSSI threshold + cooldown
  → sendPrivacyAlert: build UNMutableNotificationContent
      Title:  "Ray-Ban Meta Nearby! ⚠️" (or manufacturer-resolved)
      Subtitle: device display name
      Body: "Detected approximately X.X meters away. Be aware: [type-specific warning]"
      Sound: .default
  → UNNotificationCenter.current().add(request)
  → saveToSwiftDataHistory: post NotificationCenter notification
      → DashboardView.addHistoricalLog: insert/update SwiftData record
```

---

## 8. Localization

- **Primary**: `Localizable.xcstrings` (Xcode JSON format) at `Near/Localizable.xcstrings`
- **Languages**: English (base), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Portuguese (`pt`), Chinese Simplified (`zh-Hans`)
- **Runtime Switch**: `@AppStorage("selectedLanguage")` → `.environment(\.locale, Locale(identifier:))` on root view
- **Adding Keys**: Python scripts that modify the xcstrings JSON (see `CLAUDE.md` for pattern)
- **Legacy**: `Localization/` directory contains standalone JSON files from an earlier localization system — not actively used by the app

---

## 9. Design System

The app follows **Apple Human Interface Guidelines** with a consistent design language:

| Token | Value |
|---|---|
| `backgroundColor` | `.systemGroupedBackground` |
| `primaryBlue` | `.blue` |
| `activeRed` | `.red` |
| `cardBackground` | `.secondarySystemGroupedBackground` |
| `itemBackground` | `.tertiarySystemGroupedBackground` |
| `borderStroke` | `.separator` |

### Typography
- `.system(size:weight:design:)` with `.rounded` design throughout
- List item names: 16pt semibold
- Metadata sub-rows: 11pt medium

### Patterns
- **Settings Rows**: `HStack(spacing: 16)` → 24×24 icon frame → text → trailing control
- **Toggle Style**: `.toggleStyle(SwitchToggleStyle(tint: .green))`
- **List Style**: `.listStyle(.insetGrouped)` everywhere
- **Navigation**: `.navigationBarTitleDisplayMode(.inline)`
- **Color Scheme**: `preferredColorScheme()` from `appAppearance` setting

---

## 10. Settings Architecture

Settings are organized into 3 sections with multiple sub-screens:

```
Settings (SettingsView)
├── General
│   ├── Notifications toggle (alertOnNewDevices)
│   ├── Appearance picker (system / light / dark)
│   ├── Language picker (6 languages)
│   └── Privacy → PrivacySettingsView
│       ├── Export CSV Detection Log
│       └── Privacy Disclosures (info text)
├── Scanning
│   ├── Scan Preference → ScanRangeSettingsView
│   │   ├── Radar Mode toggle (continueScanInBackground)
│   │   │   └── Background Refresh status warnings
│   │   ├── Detection Sensitivity slider (RSSI threshold)
│   │   └── Notification Cooldown → CooldownSettingsView
│   │       └── Cooldown slider (2s - 60s)
│   └── Device Filters → DeviceFiltersSettingsView
│       ├── Per-type toggles (4 device types)
│       └── Ignored devices whitelist (restore button)
└── About
    ├── About Near → PrivacyInfoView
    ├── Version / Build
    └── Licences → LicensesSettingsView
```

All sub-screens live inside `SettingsView.swift` (675 lines total).

---

## 11. Key Technical Details

### Background Scanning
iOS restricts background BLE scanning to specific service UUIDs. Near transitions between:
- **Foreground**: `scanForPeripherals(withServices: nil)` — discovers all devices
- **Background**: `scanForPeripherals(withServices: [180F, 180A, FEAA])` — limited but functional

### Device Filtering
Common accessories are filtered out by name keywords:
`keyboard`, `mouse`, `headphones`, `airpods`, `beats`, `watch`, `tv`, `speaker`, `tile`, `trackpad`

### RSSI Distance Model
```
TxPower = -59 dBm (calibration constant)
if ratio < 1.0: distance = ratio^10
else: distance = 0.89976 × ratio^7.7095 + 0.111
```

### Signal Color Coding
| RSSI Range | Color | Meaning |
|---|---|---|
| ≥ -60 dBm | Red | Extremely close |
| -60 to -75 dBm | Orange | Nearby |
| -75 to -88 dBm | Yellow | Mid-range |
| < -88 dBm | Blue | Distant |

---

## 12. Legal Disclaimers

> ⚠️ **HARASSING someone because you think they are wearing a covert surveillance device can be a criminal offence.** It may even be a more serious offence than using such a device. Please seek legal advice regarding your local laws.

- Near provides **no guarantee** detected devices are truly smart glasses
- False positives are inherent to BLE company ID matching
- The app collects **no personal data**, has **no telemetry**, and **no ads**
- Detection logs are stored locally only and never shared automatically
- Licensed under a proprietary license — see `LICENSE` for full terms

---

## 13. Build & CI

### Local Build
```bash
xcodebuild -project Near.xcodeproj -scheme Near -sdk iphonesimulator \
  -destination 'id=3B7708B3-2303-452A-90F5-A6E0739D29D7' build
```

### CI
- GitHub Actions workflow: `.github/workflows/objective-c-xcode.yml`
- Build number script: `scripts/update_build_number.sh`

### Requirements
- macOS with Xcode 15+
- iOS 17.0+ SDK
- SwiftData support
- No third-party dependencies (100% Apple frameworks)

---

## 14. Current ToDos & Improvements

| Priority | Area | Issue |
|---|---|---|

| 🟢 **Low** | **No widget/Live Activity** | Could add a Lock Screen widget or Live Activity for active scanning status. |
| 🟢 **Low** | **No unit tests** | Zero test targets in the project. |

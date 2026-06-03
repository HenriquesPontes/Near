# Near – Project Guidelines

> **Near** is a privacy-awareness iOS app that detects nearby smart glasses via Bluetooth Low Energy (BLE) and alerts the user with local notifications. It targets **iOS 17+** and is built with **SwiftUI**, **SwiftData**, and **CoreBluetooth**.

---

## Architecture Overview

```
Near/
├── NearApp.swift              ← App entry point (@main), sets up SwiftData ModelContainer
├── Assets.xcassets/           ← App icons, colors, image assets
├── Models/
│   └── Item.swift             ← SwiftData @Model: `DetectedDevice` (persisted alert history)
├── DesignSystem/
│   └── DesignSystem.swift     ← Static color tokens, gradients, card styles (dark theme)
├── Views/
│   ├── Screens/
│   │   ├── ContentView.swift      ← Root view wrapper → DashboardView (dark mode forced)
│   │   ├── DashboardView.swift    ← Main screen: alert history list, SCAN & Settings nav
│   │   ├── ScanRadarView.swift    ← Circular radar with sweeping sonar + device pings
│   │   ├── DeviceDetailView.swift ← Device profile: signal chart, threat breakdown, locator
│   │   └── SettingsView.swift     ← Sensitivity slider, channel toggles, about section
│   └── Components/
│       ├── DevicePingNode.swift   ← Animated radar dot for a detected device
│       ├── SignalHistoryChart.swift← RSSI line chart using SwiftUI Path drawing
│       ├── ToggleRows.swift       ← Reusable toggle row component for settings
│       └── ZCenterContainer.swift ← Utility ZStack centering wrapper
└── Utilities/
    └── BluetoothManager.swift ← Singleton BLE scanner (CBCentralManager) + local notifications
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5 |
| UI Framework | SwiftUI (dark mode only) |
| Persistence | SwiftData (`DetectedDevice` @Model) |
| Bluetooth | CoreBluetooth (`CBCentralManager`) |
| Notifications | UserNotifications (local push) |
| Min Deployment | iOS 17.0 |
| IDE | Xcode 15+ |
| Bundle ID | `com.luvlu.Near` |

---

## Key Concepts

### BLE Device Detection
- The app scans for **all** BLE peripherals (no service UUID filter).
- Devices are categorized by matching **Bluetooth SIG Company IDs** from manufacturer-specific advertising data and/or peripheral name patterns.
- Supported smart glasses channels:
  - `rayban_meta` → Company IDs `0x058E`, `0x01AB`, `0x0D53`
  - `vision_pro` → Company ID `0x004C` (Apple) + name heuristics
  - `snap_spectacles` → Company ID `0x03C2`
  - `unknown` → Unrecognized devices (non-generic accessories)
- Common accessories (keyboards, mice, headphones, AirPods, watches, speakers, etc.) are filtered out.

### BluetoothManager (Singleton)
- `BluetoothManager.shared` – the single source of truth for live scan state.
- Published properties: `detectedDevices`, `isScanning`, `alertOnNewDevices`, `rssiThreshold`, `enabledAlertTypes`.
- Alerts are rate-limited to **one per device every 2 minutes**.
- History persistence is broadcast via `NotificationCenter` (`NewDeviceDetectedHistory`) and saved into SwiftData by the receiving view.

### SwiftData Model
- `DetectedDevice` is the persisted entity stored in the on-disk SwiftData store.
- Fields: `id` (UUID, unique), `deviceId`, `name`, `type`, `timestamp`, `rssi`, `isStarred`, `threatLevel`, `isSimulated`.
- The `ModelContainer` is configured in `NearApp.swift` and injected via `.modelContainer()`.

---

## Design System

The app uses a **dark, premium aesthetic** with glassmorphism-inspired cards.

### Tokens (defined in `DesignSystem.swift`)

| Token | Value |
|---|---|
| `backgroundGradient` | Deep navy → near-black linear gradient |
| `primaryBlue` | `Color(red: 0.0, green: 0.5, blue: 1.0)` |
| `activeRed` | `Color.red.opacity(0.9)` |
| `cardBackground` | `Color(white: 0.1).opacity(0.8)` |
| `itemBackground` | `Color(white: 0.12).opacity(0.8)` |
| `borderStroke` | `Color.white.opacity(0.08)` |

### Style Rules
- **Always** use `DesignSystem.*` tokens for colors and backgrounds — do not hardcode colors in views.
- Cards use `.background(DesignSystem.cardBackground)` with `.overlay(RoundedRectangle(...).stroke(DesignSystem.borderStroke))`.
- All screens are wrapped in `DesignSystem.backgroundGradient.ignoresSafeArea()`.
- Color scheme is locked to `.dark` at the root `ContentView`.
- Use `SF Symbols` for all iconography.

---

## Coding Conventions

### Swift / SwiftUI
- **SwiftUI-first** – no UIKit unless absolutely necessary.
- Use `@ObservedObject` / `@EnvironmentObject` for `BluetoothManager.shared` references in views.
- Use `@Query` for SwiftData fetches, `@Environment(\.modelContext)` for writes.
- Mark view sections with `// MARK: -` comments for readability.
- Keep views composable: reusable pieces go in `Views/Components/`, full screens in `Views/Screens/`.
- Models go in `Models/`, services/managers in `Utilities/`.

### Naming
- Files are named after the primary type they contain (e.g., `DashboardView.swift` → `struct DashboardView`).
- Device type strings use `snake_case`: `"rayban_meta"`, `"vision_pro"`, `"snap_spectacles"`, `"unknown"`.
- Threat levels are capitalized strings: `"High"`, `"Medium"`, `"Low"`.

### No Mock / Simulation Data
- **Do not add mock data, simulation modes, or fake device generators.** All data must originate from real CoreBluetooth scanning or persisted SwiftData records.
- The app currently has no simulation toggle — keep it that way.

---

## Build & Run

```bash
# Clean build for simulator
xcodebuild -project Near.xcodeproj -scheme Near \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  clean build

# Or open in Xcode
open Near.xcodeproj
```

### Required Entitlements / Info.plist Keys
- `NSBluetoothAlwaysUsageDescription` – BLE scanning permission.
- `NSBluetoothPeripheralUsageDescription` – Legacy BLE permission string.
- Background modes: `bluetooth-central` (if background scanning is enabled).

---

## Testing Notes

- **BLE scanning requires a real device** — the iOS Simulator does not support CoreBluetooth discovery.
- Build verification on Simulator confirms compilation and UI layout but not scan functionality.
- For RSSI-based distance, the formula uses TxPower = −59 dBm at 1 meter reference.

---

## Reference Data

- [company_identifiers.yaml](company_identifiers.yaml) — Full Bluetooth SIG company ID registry used for device classification.
- Company IDs are **little-endian** in manufacturer advertising data (low byte first).

---

## Important Warnings

> **HARASSING someone because you think they are wearing a covert surveillance device can be a criminal offence.** This app produces false positives. Always exercise caution and never act aggressively based on app alerts alone.

- False positives are expected (VR headsets, other products from the same manufacturer).
- The app stores **no personal data** — only BLE manufacturer IDs and RSSI values.
- No telemetry, no ads, no analytics.

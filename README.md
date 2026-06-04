# Near

An iOS application designed to detect nearby smart glasses and provide privacy awareness through Bluetooth Low Energy (BLE) scanning.

> [!WARNING]
> **DO NOT HARASS ANYONE.**
> Any form of harassment or confrontation based on the suspicion of covert surveillance is unacceptable and may be illegal. *Near* relies on Bluetooth Low Energy (BLE) heuristics that can produce false positives—such as mistaking a VR headset or smartwatch for smart glasses. This app is designed solely for personal situational awareness. Always act responsibly and familiarize yourself with your local privacy laws.

---

## 🎯 Purpose
With the rise of smart glasses capable of covert audio and video recording, *Near* provides a technical tool to help you stay aware of your surroundings. It scans for Bluetooth signatures from known smart glasses manufacturers and alerts you when they cross into your proximity.

## 🛠 Features
- **Smart Glasses Detection**: Identifies devices like Meta Ray-Ban, Apple Vision Pro, Snapchat Spectacles, Google Glass, and more.
- **Radar Dashboard**: A sleek interface listing historical detections with threat levels, signal strength (RSSI), and estimated distance.
- **Radar Mode (Background Scanning)**: When enabled, the app actively scans in the background and sends a push notification if a known device gets too close.
- **Customizable Sensitivity**: Adjust the detection range (Near / Medium / Far) to avoid false alarms from distant devices.
- **Notification Cooldown**: Prevents notification spam by enforcing a customizable cooldown period for repeated detections of the same device.
- **Device Channels**: Granular control over which brands or types of smart glasses trigger an alert.
- **Multi-language Support**: Fully localized in English, Italian, and Portuguese.

## 📡 How It Works
*Near* uses Bluetooth LE `CBCentralManager` to scan for peripheral devices. Because MAC addresses randomize and services can be obfuscated, the app heuristics rely heavily on:
1. **Manufacturer Specific Data**: Identifying `Company ID` codes assigned by the Bluetooth SIG (e.g., `0x01AB` for Meta, `0x004C` for Apple, `0x03C2` for Snapchat).
2. **Device Naming Patterns**: Matching advertised peripheral names against known hardware strings.

> [!NOTE]
> **False Positives**: This approach means *Near* might alert you to a Meta Quest VR headset or an Apple Watch, as they share company IDs and Bluetooth characteristics with smart glasses. Use the alerts as a cue to be aware, not as definitive proof.

## 🚀 Usage

1. Open the app to the **Dashboard** to see recent detections.
2. Tap the **Radar** toggle in the top right to enable continuous background scanning (requires a first-time warning acceptance).
3. Tap **Start Scanning** to view the live radar UI and hot/cold proximity locator.
4. Open **Settings** to adjust your Notification Cooldown, Detection Sensitivity, and allowed Device Channels.

## 🏗 Build from Source

### Requirements
- **macOS** with **Xcode 16+** installed
- Target SDK: **iOS 18.0+**
- Swift 6 & SwiftUI

### Steps
```bash
# Clone the repository
git clone https://github.com/HenriquesPontes/Near.git
cd Near

# Clean and Build for Simulator
xcodebuild -project Near.xcodeproj -scheme Near -destination "platform=iOS Simulator,name=iPhone 17" clean build
```

## 📜 Privacy
*Near* does not track you. It does not collect telemetry, contains no ads, and does not phone home. All detected device logs are stored locally on your device using SwiftData and can be cleared at any time from the app settings.

## 🤝 Credits & Shoutouts
- Original concept inspired by community efforts to curb surveillance tech.
- iOS/SwiftUI implementation by Henriques Pontes.
- Thanks to the open-source community for Bluetooth assigned number registries.

## 📄 License
This app is provided under a proprietary license. See the `LICENSE` file for more details. Use at your own risk.

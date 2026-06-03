# Near
attempting to detect smart glasses nearby and warn you.

# ⚠ WARNING! ⚠ 
**HARASSING someone because you think they are wearing a covert surveillance device can be a criminal offence. It may even be a more serious offence than using such a device. Please seek legal advice regarding your local laws on this matter.**
---
## ⚠ DO NOT HARASS ANYONE AT ALL ⚠
---

# Near
The app, called *Near*, has one sole purpose: Look for smart glasses nearby and warn you.

# Table of contents
 * [Near](#Near)
   * [Why?](#why)
   * [How?](#how)
   * [Features](#features)
     * [What's RSSI?](#whats-rssi)
   * [Usage](#usage)
   * [ToDos](#todos)
   * [Tech-Solutionism?](#tech-solutionism)
   * [Build from Source](#build-from-source)
   * [Shoutouts](#shoutouts)
   * [License and Credits](#license-and-credits)

This app notifies you when smart glasses are nearby. It uses company identifiers in the Bluetooth data sent out by these. Therefore, there likely are false positives (e.g. from VR headsets). Hence, please proceed with caution when approaching a person nearby wearing glasses. They might just be regular glasses, despite this app’s warning.
        
The app’s author Henriques Pontes takes no liability whatsoever for this app nor it’s functionality. Use at your own risk. By technical design, detecting Bluetooth LE devices might sometimes just not work as expected. I am no graduated developer. This is all written in my free time and with knowledge I taught myself.<br/>
**False positives are likely.** This means, the app *Near* may notify you of smart glasses nearby when there might be in fact a VR headset of the same manufacturer or another product of that company’s breed. It may also miss smart glasses nearby. Again: I am no pro developer.<br/>
However, this app is provided under a proprietary [license](LICENSE).<br/>
The app *Near* does not store any details about you or collects any information about you or your phone. There are no telemetry, no ads, and no other nuisance.<br/>
If you choose to store (export) the logfile, that is completely up to you and your liability where this data go to. The logs are recorded only locally and not automatically shared with anyone. They do contain little sensitive data; in fact, only the manufacturer ID codes and RSSI strength of BLE devices encountered.<br/>
<br/>
**Use with extreme caution!** As stated before: There is no guarantee that detected smart glasses are really nearby. It might be another device looking technically (on the BLE adv level) similar to smart glasses.<br/>
Please do not act rashly. **Think before you act upon any messages** (not only from this app).<br/>

---

## Why?
- Because I consider smart glasses an intolerable intrusion, consent neglecting, horrible piece of tech that is already used for making various and tons of equally truly disgusting 'content'.
- Some smart glasses feature small LED signifying a recording is going on. But this is easily disabled, whilst manufacturers claim to prevent that and take no responsibility at all (tech tends to do that for decades now).
- Smart glasses have been used for instant facial recognition before and reportedly will be out of the box. This puts a lot of people in danger.
- Their data is used to train AI, which means, people will screen the recordings and see, likely, most intimate, insights.
- I hope this app is useful for someone.
  
## How?
- It's a simple rather heuristic approach. Because BLE uses randomized MAC addresses, the OSSID are not stable, nor the UUID of the service announcements, we can't just scan for the bluetooth beacons. And, to make things even more dire, some like Meta use proprietary Bluetooth services, so we rely on advertising company identifiers.
- The currently **most viable approach** comes from the [Bluetooth SIG assigned numbers repo](https://www.bluetooth.com/specifications/assigned-numbers/). Following this, the manufacturer company's name shows up as number codes in the packet advertising header (ADV) of BLE beacons.
  - this is what BLE advertising frames look like:
```
Frame 1: Advertising (ADV_IND)
Time:  0.591232 s
Address: C4:7C:8D:1E:2B:3F (Random Static)
RSSI: -58 dBm

Flags:
  02 01 06
    Flags: LE General Discoverable Mode, BR/EDR Not Supported

Manufacturer Specific Data:
  Length: 0x1A
  Type:   Manufacturer Specific Data (0xFF)
  Company ID: 0x058E (Meta Platforms Technologies, LLC)
  Data: 4D 45 54 41 5F 52 42 5F 47 4C 41 53 53

Service UUIDs:
  Complete List of 16-bit Service UUIDs
  0xFEAA
```
- According to the [Bluetooth SIG assigned numbers repo](https://www.bluetooth.com/specifications/assigned-numbers/), we use these company IDs:
  - `0x004C` for `Apple, Inc.` (for Apple Vision Pro spatial devices)
  - `0x01AB` for `Meta Platforms, Inc. (formerly Facebook)`
  - `0x058E` for `Meta Platforms Technologies, LLC`
  - `0x0D53` for `Luxottica Group S.p.A` (who manufactures the Meta Ray-Bans)
  - `0x03C2` for `Snapchat, Inc.` (that makes SNAP Spectacles)
    
  They are **immutable and mandatory**. Of course, Meta and other manufacturers also have other products that come with Bluetooth and therefore their ID, e.g. VR Headsets. Therefore, using these company ID codes for the app's scanning process is prone to false positives. But if you can't see someone wearing an Oculus Rift around you and there are no buildings where they could hide, chances are good that it's smart glasses instead.
- When the app recognizes a Bluetooth Low Energy (BLE) device with a sufficient signal strength, it will push an alert message and log it to your SwiftData history.

---

## Features
- **Smart Glasses Alerts**: The app *Near* pushes a local notification when smart glasses are detected in range.
- **Radar Scanner View**: A circular radar layout with sweeping sonar lines and pulsing ping indicators. Tapping a target opens details.
- **Hot-and-Cold Locator**: Interactive proximity gauge that shifts colors between cold blue and hot red to help you locate the smart glasses by signal strength beeps.
- **Signal Strength Chart**: Custom path line chart visualizing real-time RSSI signal trends.
- **Threat Level Profile**: Deep breakdown of device characteristics (Camera capture threat, audio arrays, speaker/HUD capabilities).
- **Custom Sensitivity Settings**: Slider threshold to filter alert zones (Near / Medium / Far) and toggles to mute specific device channels.

### What's RSSI?
RSSI is short for Received Signal Strength Indication. The value is an indication of the reception field strength of wireless communication.
In typical BLE (Bluetooth Low Energy) scenarios, RSSI rough distance (open space) is:
  - -60 dBm ~ 1 – 3 m
  - -70 dBm ~ 3 – 10 m
  - -80 dBm ~ 10 – 20 m
  - -90 dBm ~ 20 – 40 m
  - -100 dBm ~ 30 – 100+ m or near signal loss
Indoors, distances are often much shorter.
RSSI drops roughly according to:
    `RSSI ≈ -10 * n * log10(distance) + constant`

---

## Usage

1. Clone or download the Xcode project.
2. Build and run it on your iOS device or simulator.
3. Open the app to the main dashboard listing the detection history.
4. Tap the **SCAN** button to launch the live Radar screen.
5. Grant Bluetooth permissions (and location permission if requested by system BLE protocols).
6. Walk around! If any smart glasses cross your configured sensitivity range, an audio beep will trigger, a log will persist, and a local alert will push to your device.
7. Customize values inside the **Setting** screen (change detection sensitivity or mute channels).

---

## ToDos
- Add an option to set false positives to an ignore whitelist.
- Add **more manufacturer IDs** of smart glasses. Right now, oakley and snap are supported. If you have logs from other camera-integrated glasses, please send them in!

---

## Tech-Solutionism?
I know, this might be an odd place to do so, but just hear me out on this. I am aware this is a technical solution to a social problem, which is itself amplified by tech.
I do not want to promote techsolutionism nor do I want people to feel falsely secure. It's still an imperfect approach and probably always will be. We need better solutions to curb surveillance tech and privacy intrusions.

---

## Build from Source

You can build the app yourself from source code. This makes sure there are no other libraries included and you get what you want.

### Requirements
- **macOS** with **Xcode 15+** installed
- Target SDK: **iOS 17.0+**
- SwiftData support
- Git

### Building step-by-step
```bash
# Verify Xcode Command Line Tools are active
$ xcodebuild -version

# Clone the repository
$ git clone https://github.com/HenriquesPontes/Near.git
$ cd Near

# Clean and Build for Simulator
$ xcodebuild -project Near.xcodeproj -scheme Near -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" clean build
```

---

## Shoutouts
- [@vfrmedia@social.tchncs.de](https://social.tchncs.de/@vfrmedia) for warning help.
- [@mewsleah@meow.social](https://meow.social/@mewsleah) for canary ideas.
- [@pojntfx](https://github.com/pojntfx) for license discussions.
- [Sarah-Jane B.](https://www.linkedin.com/in/sarah-janeb/) for UX suggestions.
- Marcel L. for feedback and testing the iOS app.
- Henriques Pontes for SwiftUI port and layout refinement.

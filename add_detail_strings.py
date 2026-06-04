import json
import sys

strings_to_add = [
    "EXTREMELY CLOSE (HOT)",
    "The smart glasses are likely on a person right next to you.",
    "NEARBY (WARM)",
    "The device is in the immediate vicinity (same room or table).",
    "MID-RANGE (COOL)",
    "Signal is moderate. The device is within 5-10 meters.",
    "DISTANT (COLD)",
    "Weak signal detected. The device is far or shielded.",
    "Dual 12MP Ultra-wide cameras. Records 1080p video with white LED active capture indicator (often taped over by covert users).",
    "Stereoscopic 3D cameras. Captures spatial videos and environment depth data continuously for digital twinning.",
    "AR capture cameras. Auto-syncs shorts directly to Snapchat cloud networks.",
    "POV camera capable of recording 720p/1080p video and photos directly to local storage.",
    "Smart eyewear camera. Potential for discrete photo or video recording.",
    "Unknown camera system. May capture pictures or video streams anonymously.",
    "Custom 5-mic array for spatial audio capturing. Highly directional and sensitive.",
    "Dual-driver audio pods with spatial audio calibration. Multi-microphone recording.",
    "Dual microphones for voice recognition and voice clip logging.",
    "Built-in microphone for voice commands and audio recording.",
    "Microphone array for voice assistance and environmental audio capturing.",
    "Standard microphone system. Capable of surrounding room conversation recording.",
    "No display/HUD. Emits audio notifications and has open-ear speakers.",
    "Dual micro-OLED displays (4K resolution per eye). Includes external EyeSight screen showing digital eyes.",
    "Dual Waveguide displays with 2000 nits brightness showing augmented reality projections.",
    "Prism projector display creating a semi-transparent HUD in the wearer's peripheral vision.",
    "Likely features a micro-projector or waveguide HUD for augmented reality.",
    "No display HUD detected. Audio/Radio communication channel only.",
    "Audio Guidance Active",
    "Enable Audio Guidance",
    "Ignore Device (Add to Whitelist)",
    "Calibrating BLE waves..."
]

with open('Near/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

for s in strings_to_add:
    if s not in data['strings']:
        data['strings'][s] = {
            "extractionState": "manual",
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": s
                    }
                }
            }
        }

with open('Near/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    
print("Added missing strings to Localizable.xcstrings")

import Foundation

let lowerName = "smartvision"
let genericDevices = [
    "keyboard", "mouse", "headphones", "airpods", "beats", "watch", "tv", "speaker",
    "tile", "trackpad", "iphone", "ipad", "macbook", "mac mini", "mac studio", "imac", "mac pro",
    "pencil", "homepod", "appletv", "quest", "oculus", "tracker", "tag", "smarttag", "display",
    "audio", "nintendo", "playstation", "xbox", "car", "ford", "toyota", "honda", "bmw", "tesla"
]

if let match = genericDevices.first(where: { lowerName.contains($0) }) {
    print("Failed: contains \(match)")
}

let genericDevicesRegex = "\\b(" + genericDevices.joined(separator: "|") + ")\\b"
if lowerName.range(of: genericDevicesRegex, options: .regularExpression) != nil {
    print("Regex Failed")
} else {
    print("Regex Passed")
}

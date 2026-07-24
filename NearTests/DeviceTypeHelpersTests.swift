import XCTest
@testable import Near // The app target module is Near based on the build logs

final class DeviceTypeHelpersTests: XCTestCase {

    func testIconForType() throws {
        XCTAssertEqual(iconForType("rayban_meta"), "Meta")
        XCTAssertEqual(iconForType("vision_pro"), "Apple")
        XCTAssertEqual(iconForType("snap_spectacles"), "snapchat_icon")
        XCTAssertEqual(iconForType("google_glass"), "Google")
        XCTAssertEqual(iconForType("samsung_glasses"), "Samsung")
        XCTAssertEqual(iconForType("unknown"), "questionmark.circle.fill")
    }

    func testDisplayNameForType() throws {
        XCTAssertEqual(displayNameForType("rayban_meta"), String(localized: "Ray-Ban Meta glasses"))
        XCTAssertEqual(displayNameForType("vision_pro"), String(localized: "Apple Devices"))
        XCTAssertEqual(displayNameForType("snap_spectacles"), String(localized: "Snapchat Spectacles"))
    }

    func testEstimatedDistance() throws {
        // Test RSSI = 0
        XCTAssertEqual(estimatedDistance(for: 0), -1.0)
        
        // Test near distance
        let nearDist = estimatedDistance(for: -59)
        XCTAssertEqual(nearDist, 1.01076, accuracy: 0.001) // ratio = 1.0 -> 0.89976 + 0.111 = 1.01076
        
        // Test far distance
        let farDist = estimatedDistance(for: -90)
        XCTAssertGreaterThan(farDist, 10.0)
    }

    func testColorForRssi() throws {
        XCTAssertEqual(colorForRssi(-50), .red)
        XCTAssertEqual(colorForRssi(-65), .orange)
        XCTAssertEqual(colorForRssi(-80), .yellow)
        XCTAssertEqual(colorForRssi(-90), .blue)
    }
}

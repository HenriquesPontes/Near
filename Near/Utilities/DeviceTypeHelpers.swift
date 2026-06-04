//
//  DeviceTypeHelpers.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

// MARK: - Shared Device Type Utilities
// Extracted from DashboardView, ScanRadarView, and DeviceDetailView
// to eliminate code duplication.

/// Returns the appropriate SF Symbol name for a device type string.
func iconForType(_ type: String) -> String {
    switch type {
    case "rayban_meta", "oakley_meta", "project_aria", "meta_orion", "other_meta_glasses": return "Meta"
    case "vision_pro": return "Apple"
    case "snap_spectacles": return "snapchat_icon"
    case "google_glass", "google_gentle_monster", "google_warby_parker", "google_xreal": return "Google"
    case "samsung_glasses": return "Samsung"
    default: return "questionmark.circle.fill"
    }
}

/// Returns the brand color associated with a device type string.
func colorForType(_ type: String) -> Color {
    switch type {
    case "rayban_meta", "oakley_meta", "project_aria", "meta_orion", "other_meta_glasses": return .red
    case "vision_pro": return .purple
    case "snap_spectacles": return .yellow
    case "google_glass", "google_gentle_monster", "google_warby_parker", "google_xreal": return .green
    case "samsung_glasses": return .blue
    default: return .gray
    }
}

/// Returns a human-readable display name for a device type string.
func displayNameForType(_ type: String) -> String {
    switch type {
    case "rayban_meta": return "Ray-Ban Meta"
    case "oakley_meta": return "Oakley Meta"
    case "project_aria": return "Project Aria"
    case "meta_orion": return "Meta Orion"
    case "other_meta_glasses": return "Meta Smart Glasses"
    case "vision_pro": return "Apple Vision Pro"
    case "snap_spectacles": return "Snapchat Spectacles"
    case "google_glass": return "Google Glass"
    case "google_gentle_monster": return "Google x Gentle Monster"
    case "google_warby_parker": return "Google x Warby Parker"
    case "google_xreal": return "Google XREAL/Aura"
    case "samsung_glasses": return "Samsung Smart Glasses"
    default: return "Unknown Device"
    }
}

/// A view that renders either an SF Symbol or a custom asset image based on the icon name.
struct DeviceIconView: View {
    let icon: String
    let color: Color
    
    private let customIcons = ["snapchat_icon", "Apple", "Meta", "Samsung", "Google"]
    
    var body: some View {
        if customIcons.contains(icon) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(color)
        }
    }
}

// MARK: - Signal Strength & Proximity Utilities

/// Estimates the distance in meters based on the RSSI value.
func estimatedDistance(for rssi: Int) -> Double {
    let txPower = -59.0
    if rssi == 0 { return -1.0 }
    let ratio = Double(rssi) * 1.0 / txPower
    if ratio < 1.0 {
        return pow(ratio, 10.0)
    } else {
        return (0.89976) * pow(ratio, 7.7095) + 0.111
    }
}

/// Returns the color associated with a given RSSI signal strength.
func colorForRssi(_ rssi: Int) -> Color {
    if rssi >= -60 {
        return .red
    } else if rssi >= -75 {
        return .orange
    } else if rssi >= -88 {
        return .yellow
    } else {
        return .blue
    }
}


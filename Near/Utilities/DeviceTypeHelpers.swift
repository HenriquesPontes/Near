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
    case "rayban_meta": return "eyeglasses"
    case "vision_pro": return "apple.logo"
    case "snap_spectacles": return "snapchat_icon"
    default: return "questionmark.circle.fill"
    }
}

/// Returns the brand color associated with a device type string.
func colorForType(_ type: String) -> Color {
    switch type {
    case "rayban_meta": return .red
    case "vision_pro": return .purple
    case "snap_spectacles": return .yellow
    default: return .gray
    }
}

/// Returns a human-readable display name for a device type string.
func displayNameForType(_ type: String) -> String {
    switch type {
    case "rayban_meta": return "Ray-Ban Meta"
    case "vision_pro": return "Apple Vision Pro"
    case "snap_spectacles": return "Snapchat Spectacles"
    default: return "Unknown Device"
    }
}

/// A view that renders either an SF Symbol or a custom asset image based on the icon name.
struct DeviceIconView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        if icon == "snapchat_icon" {
            Image("snapchat_icon")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(color)
        } else {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(color)
        }
    }
}

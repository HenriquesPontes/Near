//
//  DesignSystem.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct DesignSystem {
    // Elegant background gradient used in screens
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.01, green: 0.02, blue: 0.05)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Core color tokens
    static let primaryBlue = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let activeRed = Color.red.opacity(0.9)
    
    // Card styles
    static let cardBackground = Color(white: 0.1).opacity(0.8)
    static let itemBackground = Color(white: 0.12).opacity(0.8)
    static let borderStroke = Color.white.opacity(0.08)
}

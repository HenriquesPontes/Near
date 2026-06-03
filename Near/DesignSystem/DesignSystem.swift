//
//  DesignSystem.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct DesignSystem {
    // Dynamic background color used in screens, adapting to light/dark modes
    static var backgroundColor: Color {
        Color(.systemGroupedBackground)
    }
    
    // Core color tokens
    static let primaryBlue = Color.blue
    static let activeRed = Color.red
    
    // Card styles (dynamic)
    static var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    static var itemBackground: Color {
        Color(.tertiarySystemGroupedBackground)
    }
    
    static var borderStroke: Color {
        Color(.separator)
    }
}

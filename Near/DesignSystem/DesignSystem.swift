//
//  DesignSystem.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

struct DesignSystem {
    // Dynamic background color used in screens, adapting to light/dark modes
    static var backgroundColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "141415")
                : UIColor(hex: "EDEEF0")
        })
    }
    
    // Core color tokens
    static let primaryBlue = Color.blue
    static let activeRed = Color.red
    
    // Card styles (dynamic)
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "1C1D1F")
                : UIColor(hex: "E1E3E6")
        })
    }
    
    static var itemBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "27292A")
                : UIColor(hex: "B1B5B7")
        })
    }
    
    static var borderStroke: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "5D5F64")
                : UIColor(hex: "B1B5B7")
        })
    }
}

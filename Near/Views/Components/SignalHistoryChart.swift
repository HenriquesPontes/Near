//
//  SignalHistoryChart.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct SignalHistoryChart: Shape {
    let history: [Int]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard history.count > 1 else { return path }
        
        let width = rect.width
        let height = rect.height
        
        // RSSI ranges normally from -95 to -45. Normalize values
        let minRssi: CGFloat = -95.0
        let maxRssi: CGFloat = -45.0
        let range = maxRssi - minRssi
        
        let stepX = width / CGFloat(history.count - 1)
        
        for i in 0..<history.count {
            let val = CGFloat(history[i])
            let normalizedVal = max(min((val - minRssi) / range, 1.0), 0.0)
            
            // Invert Y because (0,0) is top-left in coordinates
            let y = height - (normalizedVal * height)
            let x = CGFloat(i) * stepX
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

#Preview {
    SignalHistoryChart(history: [-80, -75, -70, -68, -72, -85, -90, -78, -70, -65])
        .stroke(Color.blue, lineWidth: 2)
        .frame(height: 120)
        .padding()
        .background(Color.black)
}

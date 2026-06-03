//
//  ContentView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DashboardView()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}

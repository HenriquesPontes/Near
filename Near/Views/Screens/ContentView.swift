//
//  ContentView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        DashboardView()
            .sheet(isPresented: Binding(
                get: { !hasSeenOnboarding },
                set: { _ in } // Controlled purely by AppStorage
            )) {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}

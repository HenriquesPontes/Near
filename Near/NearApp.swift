//
//  NearApp.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

@main
struct NearApp: App {
    @AppStorage("selectedLanguage") var selectedLanguage: String = Bundle.main.preferredLocalizations.first ?? "en"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DetectedDevice.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: selectedLanguage))
        }
        .modelContainer(sharedModelContainer)
    }
}

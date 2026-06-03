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
    @AppStorage("appAppearance") var appAppearance: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

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
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}

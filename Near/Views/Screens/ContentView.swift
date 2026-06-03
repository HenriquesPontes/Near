//
//  ContentView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @State private var autoDismissTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            DashboardView()
            
            if let activeDevice = btManager.activeNotification {
                VStack {
                    InAppNotificationToast(device: activeDevice) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            btManager.activeNotification = nil
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .zIndex(999)
                .onAppear {
                    // Cancel previous task if active
                    autoDismissTask?.cancel()
                    
                    // Auto-dismiss after 4 seconds using Task to respect swift concurrency
                    autoDismissTask = Task {
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            btManager.activeNotification = nil
                        }
                    }
                }
                .onDisappear {
                    autoDismissTask?.cancel()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}

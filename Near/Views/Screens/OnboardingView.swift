//
//  OnboardingView.swift
//  Near
//
//  Created by Admin on 6/4/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header Icon
            ZStack {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "eyeglasses")
                    .font(.system(size: 40))
                    .foregroundColor(Color(UIColor.systemBackground))
            }
            .padding(.bottom, 30)
            
            // Title
            Text("Welcome to NearbyGlasses")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Your personal awareness tool for smart glasses and camera-equipped wearables.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            
            // Features list
            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "antenna.radiowaves.left.and.right",
                    color: .blue,
                    title: "Signal Detection",
                    description: "Detects Bluetooth emissions from popular smart glasses like Ray-Ban Meta and other smart glasses."
                )
                
                FeatureRow(
                    icon: "bell.badge.fill",
                    color: .red,
                    title: "Alerts & Notifications",
                    description: "Get notified when potential surveillance devices are nearby."
                )
                
                FeatureRow(
                    icon: "lock.shield.fill",
                    color: .green,
                    title: "Privacy First",
                    description: "NearbyGlasses doesn't collect your data. Everything happens entirely on your device."
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Disclaimer
            Text("NearbyGlasses uses Bluetooth to estimate proximity. It requires permission to scan for devices. False positives are possible.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            // Action Button
            Button {
                withAnimation {
                    hasSeenOnboarding = true
                }
            } label: {
                Text("Grant Permission")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

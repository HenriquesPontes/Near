//
//  InAppNotificationToast.swift
//  Near
//
//  Created by Admin on 6/4/26.
//

import SwiftUI

struct InAppNotificationToast: View {
    let device: BluetoothDevice
    let onClose: () -> Void
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    private var deviceDescription: LocalizedStringKey {
        switch device.type {
        case "rayban_meta":
            return "Ray-Ban Meta detected nearby"
        case "vision_pro":
            return "Apple Vision Pro detected nearby"
        case "snap_spectacles":
            return "Snapchat Spectacles detected nearby"
        default:
            return "Unknown wearable detected nearby"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left App Icon in Purple/Violet Border
            ZStack {
                Color.white
                Image("notification_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 40, height: 40)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(red: 0.5, green: 0.2, blue: 0.9), lineWidth: 2) // Bright purple border
            )
            
            // Text Content (Title & Description)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(deviceDescription)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time Stamp
            Text(timeString)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .onTapGesture {
            onClose()
        }
    }
}

#Preview {
    InAppNotificationToast(
        device: BluetoothDevice(
            deviceId: "123",
            name: "Ray-Ban Meta",
            type: "rayban_meta",
            rssi: -50
        ),
        onClose: {}
    )
    .background(Color.gray)
}

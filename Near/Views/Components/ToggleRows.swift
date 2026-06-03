//
//  ToggleRows.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct ToggleRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.8))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
        }
        .padding(16)
    }
}

struct FilterToggleRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
    var systemIcon: String? = nil
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                } else {
                    Image(systemName: icon)
                }
            }
            .font(.system(size: 18))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.8))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
        }
        .padding(16)
    }
}

#Preview {
    VStack {
        ToggleRow(title: "Alert notifications", subtitle: "Turn alert notifications on/off", icon: "bell", color: .blue, isOn: .constant(true))
        FilterToggleRow(title: "Rayban Meta", description: "Discreet photo/video capturing", icon: "eye", color: .red, isOn: .constant(true))
    }
    .padding()
    .background(Color.black)
}

//
//  ZCenterContainer.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct ZCenterContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            DesignSystem.backgroundColor
                .ignoresSafeArea()
            
            content
        }
    }
}

#Preview {
    ZCenterContainer {
        Text("ZCenterContainer Preview")
            .foregroundColor(.white)
    }
}

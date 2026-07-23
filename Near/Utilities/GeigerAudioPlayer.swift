//
//  GeigerAudioPlayer.swift
//  Near
//

import AudioToolbox
import Foundation

class GeigerAudioPlayer {
    static let shared = GeigerAudioPlayer()
    
    // Low-latency system sound click (1104 = keyboard / radar click sound)
    private let geigerSoundID: SystemSoundID = 1104
    
    private init() {}
    
    func playClick() {
        #if os(iOS)
        AudioServicesPlaySystemSound(geigerSoundID)
        #endif
    }
}

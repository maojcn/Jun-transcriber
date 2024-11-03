//
//  AudioDropDelegate.swift
//  Jun
//
//  Created by Jiacheng Mao on 2024/11/3.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

private let supportedAudioTypes: [UTType] = [
    .mp3,          // .mp3
    .wav,          // .wav
    .mpeg4Audio,   // .m4a, .aac
    .aiff,         // .aif, .aiff
    .midi,         // .mid
    .audiovisualContent, // .caf
]

struct AudioDropDelegate: DropDelegate {
    let audioFileBinding: Binding<URL?>
    let isTargeted: Binding<Bool>
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: supportedAudioTypes)
    }
    
    func dropEntered(info: DropInfo) {
        isTargeted.wrappedValue = true
    }
    
    func dropExited(info: DropInfo) {
        isTargeted.wrappedValue = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        isTargeted.wrappedValue = false
        
        guard let itemProvider = info.itemProviders(for: supportedAudioTypes).first else {
            return false
        }
        
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.audiovisualContent.identifier) { url, error in
            guard let url = url else { return }
            
            // Create a permanent copy in the app's documents directory
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                DispatchQueue.main.async {
                    self.audioFileBinding.wrappedValue = destinationURL
                }
            } catch {
                print("Error handling dropped file: \(error)")
            }
        }
        return true
    }
}

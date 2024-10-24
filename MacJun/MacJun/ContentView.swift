//
//  ContentView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var whisperState = WhisperState()
    
    var body: some View {
        WhisperModelListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WhisperModel.self, inMemory: true)
}

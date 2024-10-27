//
//  ContentView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var whisperState = WhisperState(modelName: "tiny.en")
    @State private var selectedModelName: String = "tiny.en"
    @StateObject private var downloader = WhisperModelDownloader()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WhisperModelListView()
                .tabItem {
                    Label("Models", systemImage: "square.stack.3d.up")
                }
                .tag(0)
            
            TranscribeDeomoView(whisperState: whisperState, selectedModelName: $selectedModelName, downloader: downloader)
                .tabItem {
                    Label("Transcribe", systemImage: "waveform")
                }
                .tag(1)
        }
        .onChange(of: selectedModelName) { old, newModelName in
            whisperState.loadModel(modelName: newModelName)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

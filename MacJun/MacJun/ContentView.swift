//
//  ContentView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI

struct ContentView: View {
    enum Tab {
        case transcription
        case models
    }
    
    @State private var selectedTab: Tab = .transcription
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                NavigationLink(value: Tab.transcription) {
                    Label("Transcription", systemImage: "waveform")
                }
                NavigationLink(value: Tab.models) {
                    Label("Models", systemImage: "square.stack.3d.up")
                }
            }
            .navigationTitle("MacJun")
        } detail: {
            // Main content area
            switch selectedTab {
            case .transcription:
                TranscriptionView()
            case .models:
                WhisperModelListView()
            }
        }
        .navigationSplitViewStyle(.automatic)
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WhisperModel.self, inMemory: true)
}

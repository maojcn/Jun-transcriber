//
//  ContentView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI

struct ContentView: View {
    enum Tab {
        case models
        case transcription
    }
    
    @State private var selectedTab: Tab = .transcription
    @State private var sidebarWidth: CGFloat = 200
    
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
            .listStyle(.sidebar)
        } detail: {
            // Main Content Area
            Group {
                switch selectedTab {
                case .transcription:
                    TranscriptionView()
                        .navigationTitle("Transcription")
                case .models:
                    WhisperModelListView()
                        .navigationTitle("Whisper Models")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WhisperModel.self, inMemory: true)
}

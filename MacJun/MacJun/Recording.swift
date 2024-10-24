//
//  Recording.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import Foundation
import SwiftData
import SwiftUICore

@Model
class Recording {
    var title: String
    var date: Date
    var duration: TimeInterval
    var audioFileURL: URL?
    var transcriptionResultURL: URL?
    var processingStatus: ProcessingStatus
    
    // Added computed properties for better UI presentation
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0:00"
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
    
    init(title: String, date: Date = Date(), duration: TimeInterval, audioFileURL: URL? = nil) {
        self.title = title
        self.date = date
        self.duration = duration
        self.audioFileURL = audioFileURL
        self.processingStatus = .notStarted
    }
    
    enum ProcessingStatus: Codable, Equatable {
        case notStarted
        case processing
        case completed
        case failed(String)
        
        var displayText: String {
            switch self {
            case .notStarted: return "Not Started"
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .failed(let error): return "Failed: \(error)"
            }
        }
        
        var icon: String {
            switch self {
            case .notStarted: return "circle"
            case .processing: return "arrow.triangle.2.circlepath"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .notStarted: return .gray
            case .processing: return .blue
            case .completed: return .green
            case .failed: return .red
            }
        }
    }
}

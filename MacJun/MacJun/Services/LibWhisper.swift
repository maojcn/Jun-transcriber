//
//  LibWhisper.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import Foundation
import whisper

enum WhisperError: Error {
    case couldNotInitializeContext
}

// Meet Whisper C++ constraint: Don't access from more than one thread at a time.
actor WhisperContext {
    private var context: OpaquePointer

    init(context: OpaquePointer) {
        self.context = context
    }

    deinit {
        whisper_free(context)
    }

    func fullTranscribe(samples: [Float], customParams: WhisperParams? = nil) {
        // Leave 2 processors free (i.e. the high-efficiency cores).
        let maxThreads = max(1, min(8, cpuCount() - 2))
        print("Selecting \(maxThreads) threads")
        
        var params = customParams?.toWhisperFullParams() ?? whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        
        // Set default values if not provided in customParams
        if customParams == nil {
            "auto".withCString { en in
                params.print_realtime   = true
                params.print_progress   = false
                params.print_timestamps = true
                params.print_special    = false
                params.translate        = false
                params.language         = en
                params.n_threads        = Int32(maxThreads)
                params.offset_ms        = 0
                params.no_context       = true
                params.single_segment   = false
            }
        }

        whisper_reset_timings(context)
        print("About to run whisper_full")
        samples.withUnsafeBufferPointer { samples in
            if (whisper_full(context, params, samples.baseAddress, Int32(samples.count)) != 0) {
                print("Failed to run the model")
            } else {
                whisper_print_timings(context)
            }
        }
    }

    func getTranscription() -> String {
        var transcription = ""
        for i in 0..<whisper_full_n_segments(context) {
            transcription += String.init(cString: whisper_full_get_segment_text(context, i))
        }
        return transcription
    }

    static func createContext(path: String) throws -> WhisperContext {
        var params = whisper_context_default_params()
#if targetEnvironment(simulator)
        params.use_gpu = false
        print("Running on the simulator, using CPU")
#endif
        let context = whisper_init_from_file_with_params(path, params)
        if let context {
            return WhisperContext(context: context)
        } else {
            print("Couldn't load model at \(path)")
            throw WhisperError.couldNotInitializeContext
        }
    }
}

fileprivate func cpuCount() -> Int {
    ProcessInfo.processInfo.processorCount
}

struct WhisperParams {
    var printRealtime: Bool?
    var printProgress: Bool?
    var printTimestamps: Bool?
    var printSpecial: Bool?
    var translate: Bool?
    var language: String?
    var nThreads: Int32?
    var offsetMs: Int32?
    var noContext: Bool?
    var singleSegment: Bool?
    
    func toWhisperFullParams() -> whisper_full_params {
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        
        if let printRealtime = printRealtime { params.print_realtime = printRealtime }
        if let printProgress = printProgress { params.print_progress = printProgress }
        if let printTimestamps = printTimestamps { params.print_timestamps = printTimestamps }
        if let printSpecial = printSpecial { params.print_special = printSpecial }
        if let translate = translate { params.translate = translate }
        if let language = language {
            language.withCString { cString in
                params.language = cString
            }
        }
        if let nThreads = nThreads { params.n_threads = nThreads }
        if let offsetMs = offsetMs { params.offset_ms = offsetMs }
        if let noContext = noContext { params.no_context = noContext }
        if let singleSegment = singleSegment { params.single_segment = singleSegment }
        
        return params
    }
}

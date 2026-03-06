//
//  AIConfig.swift
//  VirtualUAVHanger
//
//  Central place to read AI configuration (Gemini API key) from the environment.
//

import Foundation

enum AIConfig {
    /// Gemini API endpoint and model.
    static let geminiEndpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent")!

    /// Reads the Gemini API key from the process environment.
    ///
    /// Set `GEMINI_API_KEY` in your Xcode scheme's Environment Variables.
    static var geminiAPIKey: String {
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            return key
        }
        #if DEBUG
        fatalError("GEMINI_API_KEY not set in environment. Add it in the Xcode scheme (Run -> Arguments -> Environment Variables).")
        #else
        return ""
        #endif
    }
}


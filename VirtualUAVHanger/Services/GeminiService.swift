//
//  GeminiService.swift
//  VirtualUAVHanger
//
//  Thin client for Gemini chat, used by the onboard AI assistant.
//

import Foundation

struct AIMessage: Codable, Sendable {
    enum Role: String, Codable {
        case user
        case model
        case system
    }

    var role: Role
    var text: String
}

/// DTO used when we ask Gemini to structure a drone part.
struct AIGeneratedPart: Codable {
    var name: String?
    var category: String?
    var brand: String?
    var serialNumber: String?
    var manualURL: String?
    var imageURL: String?
}

/// DTO used when we ask Gemini to structure a drone.
struct AIGeneratedDrone: Codable {
    var name: String?
    var imageURL: String?
}

/// Minimal subset of Gemini API response we care about.
private struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

/// Service that calls Gemini's `generateContent` endpoint.
actor GeminiService {
    static let shared = GeminiService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// General chat: returns the model's plain text reply.
    func chat(messages: [AIMessage], productURL: URL? = nil, context: String? = nil) async throws -> String {
        if CommandLine.arguments.contains("--ai-mock") {
            return "Mock AI: Got it! I can help you manage your drone fleet."
        }
        var contents: [[String: Any]] = []

        // Convert our messages into Gemini "contents".
        for message in messages {
            let role: String
            switch message.role {
            case .user: role = "user"
            case .model: role = "model"
            case .system: role = "user" // system messages go into systemInstruction separately
            }
            contents.append([
                "role": role,
                "parts": [["text": message.text]]
            ])
        }

        var body: [String: Any] = [:]
        body["contents"] = contents
        let genConfig = [
            "temperature": NSNumber(value: 0.3),
            "maxOutputTokens": NSNumber(value: 2048)
        ]
        body["generationConfig"] = genConfig as [String: NSNumber]

        if let context, !context.isEmpty {
            let sys = """
            You are the onboard assistant for the Virtual UAV Hangar (vHangar) app.
            Use the provided inventory snapshot as ground truth. If something is missing from the snapshot, say you don't know.
            You may help the user add/edit drones and components, but do NOT invent IDs.

            \(context)
            """
            body["systemInstruction"] = [
                "role": "user",
                "parts": [["text": sys]]
            ]
        }

        if let url = productURL {
            // Give Gemini the product URL as part of the prompt so it can fetch details.
            let extra: [String: Any] = [
                "role": "user",
                "parts": [["text": "Product URL to use for context: \(url.absoluteString)"]]
            ]
            if var existing = body["contents"] as? [[String: Any]] {
                existing.append(extra)
                body["contents"] = existing
            }
        }

        return try await sendRequest(body: body)
    }

    /// Ask Gemini to output ONLY JSON describing a set of inventory edit actions.
    func planEdits(request: String, productURL: URL? = nil, context: String) async throws -> String {
        let systemInstruction = """
        You are an assistant inside the Virtual UAV Hangar (vHangar) app.
        The app has ONE hangar; Drones are the fleet, Components are DronePart items.
        Use the provided inventory snapshot as the source of truth. Do not invent IDs.
        When you need to reference an existing item, prefer using its id from the snapshot.

        Output ONLY JSON with this exact shape:
        {
          "actions": [
            {
              "type": "createDrone | updateDrone | deleteDrone | createPart | updatePart | deletePart",
              "targetId": "uuid-or-null",
              "targetName": "string-or-null",
              "fields": { }
            }
          ]
        }

        Supported fields:
        - Drone fields: name, imageURL
        - Part fields: name, category (Motor|ESC|FC|VTX), brand, serialNumber, manualURL, imageURL, quantity (int), status (Installed|Spare|Grounded), droneId, droneName

        Inventory snapshot:
        \(context)
        """

        var body: [String: Any] = [:]
        body["systemInstruction"] = [
            "role": "user",
            "parts": [["text": systemInstruction]]
        ]
        body["contents"] = [
            ["role": "user", "parts": [["text": request]]]
        ]
        body["generationConfig"] = [
            "temperature": NSNumber(value: 0.1),
            "maxOutputTokens": NSNumber(value: 1024),
            "responseMimeType": "application/json"
        ] as [String: Any]

        if let url = productURL {
            body["contents"] = [
                ["role": "user", "parts": [["text": request]]],
                ["role": "user", "parts": [["text": "Product URL: \(url.absoluteString)"]]]
            ]
        }

        return try await sendRequest(body: body)
    }

    /// Asks Gemini to extract a structured DronePart description from free text + optional URL.
    func extractPart(from text: String, productURL: URL? = nil) async throws -> AIGeneratedPart {
        if CommandLine.arguments.contains("--ai-mock") {
            return AIGeneratedPart(name: "UITest Motor", category: "Motor", brand: "UITest Brand", serialNumber: "", manualURL: nil, imageURL: nil)
        }
        let systemInstruction = """
        You are an assistant inside a drone inventory app (Virtual UAV Hangar).
        From the user's message and optional product URL, extract ONE drone component (part).
        Output ONLY JSON with this shape, no extra text:
        {
          "name": "...",
          "category": "Motor | ESC | FC | VTX",
          "brand": "...",
          "serialNumber": "...",
          "manualURL": "https://...",
          "imageURL": "https://..."
        }
        Use null or empty strings when information is missing.
        """

        var contents: [[String: Any]] = [
            [
                "role": "user",
                "parts": [["text": text]]
            ]
        ]

        if let url = productURL {
            contents.append([
                "role": "user",
                "parts": [["text": "Product URL: \(url.absoluteString)"]]
            ])
        }

        let body: [String: Any] = [
            "systemInstruction": [
                "role": "user",
                "parts": [["text": systemInstruction]]
            ],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 512,
                "responseMimeType": "application/json"
            ]
        ]

        let jsonText = try await sendRequest(body: body)
        let data = Data(jsonText.utf8)
        return try JSONDecoder().decode(AIGeneratedPart.self, from: data)
    }

    /// Asks Gemini to extract a structured Drone description from free text + optional URL.
    func extractDrone(from text: String, productURL: URL? = nil) async throws -> AIGeneratedDrone {
        if CommandLine.arguments.contains("--ai-mock") {
            return AIGeneratedDrone(name: "UITest Drone", imageURL: nil)
        }
        let systemInstruction = """
        You are an assistant inside a drone inventory app (Virtual UAV Hangar).
        From the user's message and optional product URL, extract ONE drone.
        Output ONLY JSON with this shape, no extra text:
        {
          "name": "...",
          "imageURL": "https://..."
        }
        Use null or empty strings when information is missing.
        """

        var contents: [[String: Any]] = [
            [
                "role": "user",
                "parts": [["text": text]]
            ]
        ]

        if let url = productURL {
            contents.append([
                "role": "user",
                "parts": [["text": "Product URL: \(url.absoluteString)"]]
            ])
        }

        let body: [String: Any] = [
            "systemInstruction": [
                "role": "user",
                "parts": [["text": systemInstruction]]
            ],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 256,
                "responseMimeType": "application/json"
            ]
        ]

        let jsonText = try await sendRequest(body: body)
        let data = Data(jsonText.utf8)
        return try JSONDecoder().decode(AIGeneratedDrone.self, from: data)
    }

    // MARK: - Low-level request

    private func sendRequest(body: [String: Any]) async throws -> String {
        var request = URLRequest(url: AIConfig.geminiEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AIConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "GeminiService", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Gemini API error: \(text)"])
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        guard
            let first = decoded.candidates.first,
            let part = first.content.parts.first,
            let text = part.text
        else {
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No text content in Gemini response"])
        }
        return text
    }
}


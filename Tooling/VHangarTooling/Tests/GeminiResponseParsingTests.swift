import XCTest
@testable import VHangarTooling

/// Tests that simulate Gemini API response parsing and AI action generation.
///
/// These tests validate:
/// 1. The JSON response shape that GeminiService produces for planEdits()
/// 2. The AIGeneratedPart/AIGeneratedDrone DTO shapes (mirrored from GeminiService)
/// 3. End-to-end AI action envelopes matching what the executor would consume
///
/// No real network calls are made — all payloads are sourced from known
/// Pyrodrone product data to keep tests deterministic.
final class GeminiResponseParsingTests: XCTestCase {

    // MARK: - Mirror DTOs (match GeminiService.swift definitions)
    // These replicate the internal structs so we can test parsing without
    // importing the app target.

    private struct AIGeneratedPart: Codable {
        var name: String?
        var category: String?
        var brand: String?
        var serialNumber: String?
        var manualURL: String?
        var imageURL: String?
    }

    private struct AIGeneratedDrone: Codable {
        var name: String?
        var imageURL: String?
    }

    private struct GeminiCandidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { let text: String? }
            let parts: [Part]
        }
        let content: Content
    }

    private struct GeminiResponse: Decodable {
        let candidates: [GeminiCandidate]
    }

    private let decoder = JSONDecoder()

    // MARK: - Gemini response wrapper parsing

    func testParseGeminiTextResponse() throws {
        let json = """
        {
          "candidates": [
            {
              "content": {
                "parts": [{ "text": "You have 3 drones and 12 components in your hangar." }]
              }
            }
          ]
        }
        """
        let response = try decoder.decode(GeminiResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.candidates.first?.content.parts.first?.text,
                       "You have 3 drones and 12 components in your hangar.")
    }

    func testParseGeminiEmptyCandidates() throws {
        let json = #"{ "candidates": [] }"#
        let response = try decoder.decode(GeminiResponse.self, from: Data(json.utf8))
        XCTAssertTrue(response.candidates.isEmpty)
    }

    func testParseGeminiNullText() throws {
        let json = """
        {
          "candidates": [
            { "content": { "parts": [{ "text": null }] } }
          ]
        }
        """
        let response = try decoder.decode(GeminiResponse.self, from: Data(json.utf8))
        XCTAssertNil(response.candidates.first?.content.parts.first?.text)
    }

    // MARK: - extractPart response → AIGeneratedPart

    func testExtractPartFromMotorJSON() throws {
        // Simulates what Gemini returns for extractPart() when given the RSIII motor URL
        let geminiJSON = """
        {
          "name": "Emax RSIII 2207 2100KV FPV Racing Motor",
          "category": "Motor",
          "brand": "EMAX",
          "serialNumber": "",
          "manualURL": null,
          "imageURL": "https://pyrodrone.com/cdn/shop/products/rsiii-2207.jpg"
        }
        """
        let part = try decoder.decode(AIGeneratedPart.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(part.name, "Emax RSIII 2207 2100KV FPV Racing Motor")
        XCTAssertEqual(part.category, "Motor")
        XCTAssertEqual(part.brand, "EMAX")
        XCTAssertEqual(part.serialNumber, "")
        XCTAssertNil(part.manualURL)
        XCTAssertEqual(part.imageURL, "https://pyrodrone.com/cdn/shop/products/rsiii-2207.jpg")
    }

    func testExtractPartFromESCJSON() throws {
        // Simulates Gemini extracting a Foxeer Reaper ESC
        let geminiJSON = """
        {
          "name": "Foxeer Reaper F4 AM32 65A 3-8S 4in1 ESC",
          "category": "ESC",
          "brand": "Foxeer",
          "serialNumber": null,
          "manualURL": "https://foxeer.com/manual/reaper-f4",
          "imageURL": "https://pyrodrone.com/cdn/shop/products/foxeer-reaper.jpg"
        }
        """
        let part = try decoder.decode(AIGeneratedPart.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(part.name, "Foxeer Reaper F4 AM32 65A 3-8S 4in1 ESC")
        XCTAssertEqual(part.category, "ESC")
        XCTAssertEqual(part.brand, "Foxeer")
        XCTAssertEqual(part.manualURL, "https://foxeer.com/manual/reaper-f4")
    }

    func testExtractPartFromFCJSON() throws {
        let geminiJSON = """
        {
          "name": "TBS Lucid H7 FC 2-8S Dual Camera Input",
          "category": "FC",
          "brand": "TBS",
          "serialNumber": "",
          "manualURL": "",
          "imageURL": ""
        }
        """
        let part = try decoder.decode(AIGeneratedPart.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(part.category, "FC")
        XCTAssertEqual(part.brand, "TBS")
    }

    func testExtractPartFromVTXJSON() throws {
        let geminiJSON = """
        {
          "name": "TBS Unify Pro32 Nano 5G8 V1.1",
          "category": "VTX",
          "brand": "TBS",
          "serialNumber": null,
          "manualURL": null,
          "imageURL": null
        }
        """
        let part = try decoder.decode(AIGeneratedPart.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(part.name, "TBS Unify Pro32 Nano 5G8 V1.1")
        XCTAssertEqual(part.category, "VTX")
        XCTAssertNil(part.imageURL)
    }

    func testExtractPartMissingFields() throws {
        // Gemini sometimes omits optional fields entirely
        let geminiJSON = """
        {
          "name": "Unknown Motor",
          "category": "Motor"
        }
        """
        let part = try decoder.decode(AIGeneratedPart.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(part.name, "Unknown Motor")
        XCTAssertNil(part.brand)
        XCTAssertNil(part.imageURL)
    }

    // MARK: - extractDrone response → AIGeneratedDrone

    func testExtractDroneFromHappyModelMobula6() throws {
        let geminiJSON = """
        {
          "name": "HappyModel Mobula 6 1S Micro Whoop",
          "imageURL": "https://pyrodrone.com/cdn/shop/products/mobula6.jpg"
        }
        """
        let drone = try decoder.decode(AIGeneratedDrone.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(drone.name, "HappyModel Mobula 6 1S Micro Whoop")
        XCTAssertEqual(drone.imageURL, "https://pyrodrone.com/cdn/shop/products/mobula6.jpg")
    }

    func testExtractDroneNullImage() throws {
        let geminiJSON = #"{ "name": "BetaFPV Pavo20 Pro", "imageURL": null }"#
        let drone = try decoder.decode(AIGeneratedDrone.self, from: Data(geminiJSON.utf8))
        XCTAssertEqual(drone.name, "BetaFPV Pavo20 Pro")
        XCTAssertNil(drone.imageURL)
    }

    // MARK: - planEdits → AIActionEnvelope (full Gemini JSON-in-text round-trip)

    func testPlanEditsResponseWrappedInGeminiFormat() throws {
        // Simulates GeminiService receiving a planEdits response:
        // the action envelope JSON is embedded as `text` inside the Gemini response wrapper.
        let innerJSON = """
        {"actions":[{"type":"createDrone","fields":{"name":"BetaFPV Air65"}},{"type":"createPart","fields":{"name":"iFlight XING-E Pro 2207 1800KV","category":"Motor","brand":"iFlight","quantity":4,"status":"Spare","droneName":"BetaFPV Air65"}}]}
        """

        let wrappedJSON = """
        {
          "candidates": [
            {
              "content": {
                "parts": [{ "text": \(encodeAsJSONString(innerJSON)) }]
              }
            }
          ]
        }
        """

        // 1. Parse outer Gemini wrapper
        let response = try decoder.decode(GeminiResponse.self, from: Data(wrappedJSON.utf8))
        let text = try XCTUnwrap(response.candidates.first?.content.parts.first?.text)

        // 2. Parse inner action envelope from extracted text
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(text.utf8))
        XCTAssertEqual(envelope.actions.count, 2)
        XCTAssertEqual(envelope.actions[0].type, "createDrone")
        XCTAssertEqual(envelope.actions[1].fields?["category"]?.stringValue, "Motor")
        XCTAssertEqual(envelope.actions[1].fields?["quantity"]?.intValue, 4)
    }

    func testPlanEditsRTFFleetSetup() throws {
        // Simulates AI planning actions for seeding an RTF fleet from the catalog
        let json = """
        {
          "actions": [
            {
              "type": "createDrone",
              "fields": { "name": "EMAX Tinyhawk 3 BNF" }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "Emax RSIII 2207 2100KV Motor",
                "category": "Motor",
                "brand": "EMAX",
                "quantity": 4,
                "status": "Installed",
                "droneName": "EMAX Tinyhawk 3 BNF"
              }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "SpeedyBee F7 V3 Stack ESC 50A",
                "category": "ESC",
                "brand": "SpeedyBee",
                "quantity": 1,
                "status": "Installed",
                "droneName": "EMAX Tinyhawk 3 BNF"
              }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "SpeedyBee F7 V3 FC",
                "category": "FC",
                "brand": "SpeedyBee",
                "quantity": 1,
                "status": "Installed",
                "droneName": "EMAX Tinyhawk 3 BNF"
              }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "RUSHFPV Rush Tank SOLO VTX",
                "category": "VTX",
                "brand": "RushFPV",
                "quantity": 1,
                "status": "Installed",
                "droneName": "EMAX Tinyhawk 3 BNF"
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(envelope.actions.count, 5)

        let drone = envelope.actions[0]
        XCTAssertEqual(drone.type, "createDrone")
        XCTAssertEqual(drone.fields?["name"]?.stringValue, "EMAX Tinyhawk 3 BNF")

        let parts = envelope.actions.dropFirst()
        let categories = parts.compactMap { $0.fields?["category"]?.stringValue }
        XCTAssertEqual(Set(categories), Set(["Motor", "ESC", "FC", "VTX"]))

        let motorPart = try XCTUnwrap(envelope.actions.first { $0.fields?["category"]?.stringValue == "Motor" })
        XCTAssertEqual(motorPart.fields?["quantity"]?.intValue, 4)
    }

    // MARK: - AI action correctness checks

    func testAllPartStatusValuesAreValid() throws {
        let validStatuses = Set(["Installed", "Spare", "Grounded"])
        let json = """
        {
          "actions": [
            { "type": "createPart", "fields": { "status": "Installed" } },
            { "type": "createPart", "fields": { "status": "Spare" } },
            { "type": "createPart", "fields": { "status": "Grounded" } }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        for action in envelope.actions {
            if let status = action.fields?["status"]?.stringValue {
                XCTAssertTrue(validStatuses.contains(status), "Invalid status: \(status)")
            }
        }
    }

    func testAllPartCategoryValuesAreValid() throws {
        let validCategories = Set(["Motor", "ESC", "FC", "VTX"])
        let json = """
        {
          "actions": [
            { "type": "createPart", "fields": { "category": "Motor" } },
            { "type": "createPart", "fields": { "category": "ESC" } },
            { "type": "createPart", "fields": { "category": "FC" } },
            { "type": "createPart", "fields": { "category": "VTX" } }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        for action in envelope.actions {
            if let cat = action.fields?["category"]?.stringValue {
                XCTAssertTrue(validCategories.contains(cat), "Invalid category: \(cat)")
            }
        }
    }

    // MARK: - Helpers

    private func encodeAsJSONString(_ s: String) -> String {
        // Wraps a string in JSON quotes with proper escaping for embedding in JSON
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }
}

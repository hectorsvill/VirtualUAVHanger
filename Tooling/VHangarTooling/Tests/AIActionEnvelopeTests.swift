import XCTest
@testable import VHangarTooling

/// Tests for AIActionEnvelope and AIAction JSON parsing.
/// These validate the exact JSON shape that GeminiService.planEdits() produces
/// and that AIActionExecutor consumes.
final class AIActionEnvelopeTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - createDrone

    func testParseCreateDroneAction() throws {
        let json = """
        {
          "actions": [
            {
              "type": "createDrone",
              "targetId": null,
              "targetName": null,
              "fields": {
                "name": "HappyModel Mobula 6",
                "imageURL": "https://pyrodrone.com/cdn/shop/products/mobula6.jpg"
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(envelope.actions.count, 1)
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "createDrone")
        XCTAssertNil(action.targetId)
        XCTAssertNil(action.targetName)
        XCTAssertEqual(action.fields?["name"]?.stringValue, "HappyModel Mobula 6")
        XCTAssertEqual(action.fields?["imageURL"]?.stringValue, "https://pyrodrone.com/cdn/shop/products/mobula6.jpg")
    }

    // MARK: - updateDrone

    func testParseUpdateDroneAction() throws {
        let uuid = UUID().uuidString
        let json = """
        {
          "actions": [
            {
              "type": "updateDrone",
              "targetId": "\(uuid)",
              "targetName": null,
              "fields": {
                "name": "BetaFPV Pavo20 Pro (Renamed)"
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "updateDrone")
        XCTAssertEqual(action.targetId, uuid)
        XCTAssertEqual(action.fields?["name"]?.stringValue, "BetaFPV Pavo20 Pro (Renamed)")
    }

    // MARK: - deleteDrone

    func testParseDeleteDroneByName() throws {
        let json = """
        {
          "actions": [
            {
              "type": "deleteDrone",
              "targetId": null,
              "targetName": "DarwinFPV Darwin129"
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "deleteDrone")
        XCTAssertNil(action.targetId)
        XCTAssertEqual(action.targetName, "DarwinFPV Darwin129")
        XCTAssertNil(action.fields)
    }

    // MARK: - createPart

    func testParseCreatePartAction() throws {
        let json = """
        {
          "actions": [
            {
              "type": "createPart",
              "targetId": null,
              "targetName": null,
              "fields": {
                "name": "Emax RSIII 2207 2100KV",
                "category": "Motor",
                "brand": "EMAX",
                "quantity": 4,
                "status": "Spare",
                "manualURL": null,
                "imageURL": "https://pyrodrone.com/cdn/shop/products/rsiii.jpg",
                "droneName": "EMAX Tinyhawk 3"
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "createPart")
        XCTAssertEqual(action.fields?["name"]?.stringValue, "Emax RSIII 2207 2100KV")
        XCTAssertEqual(action.fields?["category"]?.stringValue, "Motor")
        XCTAssertEqual(action.fields?["brand"]?.stringValue, "EMAX")
        XCTAssertEqual(action.fields?["quantity"]?.intValue, 4)
        XCTAssertEqual(action.fields?["status"]?.stringValue, "Spare")
        if case .null = action.fields?["manualURL"] { /* pass */ } else { XCTFail("expected null manualURL") }
        XCTAssertEqual(action.fields?["droneName"]?.stringValue, "EMAX Tinyhawk 3")
    }

    // MARK: - updatePart

    func testParseUpdatePartAction() throws {
        let partID = UUID().uuidString
        let json = """
        {
          "actions": [
            {
              "type": "updatePart",
              "targetId": "\(partID)",
              "targetName": null,
              "fields": {
                "status": "Installed",
                "quantity": 1
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "updatePart")
        XCTAssertEqual(action.targetId, partID)
        XCTAssertEqual(action.fields?["status"]?.stringValue, "Installed")
        XCTAssertEqual(action.fields?["quantity"]?.intValue, 1)
    }

    // MARK: - deletePart

    func testParseDeletePartAction() throws {
        let json = """
        {
          "actions": [
            {
              "type": "deletePart",
              "targetId": null,
              "targetName": "TBS Unify Pro32 Nano"
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        let action = envelope.actions[0]
        XCTAssertEqual(action.type, "deletePart")
        XCTAssertEqual(action.targetName, "TBS Unify Pro32 Nano")
    }

    // MARK: - Multi-action batch

    func testParseBatchActions() throws {
        let json = """
        {
          "actions": [
            {
              "type": "createDrone",
              "fields": { "name": "BetaFPV Air65" }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "Foxeer Reaper F4 AM32 65A ESC",
                "category": "ESC",
                "brand": "Foxeer",
                "quantity": 1,
                "status": "Spare",
                "droneName": "BetaFPV Air65"
              }
            },
            {
              "type": "createPart",
              "fields": {
                "name": "iFlight XING-E Pro 2207 1800KV",
                "category": "Motor",
                "brand": "iFlight",
                "quantity": 4,
                "status": "Installed",
                "droneName": "BetaFPV Air65"
              }
            }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(envelope.actions.count, 3)
        XCTAssertEqual(envelope.actions[0].type, "createDrone")
        XCTAssertEqual(envelope.actions[1].type, "createPart")
        XCTAssertEqual(envelope.actions[1].fields?["category"]?.stringValue, "ESC")
        XCTAssertEqual(envelope.actions[2].fields?["quantity"]?.intValue, 4)
    }

    // MARK: - Empty envelope

    func testParseEmptyActions() throws {
        let json = #"{ "actions": [] }"#
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        XCTAssertTrue(envelope.actions.isEmpty)
    }

    // MARK: - Unknown action type is tolerated

    func testUnknownActionTypeIsPreserved() throws {
        let json = """
        {
          "actions": [
            { "type": "someNewFutureAction", "fields": { "key": "value" } }
          ]
        }
        """
        let envelope = try decoder.decode(AIActionEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(envelope.actions[0].type, "someNewFutureAction")
    }

    // MARK: - Encoding round-trip

    func testEnvelopeRoundTrip() throws {
        let original = AIActionEnvelope(actions: [
            AIAction(
                type: "createPart",
                targetId: nil,
                targetName: nil,
                fields: [
                    "name": .string("SpeedyBee TX800 5.8GHz VTX"),
                    "category": .string("VTX"),
                    "quantity": .int(1),
                    "status": .string("Spare")
                ]
            )
        ])
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIActionEnvelope.self, from: encoded)
        XCTAssertEqual(decoded.actions.count, 1)
        XCTAssertEqual(decoded.actions[0].fields?["name"]?.stringValue, "SpeedyBee TX800 5.8GHz VTX")
        XCTAssertEqual(decoded.actions[0].fields?["quantity"]?.intValue, 1)
    }
}

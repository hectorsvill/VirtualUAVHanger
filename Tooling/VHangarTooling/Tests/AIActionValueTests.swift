import XCTest
@testable import VHangarTooling

final class AIActionValueTests: XCTestCase {

    // MARK: - Decoding

    func testDecodeString() throws {
        let json = #""hello""#
        let data = Data(json.utf8)
        let value = try JSONDecoder().decode(AIActionValue.self, from: data)
        XCTAssertEqual(value.stringValue, "hello")
        XCTAssertNil(value.intValue)
    }

    func testDecodeInt() throws {
        let json = "42"
        let data = Data(json.utf8)
        let value = try JSONDecoder().decode(AIActionValue.self, from: data)
        XCTAssertEqual(value.intValue, 42)
        XCTAssertNil(value.stringValue)
    }

    func testDecodeBool() throws {
        let jsonTrue = "true"
        let jsonFalse = "false"
        let vTrue = try JSONDecoder().decode(AIActionValue.self, from: Data(jsonTrue.utf8))
        let vFalse = try JSONDecoder().decode(AIActionValue.self, from: Data(jsonFalse.utf8))
        if case .bool(let b) = vTrue { XCTAssertTrue(b) } else { XCTFail("expected bool") }
        if case .bool(let b) = vFalse { XCTAssertFalse(b) } else { XCTFail("expected bool") }
    }

    func testDecodeNull() throws {
        let json = "null"
        let data = Data(json.utf8)
        let value = try JSONDecoder().decode(AIActionValue.self, from: data)
        if case .null = value { /* pass */ } else { XCTFail("expected null") }
        XCTAssertNil(value.stringValue)
        XCTAssertNil(value.intValue)
    }

    func testDecodeZeroInt() throws {
        let data = Data("0".utf8)
        let value = try JSONDecoder().decode(AIActionValue.self, from: data)
        XCTAssertEqual(value.intValue, 0)
    }

    func testDecodeEmptyString() throws {
        let data = Data(#""""#.utf8)
        let value = try JSONDecoder().decode(AIActionValue.self, from: data)
        XCTAssertEqual(value.stringValue, "")
    }

    // MARK: - Encoding round-trip

    func testEncodeDecodeString() throws {
        let original = AIActionValue.string("Foxeer")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIActionValue.self, from: encoded)
        XCTAssertEqual(decoded.stringValue, "Foxeer")
    }

    func testEncodeDecodeInt() throws {
        let original = AIActionValue.int(4)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIActionValue.self, from: encoded)
        XCTAssertEqual(decoded.intValue, 4)
    }

    func testEncodeDecodeNull() throws {
        let original = AIActionValue.null
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIActionValue.self, from: encoded)
        if case .null = decoded { /* pass */ } else { XCTFail("expected null after round-trip") }
    }

    // MARK: - Fields dictionary decoding

    func testDecodeFieldsDictionary() throws {
        let json = """
        {
          "name": "Emax ECO II 2207",
          "quantity": 4,
          "category": "Motor",
          "featured": false,
          "serialNumber": null
        }
        """
        let data = Data(json.utf8)
        let fields = try JSONDecoder().decode([String: AIActionValue].self, from: data)

        XCTAssertEqual(fields["name"]?.stringValue, "Emax ECO II 2207")
        XCTAssertEqual(fields["quantity"]?.intValue, 4)
        XCTAssertEqual(fields["category"]?.stringValue, "Motor")
        if case .bool(let b) = fields["featured"] { XCTAssertFalse(b) } else { XCTFail() }
        if case .null = fields["serialNumber"] { /* pass */ } else { XCTFail() }
    }
}

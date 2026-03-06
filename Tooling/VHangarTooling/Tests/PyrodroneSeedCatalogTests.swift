import XCTest
@testable import VHangarTooling

/// Validates that the PyrodroneSeedCatalog contains well-formed, real Pyrodrone product data.
final class PyrodroneSeedCatalogTests: XCTestCase {

    private let allEntries = PyrodroneSeedCatalog.entries
    private let validCategories = Set(["Motor", "ESC", "FC", "VTX"])
    private let validKinds: Set<PyrodroneSeedEntry.Kind> = [.drone, .part]

    // MARK: - Structural integrity

    func testCatalogIsNonEmpty() {
        XCTAssertFalse(allEntries.isEmpty, "Seed catalog must not be empty")
    }

    func testAllSubCatalogsAreNonEmpty() {
        XCTAssertFalse(PyrodroneSeedCatalog.rtfDrones.isEmpty, "RTF drones catalog is empty")
        XCTAssertFalse(PyrodroneSeedCatalog.motors.isEmpty, "Motors catalog is empty")
        XCTAssertFalse(PyrodroneSeedCatalog.escs.isEmpty, "ESCs catalog is empty")
        XCTAssertFalse(PyrodroneSeedCatalog.flightControllers.isEmpty, "Flight controllers catalog is empty")
        XCTAssertFalse(PyrodroneSeedCatalog.vtxUnits.isEmpty, "VTX catalog is empty")
    }

    func testAllEntriesHaveNonEmptyNames() {
        for entry in allEntries {
            XCTAssertFalse(entry.name.trimmingCharacters(in: .whitespaces).isEmpty,
                           "Entry \(entry.id) has an empty name")
        }
    }

    func testAllEntriesHavePyrodroneURL() {
        for entry in allEntries {
            XCTAssertTrue(
                entry.productURL.hasPrefix("https://pyrodrone.com/products/"),
                "Expected pyrodrone.com product URL, got: \(entry.productURL)"
            )
        }
    }

    func testNoDuplicateProductURLs() {
        let urls = allEntries.map(\.productURL)
        let unique = Set(urls)
        XCTAssertEqual(urls.count, unique.count,
                       "Duplicate product URLs found in seed catalog")
    }

    func testNoDuplicateIDs() {
        let ids = allEntries.map(\.id)
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count, "Duplicate UUIDs found in seed catalog")
    }

    // MARK: - Drone entries

    func testDroneEntriesHaveNoCategory() {
        let drones = allEntries.filter { $0.kind == .drone }
        for drone in drones {
            XCTAssertNil(drone.category,
                         "Drone '\(drone.name)' should not have a category, got: \(drone.category ?? "?")")
        }
    }

    func testDroneEntriesHaveBrand() {
        let drones = allEntries.filter { $0.kind == .drone }
        for drone in drones {
            let brand = drone.brand ?? ""
            XCTAssertFalse(brand.trimmingCharacters(in: .whitespaces).isEmpty,
                           "Drone '\(drone.name)' has no brand")
        }
    }

    func testRTFDroneCount() {
        XCTAssertGreaterThanOrEqual(PyrodroneSeedCatalog.rtfDrones.count, 10,
                                    "Expected at least 10 RTF/BNF drone entries")
    }

    // MARK: - Part entries

    func testPartEntriesHaveValidCategory() {
        let parts = allEntries.filter { $0.kind == .part }
        for part in parts {
            XCTAssertNotNil(part.category,
                            "Part '\(part.name)' is missing a category")
            if let cat = part.category {
                XCTAssertTrue(validCategories.contains(cat),
                              "Part '\(part.name)' has invalid category '\(cat)'")
            }
        }
    }

    func testPartEntriesHaveQuantity() {
        let parts = allEntries.filter { $0.kind == .part }
        for part in parts {
            XCTAssertNotNil(part.quantity, "Part '\(part.name)' is missing quantity")
            if let qty = part.quantity {
                XCTAssertGreaterThan(qty, 0, "Part '\(part.name)' quantity must be > 0")
            }
        }
    }

    func testMotorQuantityIsFour() {
        let motors = PyrodroneSeedCatalog.motors
        for motor in motors {
            XCTAssertEqual(motor.quantity, 4,
                           "Motor '\(motor.name)' should have quantity 4 (one per arm)")
        }
    }

    func testAllCategoriesRepresented() {
        let parts = allEntries.filter { $0.kind == .part }
        let categories = Set(parts.compactMap(\.category))
        XCTAssertTrue(categories.contains("Motor"), "No Motor entries in catalog")
        XCTAssertTrue(categories.contains("ESC"), "No ESC entries in catalog")
        XCTAssertTrue(categories.contains("FC"), "No FC entries in catalog")
        XCTAssertTrue(categories.contains("VTX"), "No VTX entries in catalog")
    }

    // MARK: - Known entries spot-check

    func testKnownRTFDronesPresent() {
        let names = Set(allEntries.map(\.name))
        XCTAssertTrue(names.contains("Emax Tinyhawk 3 FPV Racing Drone - FrSky Bind N Fly (BNF)"))
        XCTAssertTrue(names.contains("HappyModel BNF Mobula 6 1S Micro Whoop Quadcopter"))
        XCTAssertTrue(names.contains("BetaFPV Air65 1S 65mm Analog 400mW ELRS 2.4G Brushless Whoop"))
        XCTAssertTrue(names.contains("DarwinFPV Darwin129 7\" Long Range PNP"))
    }

    func testKnownComponentsPresent() {
        let names = Set(allEntries.map(\.name))
        // Motors
        XCTAssertTrue(names.contains("Emax RSIII 2207 2100KV FPV Racing Motor"))
        XCTAssertTrue(names.contains("iFlight XING-E Pro 2207 1800KV 2-6S FPV Motor"))
        // ESCs
        XCTAssertTrue(names.contains("Foxeer Reaper F4 AM32 65A 3-8S 4in1 ESC - 30x30mm"))
        XCTAssertTrue(names.contains("Skystars KM60 BLHeli32 60A 3-6S 4-in-1 ESC - 30x30mm"))
        // Flight Controllers
        XCTAssertTrue(names.contains("TBS Lucid H7 FC 2-8S Dual Camera Input - 30x30mm"))
        XCTAssertTrue(names.contains("KISS Ultra V3 Flight Controller"))
        // VTX
        XCTAssertTrue(names.contains("TBS Unify Pro32 Nano 5G8 V1.1"))
        XCTAssertTrue(names.contains("iFlight Blitz 5.8GHz 1.6W Adjustable VTX"))
    }

    func testKnownURLsAreCorrect() {
        let urlMap = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.name, $0.productURL) })
        XCTAssertEqual(
            urlMap["Emax RSIII 2207 2100KV FPV Racing Motor"],
            "https://pyrodrone.com/products/emax-rsiii-2207-2100kv-fpv-racing-motor"
        )
        XCTAssertEqual(
            urlMap["RUSHFPV Rush Tank SOLO 5.8GHz 1.6W 37CH VTX - US Version"],
            "https://pyrodrone.com/products/rushfpv-rush-tank-solo-5-8ghz-1-6w-37ch-vtx-us-version"
        )
    }
}

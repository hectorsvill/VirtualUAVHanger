import Foundation

public struct PyrodroneSeedEntry: Identifiable, Sendable, Codable {
    public enum Kind: String, Codable, Sendable {
        case drone
        case part
    }

    public var id: UUID
    public var kind: Kind
    public var name: String
    public var brand: String?
    /// Motor | ESC | FC | VTX (for parts)
    public var category: String?
    public var quantity: Int?
    public var productURL: String

    public init(
        id: UUID = UUID(),
        kind: Kind,
        name: String,
        brand: String? = nil,
        category: String? = nil,
        quantity: Int? = nil,
        productURL: String
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.brand = brand
        self.category = category
        self.quantity = quantity
        self.productURL = productURL
    }
}

public enum PyrodroneSeedCatalog {
    public static let entries: [PyrodroneSeedEntry] = [
        .init(
            kind: .drone,
            name: "Emax Tinyhawk 3 FPV Racing Drone - FrSky Bind N Fly (BNF)",
            brand: "EMAX",
            productURL: "https://pyrodrone.com/products/emax-tinyhawk-3-fpv-racing-drone-frsky-bind-n-fly-bnf"
        ),
        .init(
            kind: .part,
            name: "SpeedyBee F7 V3 Stack w/ 50A 3-6S BLHeli_32 128K 4in1 ESC - 30x30mm",
            brand: "SpeedyBee",
            category: "FC",
            quantity: 1,
            productURL: "https://pyrodrone.com/products/speedybee-f7-v3-stack-w-50a-3-6s-blheli_32-128k-4in1-esc-30x30mm"
        ),
        .init(
            kind: .part,
            name: "RUSHFPV Rush Tank SOLO 5.8GHz 1.6W 37CH VTX - US Version",
            brand: "RushFPV",
            category: "VTX",
            quantity: 1,
            productURL: "https://pyrodrone.com/products/rushfpv-rush-tank-solo-5-8ghz-1-6w-37ch-vtx-us-version"
        ),
        .init(
            kind: .part,
            name: "Emax RSIII 2207 2100KV FPV Racing Motor",
            brand: "EMAX",
            category: "Motor",
            quantity: 4,
            productURL: "https://pyrodrone.com/products/emax-rsiii-2207-2100kv-fpv-racing-motor"
        )
    ]
}

public struct AIActionEnvelope: Codable, Sendable {
    public var actions: [AIAction]
}

public struct AIAction: Codable, Sendable {
    public var type: String
    public var targetId: String?
    public var targetName: String?
    public var fields: [String: AIActionValue]?
}

public enum AIActionValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let i = try? container.decode(Int.self) { self = .int(i); return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        self = .null
    }
}


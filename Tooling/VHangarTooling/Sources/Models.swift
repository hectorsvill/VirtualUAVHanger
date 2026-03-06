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
    /// Real Pyrodrone product links covering RTF/BNF drones and all component categories.
    /// Sources: pyrodrone.com/collections/bnf-pnp-rtf, /motors, /electronic-speed-controllers-2,
    ///          /flight-controllers, /analog-vtx  (sampled March 2026)
    public static let entries: [PyrodroneSeedEntry] = rtfDrones + motors + escs + flightControllers + vtxUnits

    // MARK: - RTF / BNF / PNP Drones

    public static let rtfDrones: [PyrodroneSeedEntry] = [
        .init(kind: .drone, name: "Emax Tinyhawk 3 FPV Racing Drone - FrSky Bind N Fly (BNF)", brand: "EMAX",
              productURL: "https://pyrodrone.com/products/emax-tinyhawk-3-fpv-racing-drone-frsky-bind-n-fly-bnf"),
        .init(kind: .drone, name: "EMAX Tinyhawk II Racing Drone RTF", brand: "EMAX",
              productURL: "https://pyrodrone.com/products/emax-tinyhawk-2-racing-drone-rtf-with-runcam-nano2-rtf"),
        .init(kind: .drone, name: "Emax Tinyhawk II Freestyle RTF Kit With Controller & Goggles", brand: "EMAX",
              productURL: "https://pyrodrone.com/products/emax-tinyhawk-ii-freestyle-rtf-kit-with-controller-goggles"),
        .init(kind: .drone, name: "EMAX EZ Pilot 75mm Beginner Indoor Racing Drone - RTF", brand: "EMAX",
              productURL: "https://pyrodrone.com/products/emax-ez-pilot-beginner-indoor-racing-drone-rtf"),
        .init(kind: .drone, name: "HappyModel BNF Mobula 6 1S Micro Whoop Quadcopter", brand: "HappyModel",
              productURL: "https://pyrodrone.com/products/happymodel-bnf-mobula-6-1s-micro-whoop-quadcopter"),
        .init(kind: .drone, name: "Happymodel Mobula8 1-2S 85mm Analog Micro FPV Whoop Drone", brand: "HappyModel",
              productURL: "https://pyrodrone.com/products/happymodel-mobula8-1-2s-85mm-analog-micro-fpv-whoop-drone-choose-receiver"),
        .init(kind: .drone, name: "Happymodel Mobula7 1S 75mm Analog FPV Brushless Whoop", brand: "HappyModel",
              productURL: "https://pyrodrone.com/products/happymodel-mobula7-1s-75mm-analog-fpv-brushless-whoop-drone-choose-receiver"),
        .init(kind: .drone, name: "BetaFPV Air65 1S 65mm Analog 400mW ELRS 2.4G Brushless Whoop", brand: "BetaFPV",
              productURL: "https://pyrodrone.com/products/betafpv-air65-1s-brushless-whoop-quadcopter-elrs-2-4g"),
        .init(kind: .drone, name: "BetaFPV Air75 1S 75mm Analog 400mW VTX Brushless Whoop", brand: "BetaFPV",
              productURL: "https://pyrodrone.com/products/betafpv-air75-1s-75mm-analog-400mw-vtx-brushless-whoop-quadcopter-choose-receiver"),
        .init(kind: .drone, name: "BetaFPV Pavo20 Pro 2.2\" Cinewhoop Quadcopter (DJI O3)", brand: "BetaFPV",
              productURL: "https://pyrodrone.com/products/betafpv-pavo20-pro-2-2-cinewhoop-quadcopter-dji-o3-ready-choose-receiver"),
        .init(kind: .drone, name: "BetaFPV Meteor75 Pro 1S 75mm HD with O4 Air Unit", brand: "BetaFPV",
              productURL: "https://pyrodrone.com/products/betafpv-meteor75-pro-1s-75mm-hd-with-o4-air-unit-brushless-whoop-quadcopter-elrs-2-4ghz"),
        .init(kind: .drone, name: "DarwinFPV Darwin129 7\" Long Range PNP", brand: "DarwinFPV",
              productURL: "https://pyrodrone.com/products/darwinfpv-darwin129-7-long-range-bnf"),
        .init(kind: .drone, name: "NewBeeDrone Hummingbird V3.1 RaceSpec 1S Analog ELRS BNF", brand: "NewBeeDrone",
              productURL: "https://pyrodrone.com/products/newbeedrone-hummingbird-v3-1-1s-analog-elrs-2-4ghz-bnf-brushless-fpv-whoop-random-color"),
    ]

    // MARK: - Motors

    public static let motors: [PyrodroneSeedEntry] = [
        .init(kind: .part, name: "Emax RSIII 2207 2100KV FPV Racing Motor", brand: "EMAX",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/emax-rsiii-2207-2100kv-fpv-racing-motor"),
        .init(kind: .part, name: "HYPERLITE 2408.5 Team Edition 1322KV Motor", brand: "Brother Hobby",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/hyperlite-2408-5-team-edition-choose-kv"),
        .init(kind: .part, name: "iFlight XING-E Pro 2207 1800KV 2-6S FPV Motor", brand: "iFlight",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/iflight-xing-e-2207-2-6s-fpv-motor"),
        .init(kind: .part, name: "Emax ECO II 2207 1900KV Stator Motor", brand: "EMAX",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/emax-eco-ii-2207-stator-motor-for-5-propeller-racing-and-freestyle-craft-1900kv"),
        .init(kind: .part, name: "Emax ECO II 2306 1700KV Stator Motor", brand: "EMAX",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/emax-eco-ii-2306-stator-for-5-6-propeller-racing-freestyle-and-cinematic-hd-camera-equipped-crafts-1700kv"),
        .init(kind: .part, name: "BrotherHobby Avenger 2806.5 1300KV Motor", brand: "Brother Hobby",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/brotherhobby-avenger-2806-5-1300kv-1700kv-motor"),
        .init(kind: .part, name: "iFlight XING X2208 1800KV 2-6S FPV NextGen Motor", brand: "iFlight",
              category: "Motor", quantity: 4,
              productURL: "https://pyrodrone.com/products/iflight-xing-x2208-2-6s-fpv-nextgen-motor"),
    ]

    // MARK: - Electronic Speed Controllers (ESC)

    public static let escs: [PyrodroneSeedEntry] = [
        .init(kind: .part, name: "SpeedyBee F7 V3 Stack w/ 50A 3-6S BLHeli_32 128K 4in1 ESC - 30x30mm", brand: "SpeedyBee",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/speedybee-f7-v3-stack-w-50a-3-6s-blheli_32-128k-4in1-esc-30x30mm"),
        .init(kind: .part, name: "Skystars KM60 BLHeli32 60A 3-6S 4-in-1 ESC - 30x30mm", brand: "Skystars",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/skystars-km60-blheli32-60a-3-6s-4-in-1-esc-30x30mm"),
        .init(kind: .part, name: "Foxeer Reaper F4 AM32 65A 3-8S 4in1 ESC - 30x30mm", brand: "Foxeer",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/foxeer-reaper-f4-am32-128k-32bit-65a-3-8s-4in1-esc-30x30mm"),
        .init(kind: .part, name: "Foxeer Mini Reaper F4 AM32 45A 3-6S 4in1 ESC - 20x20mm", brand: "Foxeer",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/foxeer-mini-reaper-f4-am32-128k-32bit-45a-3-6s-4in1-esc-20x20mm"),
        .init(kind: .part, name: "Lumenier ELITE PRO 60A 2-6S AM32 4-in-1 ESC - 30x30mm", brand: "Lumenier",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/lumenier-elite-pro-60a-2-6s-am32-4-in-1-esc-30x30mm"),
        .init(kind: .part, name: "iFlight Borg 60R 3-8S 60A ESC - 20x20mm", brand: "iFlight",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/iflight-borg-60r-3-8s-60a-esc-20x20mm"),
        .init(kind: .part, name: "T-Motor F35A 32Bit 35A 3-6S AM32 Electronic Speed Controller", brand: "T-Motor",
              category: "ESC", quantity: 1,
              productURL: "https://pyrodrone.com/products/t-motor-f35a-32bit-35a-3-6s-am32-electronic-speed-controller"),
    ]

    // MARK: - Flight Controllers

    public static let flightControllers: [PyrodroneSeedEntry] = [
        .init(kind: .part, name: "TBS Lucid H7 FC 2-8S Dual Camera Input - 30x30mm", brand: "TBS",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/tbs-lucid-h7-fc-2-8s-dual-camera-input-icm42688-x-2-duo-gyro-flight-controller-30x30mm-ndaa"),
        .init(kind: .part, name: "HDZero Gamma 45A 3-6S HD-Ready AIO Flight Controller", brand: "Divimath",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/hdzero-gamma-45a-3-6s-hd-ready-aio-flight-controller-for-2-5-4in-digital-builds-elrs-2-4ghz-rx-25-25mm"),
        .init(kind: .part, name: "BetaFPV Air Brushless Flight Controller G4 4-in-1 AIO 400mW VTX", brand: "BetaFPV",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/betafpv-air-brushless-flight-controller-g4-4-in-1-aio-400mw-vtx"),
        .init(kind: .part, name: "KISS Ultra V3 Flight Controller", brand: "KISS",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/kiss-ultra-v3-flight-controller"),
        .init(kind: .part, name: "Happymodel X14 ELRS 5-IN-1 AIO Flight Controller", brand: "HappyModel",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/happymodel-x14-elrs-5-in-1-aio-flight-controller-built-in-2-4g-uart-elrs-v3-0-and-openvtx"),
        .init(kind: .part, name: "HDZero Halo Stack H7 FC and 70A 3S-8S 4in1 ESC - 20x20mm", brand: "Divimath",
              category: "FC", quantity: 1,
              productURL: "https://pyrodrone.com/products/hdzero-halo-stack-h7-flight-controller-and-70a-3s-8s-4in1-esc-20x20mm-choose-version"),
    ]

    // MARK: - Video Transmitters (VTX)

    public static let vtxUnits: [PyrodroneSeedEntry] = [
        .init(kind: .part, name: "RUSHFPV Rush Tank SOLO 5.8GHz 1.6W 37CH VTX - US Version", brand: "RushFPV",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/rushfpv-rush-tank-solo-5-8ghz-1-6w-37ch-vtx-us-version"),
        .init(kind: .part, name: "TBS Unify Pro32 Nano 5G8 V1.1", brand: "TBS",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/tbs-unify-pro32-nano-5g8"),
        .init(kind: .part, name: "TBS Unify Pro32 HV (MMCX)", brand: "TBS",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/tbs-unify-pro32-hv-mmcx"),
        .init(kind: .part, name: "RUSHFPV Tank Tiny 5.8GHz VTX Smart Audio", brand: "RushFPV",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/rushfpv-tank-tiny-5-8ghz-vtx-smart-audio-0-25-100-200-350mw-us-version"),
        .init(kind: .part, name: "SpeedyBee TX800 5.8GHz Video Transmitter", brand: "SpeedyBee",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/speedy-bee-tx800-5-8ghz-video-transmitter"),
        .init(kind: .part, name: "iFlight Blitz 5.8GHz 1.6W Adjustable VTX", brand: "iFlight",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/iflight-blitz-5-8ghz-1-6w-adjustable-vtx"),
        .init(kind: .part, name: "Foxeer Reaper Extreme 2.5W V3 5.8GHz Analog VTX", brand: "Foxeer",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/foxeer-reaper-extreme-2-5w-5-8ghz-37ch-adjustable-analog-vtx"),
        .init(kind: .part, name: "GEPRC RAD Mini 1W 5.8GHz VTX", brand: "GEPRC",
              category: "VTX", quantity: 1,
              productURL: "https://pyrodrone.com/products/geprc-rad-mini-1w-5-8ghz-vtx"),
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


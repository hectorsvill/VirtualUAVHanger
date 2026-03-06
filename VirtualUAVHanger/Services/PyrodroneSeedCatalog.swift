//
//  PyrodroneSeedCatalog.swift
//  VirtualUAVHanger
//
//  Test catalog entries sourced from Pyrodrone product pages.
//

import Foundation

struct PyrodroneSeedEntry: Identifiable {
    enum Kind {
        case drone
        case part
    }

    let id = UUID()
    let kind: Kind
    let name: String
    let brand: String?
    let category: PartCategory?
    let quantity: Int?
    let productURL: String
}

enum PyrodroneSeedCatalog {
    /// A few real Pyrodrone links to seed demo/test data.
    static let entries: [PyrodroneSeedEntry] = [
        .init(
            kind: .drone,
            name: "Emax Tinyhawk 3 FPV Racing Drone - FrSky Bind N Fly (BNF)",
            brand: "EMAX",
            category: nil,
            quantity: nil,
            productURL: "https://pyrodrone.com/products/emax-tinyhawk-3-fpv-racing-drone-frsky-bind-n-fly-bnf"
        ),
        .init(
            kind: .part,
            name: "SpeedyBee F7 V3 Stack w/ 50A 3-6S BLHeli_32 128K 4in1 ESC - 30x30mm",
            brand: "SpeedyBee",
            category: .fc,
            quantity: 1,
            productURL: "https://pyrodrone.com/products/speedybee-f7-v3-stack-w-50a-3-6s-blheli_32-128k-4in1-esc-30x30mm"
        ),
        .init(
            kind: .part,
            name: "RUSHFPV Rush Tank SOLO 5.8GHz 1.6W 37CH VTX - US Version",
            brand: "RushFPV",
            category: .vtx,
            quantity: 1,
            productURL: "https://pyrodrone.com/products/rushfpv-rush-tank-solo-5-8ghz-1-6w-37ch-vtx-us-version"
        ),
        .init(
            kind: .part,
            name: "Emax RSIII 2207 2100KV FPV Racing Motor",
            brand: "EMAX",
            category: .motor,
            quantity: 4,
            productURL: "https://pyrodrone.com/products/emax-rsiii-2207-2100kv-fpv-racing-motor"
        )
    ]
}


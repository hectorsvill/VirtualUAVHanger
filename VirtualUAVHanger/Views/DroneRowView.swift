//
//  DroneRowView.swift
//  VirtualUAVHanger
//
//  Row presentation for a Drone.
//

import SwiftUI

struct DroneRowView: View {
    let drone: Drone

    var body: some View {
        HStack(spacing: 12) {
            if drone.localImagePath != nil || (drone.imageURL != nil && !(drone.imageURL?.isEmpty ?? true)) {
                EntityThumbnailView(
                    localImagePath: drone.localImagePath,
                    imageURL: drone.imageURL,
                    size: 44
                )
            } else {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(drone.name)
                    .font(.headline)
                Text("\(drone.parts.count) component\(drone.parts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}


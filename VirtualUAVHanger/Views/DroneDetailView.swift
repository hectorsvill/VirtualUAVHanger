//
//  DroneDetailView.swift
//  VirtualUAVHanger
//
//  Shows one drone and its components; link to add/edit parts.
//

import SwiftData
import SwiftUI

struct DroneDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.partRepository) private var partRepository
    let drone: Drone
    @State private var showAddPart = false
    @State private var partToEdit: DronePart?

    private var parts: [DronePart] {
        drone.parts.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            if drone.localImagePath != nil || (drone.imageURL != nil && !(drone.imageURL?.isEmpty ?? true)) {
                Section {
                    EntityThumbnailView(
                        localImagePath: drone.localImagePath,
                        imageURL: drone.imageURL,
                        size: 160
                    )
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            Section("Components") {
                if parts.isEmpty {
                    Text("No components")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(parts, id: \.id) { part in
                        DronePartRowView(part: part)
                            .contentShape(Rectangle())
                            .onTapGesture { partToEdit = part }
                        .contextMenu {
                            Button(role: .destructive) { deletePart(part) } label: {
                                Label("Remove Part", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(drone.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddPart = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddPart) {
            if let repo = partRepository {
                PartFormView(drone: drone, partRepository: repo) { part in
                    try? repo.create(part)
                    showAddPart = false
                } onCancel: { showAddPart = false }
            }
        }
        .sheet(item: $partToEdit) { part in
            if let repo = partRepository {
                PartFormView(
                    drone: drone,
                    part: part,
                    partRepository: repo,
                    onSaveEdit: { try? repo.update(part); partToEdit = nil },
                    onCancel: { partToEdit = nil }
                )
            }
        }
    }

    private func deletePart(_ part: DronePart) {
        try? partRepository?.delete(part)
    }
}

// MARK: - Part row (reusable)

struct DronePartRowView: View {
    let part: DronePart

    var body: some View {
        HStack(spacing: 12) {
            if part.localImagePath != nil || (part.imageURL != nil && !(part.imageURL?.isEmpty ?? true)) {
                EntityThumbnailView(
                    localImagePath: part.localImagePath,
                    imageURL: part.imageURL,
                    size: 44
                )
            } else {
                Image(systemName: categoryIcon(part.category))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(part.name)
                        .font(.headline)
                    if part.quantity > 1 {
                        Text("×\(part.quantity)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(part.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !part.serialNumber.isEmpty {
                    Text(part.serialNumber)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(part.status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func categoryIcon(_ category: PartCategory) -> String {
        switch category {
        case .motor: return "gearshape.2.fill"
        case .esc: return "bolt.fill"
        case .fc: return "cpu.fill"
        case .vtx: return "antenna.radiowaves.left.and.right"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Hangar.self, Drone.self, DronePart.self, configurations: config)
    let d = Drone(name: "Quad 1")
    container.mainContext.insert(d)
    return NavigationStack {
        DroneDetailView(drone: d)
            .modelContainer(container)
            .environment(\.partRepository, PartRepository(modelContext: container.mainContext))
    }
}

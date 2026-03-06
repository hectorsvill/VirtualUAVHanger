//
//  FleetView.swift
//  VirtualUAVHanger
//
//  Fleet flow (single global hangar): Drones → Parts.
//

import SwiftData
import SwiftUI

/// vHangar currently treats the entire app as ONE hangar.
/// This view lists all drones globally (no Hangar UI).
struct FleetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Drone.name) private var drones: [Drone]
    @State private var selectedDrone: Drone?
    @State private var showAddDrone = false

    var body: some View {
        NavigationStack {
            Group {
                if drones.isEmpty {
                    FleetEmptyState(onAdd: { showAddDrone = true })
                } else {
                    List(selection: $selectedDrone) {
                        ForEach(drones, id: \.id) { drone in
                            NavigationLink(value: drone) {
                                DroneRowView(drone: drone)
                            }
                            .contextMenu {
                                Button(role: .destructive) { deleteDrone(drone) } label: {
                                    Label("Delete Drone", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Fleet")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddDrone = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .navigationDestination(for: Drone.self) { drone in
                DroneDetailView(drone: drone)
            }
            .sheet(isPresented: $showAddDrone) {
                DroneFormView { name, imageURL, localImagePath in
                    addDrone(name: name, imageURL: imageURL, localImagePath: localImagePath)
                    showAddDrone = false
                } onCancel: { showAddDrone = false }
            }
        }
    }

    private func addDrone(name: String, imageURL: String? = nil, localImagePath: String? = nil) {
        let d = Drone(name: name, hangar: nil, imageURL: imageURL, localImagePath: localImagePath)
        modelContext.insert(d)
        try? modelContext.save()
    }

    private func deleteDrone(_ drone: Drone) {
        modelContext.delete(drone)
        try? modelContext.save()
    }
}

// MARK: - Empty state

struct FleetEmptyState: View {
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Drones", systemImage: "airplane.departure")
        } description: {
            Text("Add a drone to start tracking components.")
        } actions: {
            Button("Add Drone", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FleetView()
        .modelContainer(for: [Drone.self, DronePart.self], inMemory: true)
}

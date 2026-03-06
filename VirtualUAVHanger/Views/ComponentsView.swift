//
//  ComponentsView.swift
//  VirtualUAVHanger
//
//  All components (parts) list; filter by category/status; add/edit part.
//

import SwiftData
import SwiftUI

struct ComponentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.partRepository) private var partRepository
    @Query(sort: [SortDescriptor<DronePart>(\.updatedAt, order: .reverse)]) private var parts: [DronePart]
    @State private var selectedPart: DronePart?
    @State private var showAddPart = false
    @State private var partToEdit: DronePart?
    @State private var filterCategory: PartCategory?
    @State private var filterStatus: PartStatus?

    private var filteredParts: [DronePart] {
        var list = parts
        if let c = filterCategory {
            list = list.filter { $0.category == c }
        }
        if let s = filterStatus {
            list = list.filter { $0.status == s }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredParts.isEmpty {
                    ComponentsEmptyState(hasParts: !parts.isEmpty) {
                        showAddPart = true
                    }
                } else {
                    List(selection: $selectedPart) {
                        ForEach(filteredParts, id: \.id) { part in
                            NavigationLink(value: part) {
                                DronePartRowView(part: part)
                            }
                            .contextMenu {
                                Button { partToEdit = part } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) { deletePart(part) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Components")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showAddPart = true } label: {
                            Label("Add Part", systemImage: "plus.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Picker("Category", selection: $filterCategory) {
                            Text("All").tag(nil as PartCategory?)
                            ForEach(PartCategory.allCases) { c in
                                Text(c.rawValue).tag(c as PartCategory?)
                            }
                        }
                        Picker("Status", selection: $filterStatus) {
                            Text("All").tag(nil as PartStatus?)
                            ForEach(PartStatus.allCases) { s in
                                Text(s.rawValue).tag(s as PartStatus?)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .navigationDestination(for: DronePart.self) { part in
                PartDetailView(part: part)
            }
            .sheet(isPresented: $showAddPart) {
                if let repo = partRepository {
                    PartFormView(drone: nil, partRepository: repo) { newPart in
                        try? repo.create(newPart)
                        showAddPart = false
                    } onCancel: { showAddPart = false }
                }
            }
            .sheet(item: $partToEdit) { part in
                if let repo = partRepository {
                    PartFormView(
                        drone: part.drone,
                        part: part,
                        partRepository: repo,
                        onSaveEdit: { try? repo.update(part); partToEdit = nil },
                        onCancel: { partToEdit = nil }
                    )
                }
            }
        }
    }

    private func deletePart(_ part: DronePart) {
        try? partRepository?.delete(part)
    }
}

// MARK: - Part detail (read-only + edit)

struct PartDetailView: View {
    let part: DronePart
    @Environment(\.partRepository) private var partRepository
    @State private var showEdit = false

    var body: some View {
        List {
            if part.localImagePath != nil || (part.imageURL != nil && !(part.imageURL?.isEmpty ?? true)) {
                Section {
                    EntityThumbnailView(
                        localImagePath: part.localImagePath,
                        imageURL: part.imageURL,
                        size: 160
                    )
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            Section("Part") {
                LabeledContent("Name", value: part.name)
                LabeledContent("Category", value: part.category.rawValue)
                LabeledContent("Brand", value: part.brand)
                LabeledContent("Count", value: "\(max(1, part.quantity))")
                if !part.serialNumber.isEmpty {
                    LabeledContent("Serial", value: part.serialNumber)
                }
            }
            Section("Status") {
                LabeledContent("Status", value: part.status.rawValue)
                if let drone = part.drone {
                    LabeledContent("Installed on", value: drone.name)
                }
            }
            if let url = part.manualURL {
                Section("Manual") {
                    Link(destination: URL(string: url) ?? URL(string: "https://")!) {
                        Label("Open manual", systemImage: "doc.fill")
                    }
                }
            }
        }
        .navigationTitle(part.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let repo = partRepository {
                PartFormView(
                    drone: part.drone,
                    part: part,
                    partRepository: repo,
                    onSaveEdit: { try? repo.update(part); showEdit = false },
                    onCancel: { showEdit = false }
                )
            }
        }
    }
}

// MARK: - Empty state

struct ComponentsEmptyState: View {
    let hasParts: Bool
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(hasParts ? "No matching parts" : "No Components", systemImage: "wrench.and.screwdriver")
        } description: {
            Text(hasParts ? "Try changing the filter." : "Add components to track motors, ESCs, FCs, and VTXs.")
        } actions: {
            if !hasParts {
                Button("Add Part", action: onAdd)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ComponentsView()
        .modelContainer(for: DronePart.self, inMemory: true)
}

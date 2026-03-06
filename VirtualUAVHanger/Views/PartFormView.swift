//
//  PartFormView.swift
//  VirtualUAVHanger
//
//  Add/edit DronePart: name, category, brand, serial, manual, status, drone.
//

import SwiftData
import SwiftUI

struct PartFormView: View {
    @Environment(\.modelContext) private var modelContext
    let drone: Drone?
    var part: DronePart?
    let partRepository: PartRepositoryProtocol
    var onSave: (DronePart) -> Void = { _ in }
    var onSaveEdit: (() -> Void)?
    var onCancel: () -> Void

    @State private var name = ""
    @State private var category: PartCategory = .motor
    @State private var brand = ""
    @State private var serialNumber = ""
    @State private var manualURLText = ""
    @State private var status: PartStatus = .spare
    @State private var quantity: Int = 1
    @State private var selectedDroneId: UUID?
    @State private var imageURL: String?
    @State private var localImagePath: String?
    @FocusState private var focusedField: Field?

    private var allDrones: [Drone] {
        let descriptor = FetchDescriptor<Drone>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var isEdit: Bool { part != nil }

    enum Field { case name, brand, serial, manualURL }

    var body: some View {
        NavigationStack {
            Form {
                Section("Part") {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                    Picker("Category", selection: $category) {
                        ForEach(PartCategory.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    TextField("Brand", text: $brand)
                        .focused($focusedField, equals: .brand)
                    TextField("Serial number", text: $serialNumber)
                        .focused($focusedField, equals: .serial)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(PartStatus.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }
                Section("Quantity") {
                    Stepper(value: $quantity, in: 1...999) {
                        Text("Count: \(quantity)")
                    }
                }
                Section("Assignment") {
                    Picker("Installed on", selection: $selectedDroneId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(allDrones, id: \.id) { d in
                            Text(d.name).tag(d.id as UUID?)
                        }
                    }
                }
                Section("Manual") {
                    TextField("Manual URL", text: $manualURLText)
                        .focused($focusedField, equals: .manualURL)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                }
                EntityImagePickerView(
                    localImagePath: $localImagePath,
                    imageURL: $imageURL,
                    label: "Photo"
                )
            }
            .navigationTitle(isEdit ? "Edit Part" : "New Part")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEdit ? "Save" : "Add") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear { bindPart() }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func bindPart() {
        if let p = part {
            name = p.name
            category = p.category
            brand = p.brand
            serialNumber = p.serialNumber
            manualURLText = p.manualURL ?? ""
            status = p.status
            quantity = max(1, p.quantity)
            selectedDroneId = p.drone?.id
            imageURL = p.imageURL
            localImagePath = p.localImagePath
        } else {
            selectedDroneId = drone?.id
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = manualURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let manualURL = url.isEmpty ? nil : url

        if let existing = part {
            existing.name = trimmedName
            existing.category = category
            existing.brand = trimmedBrand
            existing.serialNumber = serialNumber
            existing.quantity = max(1, quantity)
            existing.manualURL = manualURL
            existing.status = status
            existing.drone = allDrones.first { $0.id == selectedDroneId }
            existing.imageURL = imageURL
            existing.localImagePath = localImagePath
            onSaveEdit?()
        } else {
            let assignedDrone = allDrones.first { $0.id == selectedDroneId }
            let newPart = DronePart(
                name: trimmedName,
                category: category,
                brand: trimmedBrand,
                serialNumber: serialNumber,
                quantity: max(1, quantity),
                manualURL: manualURL,
                imageURL: imageURL,
                localImagePath: localImagePath,
                status: status,
                drone: assignedDrone
            )
            onSave(newPart)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Drone.self, DronePart.self, configurations: config)
    let d = Drone(name: "Quad 1")
    container.mainContext.insert(d)
    let repo = PartRepository(modelContext: container.mainContext)
    return PartFormView(drone: d, partRepository: repo) { _ in } onCancel: { }
        .modelContainer(container)
}

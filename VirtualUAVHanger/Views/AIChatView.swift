//
//  AIChatView.swift
//  VirtualUAVHanger
//
//  Onboard AI assistant powered by Gemini:
//  - Chat about your fleet and components.
//  - Paste a product URL so Gemini can pull details.
//  - Ask it to draft new drones or parts, then create them directly.
//

import Combine
import SwiftData
import SwiftUI

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var inputText: String = ""
    @Published var productURLText: String = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    private let service: GeminiService

    init(service: GeminiService = .shared) {
        self.service = service
    }

    func sendChat(context: String) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        errorMessage = nil
        let userMessage = AIMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        inputText = ""

        isSending = true
        Task {
            do {
                let url = URL(string: productURLText.trimmingCharacters(in: .whitespacesAndNewlines))
                let reply = try await service.chat(messages: messages, productURL: url, context: context)
                await MainActor.run {
                    messages.append(AIMessage(role: .model, text: reply))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    func createPart(using modelContext: ModelContext, repository: PartRepositoryProtocol, drone: Drone?) {
        guard let last = messages.last(where: { $0.role == .model }) else { return }
        let text = last.text
        let url = URL(string: productURLText.trimmingCharacters(in: .whitespacesAndNewlines))

        isSending = true
        Task {
            do {
                let partDTO = try await service.extractPart(from: text, productURL: url)
                await MainActor.run {
                    let name = (partDTO.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled Part"
                    let brand = (partDTO.brand?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Unknown"
                    let category = PartCategory(rawValue: (partDTO.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? .motor
                    let serial = partDTO.serialNumber ?? ""
                    let manual = partDTO.manualURL?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let imageURL = partDTO.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines)

                    let newPart = DronePart(
                        name: name,
                        category: category,
                        brand: brand,
                        serialNumber: serial,
                        quantity: 1,
                        manualURL: manual,
                        imageURL: imageURL,
                        localImagePath: nil,
                        status: .spare,
                        drone: drone
                    )
                    do {
                        try repository.create(newPart)
                    } catch {
                        self.errorMessage = "Failed to save part: \(error.localizedDescription)"
                    }
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSending = false
                }
            }
        }
    }

    func createDrone(using modelContext: ModelContext) {
        guard let last = messages.last(where: { $0.role == .model }) else { return }
        let text = last.text
        let url = URL(string: productURLText.trimmingCharacters(in: .whitespacesAndNewlines))

        isSending = true
        Task {
            do {
                let dto = try await service.extractDrone(from: text, productURL: url)
                await MainActor.run {
                    let name = (dto.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "New Drone"
                    let imageURL = dto.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let drone = Drone(name: name, hangar: nil, imageURL: imageURL, localImagePath: nil)
                    modelContext.insert(drone)
                    do {
                        try modelContext.save()
                    } catch {
                        self.errorMessage = "Failed to save drone: \(error.localizedDescription)"
                    }
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSending = false
                }
            }
        }
    }

    func applyEdits(context: String, modelContext: ModelContext, repository: PartRepositoryProtocol) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        errorMessage = nil

        let requestText = trimmed
        inputText = ""

        isSending = true
        Task {
            do {
                let url = URL(string: productURLText.trimmingCharacters(in: .whitespacesAndNewlines))
                let json = try await service.planEdits(request: requestText, productURL: url, context: context)
                let data = Data(json.utf8)
                let envelope = try JSONDecoder().decode(AIActionEnvelope.self, from: data)
                let result = AIActionExecutor.apply(envelope: envelope, modelContext: modelContext, partRepository: repository)

                await MainActor.run {
                    var summary = "Applied \(result.applied) action(s)."
                    if !result.failures.isEmpty {
                        summary += "\nFailures:\n- " + result.failures.joined(separator: "\n- ")
                    }
                    messages.append(AIMessage(role: .model, text: summary))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSending = false
                }
            }
        }
    }
}

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.partRepository) private var partRepository
    @Query(sort: \Drone.name) private var drones: [Drone]

    @StateObject private var viewModel = AIChatViewModel()
    @State private var selectedDrone: Drone?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.offset) { _, message in
                            messageBubble(for: message)
                        }
                    }
                    .padding()
                }

                Divider()

                VStack(spacing: 8) {
                    HStack {
                        TextField("Optional product URL", text: $viewModel.productURLText)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            #endif
                    }

                    HStack(alignment: .top, spacing: 8) {
                        TextField("Ask about a part, drone, or paste a product link…", text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)

                        Menu {
                            Button {
                                let context = AIContextBuilder.snapshot(modelContext: modelContext)
                                viewModel.sendChat(context: context)
                            } label: {
                                Label("Send (Chat)", systemImage: "message.fill")
                            }

                            if let repo = partRepository {
                                Button {
                                    let context = AIContextBuilder.snapshot(modelContext: modelContext)
                                    viewModel.applyEdits(context: context, modelContext: modelContext, repository: repo)
                                } label: {
                                    Label("Apply Edits", systemImage: "wand.and.stars")
                                }
                            }
                        } label: {
                            if viewModel.isSending {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSending || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    aiActionsToolbar

                    #if DEBUG
                    if let repo = partRepository {
                        Button {
                            seedPyrodroneCatalog(modelContext: modelContext, repo: repo)
                        } label: {
                            Label("Seed Pyrodrone test catalog", systemImage: "shippingbox.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isSending)
                    }
                    #endif

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
        }
    }

    #if DEBUG
    private func seedPyrodroneCatalog(modelContext: ModelContext, repo: PartRepositoryProtocol) {
        let entries = PyrodroneSeedCatalog.entries

        // Create the example drone (if missing).
        if let droneEntry = entries.first(where: { $0.kind == .drone }) {
            let existing = (try? modelContext.fetch(FetchDescriptor<Drone>())) ?? []
            if existing.first(where: { $0.name == droneEntry.name }) == nil {
                let d = Drone(name: droneEntry.name, hangar: nil, imageURL: droneEntry.productURL, localImagePath: nil)
                modelContext.insert(d)
                try? modelContext.save()
            }
        }

        // Create parts as spares.
        for entry in entries where entry.kind == .part {
            let part = DronePart(
                name: entry.name,
                category: entry.category ?? .motor,
                brand: entry.brand ?? "Unknown",
                serialNumber: "",
                quantity: max(1, entry.quantity ?? 1),
                manualURL: entry.productURL,
                imageURL: entry.productURL,
                localImagePath: nil,
                status: .spare,
                drone: nil
            )
            try? repo.create(part)
        }

        viewModel.messages.append(
            AIMessage(
                role: .model,
                text: "Seeded Pyrodrone test catalog: \(entries.filter { $0.kind == .drone }.count) drone + \(entries.filter { $0.kind == .part }.count) parts."
            )
        )
    }
    #endif

    @ViewBuilder
    private var aiActionsToolbar: some View {
        HStack {
            Menu {
                Picker("Drone (optional)", selection: $selectedDrone) {
                    Text("None").tag(nil as Drone?)
                    ForEach(drones, id: \.id) { drone in
                        Text(drone.name).tag(drone as Drone?)
                    }
                }
            } label: {
                Label("Target", systemImage: "scope")
            }

            Spacer()

            if partRepository != nil {
                Button {
                    guard let repo = partRepository else { return }
                    viewModel.createPart(using: modelContext, repository: repo, drone: selectedDrone)
                } label: {
                    Label("Create Part", systemImage: "plus.circle")
                }
                .disabled(viewModel.isSending || partRepository == nil)
            }

            Button {
                viewModel.createDrone(using: modelContext)
            } label: {
                Label("Create Drone", systemImage: "airplane.badge.plus")
            }
            .disabled(viewModel.isSending)
        }
        .font(.footnote)
    }

    @ViewBuilder
    private func messageBubble(for message: AIMessage) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(isUser ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(isUser ? "You" : "AI")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}


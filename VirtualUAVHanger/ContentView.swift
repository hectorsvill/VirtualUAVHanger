//
//  ContentView.swift
//  VirtualUAVHanger
//
//  Adaptive shell: TabBar on iPhone, Sidebar on iPad/macOS.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var sidebarSelection: SidebarView.AppSection? = .fleet

    private var useCompactLayout: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        Group {
            #if os(iOS)
            if useCompactLayout {
                TabView {
                    FleetView()
                        .tabItem { Label("Fleet", systemImage: "building.2.fill") }
                    ComponentsView()
                        .tabItem { Label("Components", systemImage: "wrench.and.screwdriver.fill") }
                    AIChatView()
                        .tabItem { Label("AI", systemImage: "sparkles") }
                }
            } else {
                sidebarContent
            }
            #else
            sidebarContent
            #endif
        }
        .withPartRepository(from: modelContext)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } content: {
            switch sidebarSelection ?? .fleet {
            case .fleet: FleetView()
            case .components: ComponentsView()
            case .assistant: AIChatView()
            }
        } detail: {
            Text("Select an item")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Sidebar (iPad / macOS)

struct SidebarView: View {
    @Binding var selection: AppSection?

    enum AppSection: String, CaseIterable {
        case fleet = "Fleet"
        case components = "Components"
        case assistant = "AI"
    }

    var body: some View {
        List(AppSection.allCases, id: \.self, selection: $selection) { section in
            NavigationLink(value: section) {
                Label(section.rawValue, systemImage: icon(for: section))
            }
        }
        .navigationTitle("vHangar")
        .listStyle(.sidebar)
    }

    private func icon(for section: AppSection) -> String {
        switch section {
        case .fleet: return "building.2.fill"
        case .components: return "wrench.and.screwdriver.fill"
        case .assistant: return "sparkles"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Hangar.self, Drone.self, DronePart.self], inMemory: true)
}

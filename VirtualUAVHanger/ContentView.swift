//
//  ContentView.swift
//  VirtualUAVHanger
//
//  Adaptive shell: TabBar on iPhone, Sidebar on iPad/macOS.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var sidebarSelection: SidebarView.AppSection? = .fleet
    @State private var showSignOutAlert = false

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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        accountButton
                    }
                }
            } else {
                sidebarContent
            }
            #else
            sidebarContent
            #endif
        }
        .withPartRepository(from: modelContext)
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { authManager.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Account Button

    @ViewBuilder
    private var accountButton: some View {
        Menu {
            if let user = authManager.currentUser {
                Section {
                    Label(user.displayName, systemImage: "person.fill")
                    if let email = user.email {
                        Label(email, systemImage: "envelope.fill")
                    }
                    Label("via \(user.provider.displayName)", systemImage: providerIcon(user.provider))
                }
            }
            Divider()
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            AvatarBadge(session: authManager.currentUser)
        }
    }

    private func providerIcon(_ provider: AuthProvider) -> String {
        switch provider {
        case .apple:  "applelogo"
        case .google: "globe"
        case .email:  "envelope.fill"
        }
    }

    // MARK: - Sidebar (iPad / macOS)

    @ViewBuilder
    private var sidebarContent: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        accountButton
                    }
                }
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

// MARK: - Avatar Badge

/// Circular badge showing user initials or a person icon.
struct AvatarBadge: View {
    let session: UserSession?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 32, height: 32)

            if let initials = session?.initials, !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.accent)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.accent)
            }
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
        .environmentObject(AuthManager())
}

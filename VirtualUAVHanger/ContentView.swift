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
    @State private var showSignOutAlert  = false
    @State private var showUpgradeSheet  = false   // guest → real account
    @State private var showDataPreserved = false   // post-upgrade toast

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
                // Guest prompt as a non-intrusive top inset
                .safeAreaInset(edge: .top, spacing: 0) {
                    if authManager.isGuest {
                        GuestBanner { showUpgradeSheet = true }
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
        // Sign-out confirmation — extra context for guests
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            if authManager.isGuest {
                Button("Sign In First") {
                    showSignOutAlert = false
                    showUpgradeSheet = true
                }
                Button("Sign Out Anyway", role: .destructive) { authManager.signOut() }
            } else {
                Button("Sign Out", role: .destructive) { authManager.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if authManager.isGuest {
                Text("Your hangar data lives only on this device as a guest. Sign in first to keep it safe across reinstalls.")
            } else {
                Text("Are you sure you want to sign out?")
            }
        }
        // Upgrade sheet (guest → real account)
        .sheet(isPresented: $showUpgradeSheet) {
            LoginView(isUpgradeFlow: true)
                .environmentObject(authManager)
                .onDisappear {
                    // Show "data preserved" toast if user successfully upgraded
                    if authManager.isAuthenticated && !authManager.isGuest {
                        showDataPreserved = true
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            showDataPreserved = false
                        }
                    }
                }
        }
        // "Data preserved" toast shown briefly after upgrading from guest
        .overlay(alignment: .top) {
            if showDataPreserved {
                DataPreservedToast()
                    .padding(.top, 56)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showDataPreserved)
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
            // Guests get a prominent "Sign In" option first
            if authManager.isGuest {
                Button {
                    showUpgradeSheet = true
                } label: {
                    Label("Sign In to Save Data", systemImage: "person.badge.shield.checkmark.fill")
                }
            }
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
        case .guest:  "person.fill.questionmark"
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
                .safeAreaInset(edge: .top, spacing: 0) {
                    if authManager.isGuest {
                        GuestBanner { showUpgradeSheet = true }
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

/// Circular badge showing user initials, a guest icon, or a generic person icon.
struct AvatarBadge: View {
    let session: UserSession?

    private var isGuest: Bool { session?.provider == .guest }

    var body: some View {
        ZStack {
            Circle()
                .fill(isGuest
                      ? Color.orange.opacity(0.2)
                      : Color.accentColor.opacity(0.2))
                .frame(width: 32, height: 32)

            if isGuest {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.orange)
            } else if let initials = session?.initials, !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

// MARK: - Data Preserved Toast

/// Brief green confirmation shown after a guest successfully upgrades to a real account.
private struct DataPreservedToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("You're signed in. Your hangar data has been preserved.")
                .font(.footnote)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
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

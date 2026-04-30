# vHangar — Virtual UAV Hangar

A SwiftUI app for FPV and UAV hobbyists to organize their drone fleet and component inventory, with an onboard AI assistant powered by Google Gemini.

## Features

- **Fleet management** — Add, view, and delete drones. Each drone can have a name, photo (local or URL), and a full parts list.
- **Component inventory** — Track every part across your entire fleet. Parts are categorized as Motor, ESC, FC, or VTX and carry a lifecycle status: *Installed*, *Spare*, or *Grounded*.
- **AI Assistant** — Chat with Gemini about your inventory, paste a product URL to pull in details automatically, or ask the assistant to create drones and parts on your behalf.
- **Flexible authentication** — Sign in with Apple, Google (OAuth 2.0 + PKCE), email/password (SHA-256 hashed locally), or continue as a guest.
- **Guest mode** — Local-only data with a one-tap upgrade path to a real account; your hangar data is preserved on upgrade.
- **Adaptive layout** — Tab bar on iPhone, three-column sidebar on iPad and macOS.

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 16 or later |
| iOS deployment target | iOS 17+ |
| macOS deployment target | macOS 14+ (Sonoma) |
| Swift | 5.9+ |

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/hectorsvill/VirtualUAVHanger.git
cd VirtualUAVHanger
```

### 2. Configure environment variables in Xcode

Open `VirtualUAVHanger.xcodeproj`, then go to **Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables** and add:

| Key | Value | Required |
|---|---|---|
| `GEMINI_API_KEY` | Your [Google AI Studio](https://aistudio.google.com/) API key | Yes (for AI features) |
| `GOOGLE_CLIENT_ID` | Your iOS client ID from [Google Cloud Console](https://console.cloud.google.com/) | Only for Google Sign-In |

> **Note:** The app will crash at launch in Debug builds if `GEMINI_API_KEY` is missing. In Release builds the AI features are silently disabled.

### 3. Enable Sign in with Apple (optional)

In Xcode, select the **VirtualUAVHanger** target → **Signing & Capabilities** → click **+ Capability** → add **Sign in with Apple**.

### 4. Build and run

Select the **VirtualUAVHanger** scheme and your target device/simulator, then press **⌘R**.

## Project Structure

```
VirtualUAVHanger/
├── Models/
│   ├── Hangar.swift          # SwiftData model — location containing drones
│   ├── Drone.swift           # SwiftData model — a drone in the fleet
│   ├── DronePart.swift       # SwiftData model — a component on a drone
│   ├── PartCategory.swift    # Enum: Motor | ESC | FC | VTX
│   └── PartStatus.swift      # Enum: Installed | Spare | Grounded
├── Views/
│   ├── FleetView.swift       # Drone list
│   ├── DroneDetailView.swift # Parts list for a specific drone
│   ├── ComponentsView.swift  # Global parts list across all drones
│   ├── AIChatView.swift      # AI assistant chat interface
│   ├── DroneFormView.swift   # Add / edit drone form
│   ├── PartFormView.swift    # Add / edit part form
│   └── Auth/                 # Login, email sign-in, guest banner views
├── Services/
│   ├── GeminiService.swift   # Gemini API client (chat, planEdits, extractPart/Drone)
│   ├── AIAction.swift        # Codable action format returned by the AI
│   ├── AIActionExecutor.swift# Applies AI-generated actions to SwiftData
│   ├── AIContextBuilder.swift# Builds an inventory snapshot for Gemini context
│   ├── AIConfig.swift        # Reads GEMINI_API_KEY from the environment
│   ├── ImageStorageService.swift # Saves images to the local file system
│   └── PyrodroneSeedCatalog.swift# Demo catalog of real FPV hardware
├── Auth/
│   ├── AuthManager.swift     # Sign in with Apple / Google / Email / Guest
│   └── UserSession.swift     # Persisted session model
├── Repositories/
│   └── PartRepository*.swift # SwiftData CRUD for DronePart, injected via environment
├── ContentView.swift         # Adaptive shell (TabView / NavigationSplitView)
└── VirtualUAVHangerApp.swift # App entry point, SwiftData container setup
Tooling/
└── VHangarTooling/           # Swift package for build/code-generation tooling
VirtualUAVHangerUITests/
└── VirtualUAVHangerUITests.swift # XCUITest suite (login, fleet, parts, AI)
```

## AI Assistant

The AI tab lets you interact with your inventory in natural language. There are two send modes:

- **Send (Chat)** — Conversational response. Use the *Create Drone* or *Create Part* buttons to save the last AI suggestion directly to SwiftData.
- **Apply Edits** — Asks Gemini to produce a structured JSON action plan (`createDrone`, `updatePart`, `deletePart`, …) and executes it against your live inventory in one step.

You can optionally paste a product URL (e.g., from pyrodrone.com) into the URL field so Gemini can pull in specs automatically.

### AI mock mode (UI tests)

Pass `--ai-mock` as a launch argument to replace all Gemini network calls with deterministic local stubs. This is used by the UI test suite so no API key is needed in CI.

## Running the UI Tests

The UI test target requires no real credentials. Launch arguments injected by the test runner keep each test isolated:

| Argument | Effect |
|---|---|
| `--uitesting` | Uses an in-memory SwiftData store (data reset per run) |
| `--reset-auth` | Clears the persisted session so the login screen always appears |
| `--seed-pyrodrone` | Pre-populates the hangar with demo Pyrodrone catalog data |
| `--ai-mock` | Replaces Gemini calls with local stubs |

Run the **VirtualUAVHangerUITests** scheme from Xcode or via `xcodebuild test`.

## License

This project is released under the [MIT License](LICENSE).

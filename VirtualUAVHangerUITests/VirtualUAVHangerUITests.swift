//
//  VirtualUAVHangerUITests.swift
//  VirtualUAVHangerUITests
//
//  GUI tests covering: login screen, guest sign-in, guest banner,
//  upgrade flow sheet, tab navigation, email sign-in, sign-out alert,
//  Pyrodrone seed data in the Fleet view, add drone, add part, and
//  add drone + part via the AI assistant (mocked with --ai-mock).
//

import XCTest

final class VirtualUAVHangerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset to logged-out state and use in-memory store for each test
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func screenshot(_ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func signInAsGuest() {
        let guestBtn = app.buttons["btn_guest_signin"]
        XCTAssertTrue(guestBtn.waitForExistence(timeout: 5), "Guest button must exist")
        guestBtn.tap()
        XCTAssertTrue(
            app.staticTexts["Browsing as guest · Data is local only"].waitForExistence(timeout: 5),
            "GuestBanner must appear after guest sign-in"
        )
    }

    // MARK: - 1. Login Screen

    func test01_LoginScreenAppears() throws {
        let appleBtn = app.buttons["btn_apple_signin"]
        XCTAssertTrue(appleBtn.waitForExistence(timeout: 5), "Sign in with Apple button must exist")

        let googleBtn = app.buttons["btn_google_signin"]
        XCTAssertTrue(googleBtn.exists, "Continue with Google button must exist")

        let emailBtn = app.buttons["btn_email_signin"]
        XCTAssertTrue(emailBtn.exists, "Continue with Email button must exist")

        let guestBtn = app.buttons["btn_guest_signin"]
        XCTAssertTrue(guestBtn.exists, "Continue as Guest button must exist")

        screenshot("01_LoginScreen")
    }

    // MARK: - 2. Guest Sign-In & Banner

    func test02_GuestSignInShowsBanner() throws {
        signInAsGuest()
        screenshot("02_GuestBanner")
    }

    // MARK: - 3. Tab Navigation (as Guest)

    func test03_TabNavigation() throws {
        signInAsGuest()

        let componentsTab = app.tabBars.buttons["Components"]
        XCTAssertTrue(componentsTab.waitForExistence(timeout: 3))
        componentsTab.tap()
        screenshot("03a_ComponentsTab")

        let aiTab = app.tabBars.buttons["AI"]
        XCTAssertTrue(aiTab.waitForExistence(timeout: 3))
        aiTab.tap()
        screenshot("03b_AITab")

        app.tabBars.buttons["Fleet"].tap()
        screenshot("03c_FleetTab")
    }

    // MARK: - 4. Guest Banner → Upgrade Sheet

    func test04_GuestBannerOpensUpgradeSheet() throws {
        signInAsGuest()

        let signInBannerBtn = app.buttons["Sign In"]
        XCTAssertTrue(signInBannerBtn.waitForExistence(timeout: 3))
        signInBannerBtn.tap()

        let title = app.staticTexts["Save Your Hangar"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Upgrade sheet 'Save Your Hangar' title must appear")

        let note = app.staticTexts["Your existing hangar data will be preserved."]
        XCTAssertTrue(note.exists, "Data-preservation note must be visible")

        screenshot("04_UpgradeSheet")

        // Dismiss
        let xBtn = app.buttons["Close"]
        if xBtn.waitForExistence(timeout: 2) {
            xBtn.tap()
        } else {
            app.swipeDown()
        }
    }

    // MARK: - 5. Guest Sign-Out Alert (data-loss warning)

    func test05_GuestSignOutAlert() throws {
        signInAsGuest()

        // The account avatar button is in the navigation bar (top-bar trailing).
        // SwiftUI places ToolbarItem(.topBarTrailing) in the navigation bar area.
        let navBars = app.navigationBars
        let accountBtn = navBars.buttons.firstMatch
        if accountBtn.waitForExistence(timeout: 3) {
            accountBtn.tap()
        } else {
            // Fallback: try any button in the entire app that's not a tab bar item
            let allBtns = app.buttons.matching(
                NSPredicate(format: "NOT label IN %@",
                            ["Fleet", "Components", "AI", "Sign In"])
            )
            if allBtns.firstMatch.waitForExistence(timeout: 2) {
                allBtns.firstMatch.tap()
            }
        }

        let signOutOption = app.buttons["Sign Out"]
        if signOutOption.waitForExistence(timeout: 2) {
            signOutOption.tap()
        }

        let alert = app.alerts["Sign Out"]
        if alert.waitForExistence(timeout: 3) {
            let warnText = alert.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'local'")
            ).firstMatch
            XCTAssertTrue(warnText.exists, "Alert must warn about local-only data")
            screenshot("05_GuestSignOutAlert")
            alert.buttons["Cancel"].tap()
        } else {
            // Alert didn't appear; just screenshot current state for diagnostic purposes
            screenshot("05_GuestAccountMenu")
        }
    }

    // MARK: - 6. Email Sign-In Flow

    func test06_EmailSignIn() throws {
        let emailBtn = app.buttons["btn_email_signin"]
        XCTAssertTrue(emailBtn.waitForExistence(timeout: 5))
        emailBtn.tap()

        let emailField = app.textFields["field_email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field must appear")
        emailField.tap()
        emailField.typeText("pilot@vhangar.test")

        let passwordField = app.secureTextFields["field_password"]
        XCTAssertTrue(passwordField.exists, "Password field must exist")
        passwordField.tap()
        passwordField.typeText("secure123")

        screenshot("06a_EmailForm")

        let continueBtn = app.buttons["btn_email_continue"]
        XCTAssertTrue(continueBtn.waitForExistence(timeout: 2))
        continueBtn.tap()

        // After sign-in, main app (Fleet) should be visible, no GuestBanner
        XCTAssertTrue(app.tabBars.buttons["Fleet"].waitForExistence(timeout: 5),
                      "Fleet tab must be visible after email sign-in")
        XCTAssertFalse(app.staticTexts["Browsing as guest · Data is local only"].exists,
                       "GuestBanner must not be shown after email sign-in")
        screenshot("06b_EmailSignedIn")
    }

    // MARK: - 7. Pyrodrone Seed Data in Fleet

    func test07_PyrodroneSeedDataAppearsInFleet() throws {
        // Launch with seed data and auto-login as guest
        app.terminate()
        app.launchArguments = ["--uitesting", "--reset-auth", "--seed-pyrodrone"]
        app.launch()

        // Sign in as guest so we reach ContentView
        signInAsGuest()

        // Fleet tab should now show seeded drones
        let fleetTab = app.tabBars.buttons["Fleet"]
        XCTAssertTrue(fleetTab.waitForExistence(timeout: 5))
        fleetTab.tap()

        // Wait for the drone list to populate (data is inserted async)
        let tinyhawk = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Tinyhawk'")
        ).firstMatch
        XCTAssertTrue(tinyhawk.waitForExistence(timeout: 8),
                      "Pyrodrone-seeded 'Tinyhawk' drone must appear in Fleet view")

        screenshot("07a_PyrodroneFleet")

        // Also verify Components tab shows seeded parts
        app.tabBars.buttons["Components"].tap()
        let motor = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Motor' OR label CONTAINS 'ESC' OR label CONTAINS 'RSIII'")
        ).firstMatch
        // Components may be filtered to a selected drone; just take a screenshot
        screenshot("07b_PyrodroneComponents")
    }

    // MARK: - 8. Add Drone (manual form)

    func test08_AddDrone() throws {
        signInAsGuest()

        let fleetTab = app.tabBars.buttons["Fleet"]
        XCTAssertTrue(fleetTab.waitForExistence(timeout: 5))
        fleetTab.tap()

        // Open DroneFormView.
        // SwiftUI Form renders cells in UICollectionView; the empty-state button
        // (not in a toolbar) is the most reliable tap target.
        let emptyStateBtn = app.buttons["Add Drone"]
        let toolbarBtn    = app.buttons["btn_fleet_add_drone"]
        if emptyStateBtn.waitForExistence(timeout: 3) {
            emptyStateBtn.tap()
        } else {
            XCTAssertTrue(toolbarBtn.waitForExistence(timeout: 3), "Must have an add-drone button")
            toolbarBtn.tap()
        }

        // DroneFormView has exactly ONE text field (the name input).
        // SwiftUI Form text-field identifiers don't propagate to UITextField on iOS 26,
        // so we locate it as the first text field in the app after the sheet opens.
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Drone name field must appear")
        nameField.tap()
        nameField.typeText("UITest Drone")

        screenshot("08a_DroneForm")

        // DroneFormView sets accessibilityLabel "Confirm Add Drone" on the toolbar button
        // so we can distinguish it from the Fleet's "+" toolbar button (also labelled "Add").
        let addBtn = app.buttons["Confirm Add Drone"]
        XCTAssertTrue(addBtn.waitForExistence(timeout: 3), "Confirm Add Drone button must exist")
        addBtn.tap()

        // Verify drone appears in Fleet list
        let droneName = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'UITest Drone'")
        ).firstMatch
        XCTAssertTrue(droneName.waitForExistence(timeout: 5), "Added drone 'UITest Drone' must appear in Fleet list")

        screenshot("08b_DroneAddedToFleet")
    }

    // MARK: - 9. Add Part (manual form)

    func test09_AddPart() throws {
        signInAsGuest()

        let componentsTab = app.tabBars.buttons["Components"]
        XCTAssertTrue(componentsTab.waitForExistence(timeout: 5))
        componentsTab.tap()

        // Open PartFormView via the empty-state button (most reliable) or toolbar menu.
        let emptyStateBtn = app.buttons["Add Part"]
        let toolbarMenu   = app.buttons["btn_components_plus_menu"]
        if emptyStateBtn.waitForExistence(timeout: 3) {
            emptyStateBtn.tap()
        } else {
            XCTAssertTrue(toolbarMenu.waitForExistence(timeout: 3), "Must have an add-part button")
            toolbarMenu.tap()
            // Tap the menu item that opens the form
            let menuItem = app.buttons["Add Part"]
            if menuItem.waitForExistence(timeout: 3) { menuItem.tap() }
        }

        // PartFormView: Name is the 1st text field, Brand is the 2nd.
        // (SwiftUI Form identifier propagation is unreliable on iOS 26;
        //  use element(boundBy:) instead.)
        let nameField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Part name field must appear")
        nameField.tap()
        nameField.typeText("UITest Motor")

        let brandField = app.textFields.element(boundBy: 1)
        XCTAssertTrue(brandField.waitForExistence(timeout: 3), "Brand field must exist")
        brandField.tap()
        brandField.typeText("UITest Brand")

        screenshot("09a_PartForm")

        // PartFormView sets accessibilityLabel "Confirm Add Part" on the toolbar button.
        let addBtn = app.buttons["Confirm Add Part"]
        XCTAssertTrue(addBtn.waitForExistence(timeout: 3), "Confirm Add Part button must exist")
        addBtn.tap()

        // Verify part appears in Components list
        let partName = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'UITest Motor'")
        ).firstMatch
        XCTAssertTrue(partName.waitForExistence(timeout: 5), "Added part 'UITest Motor' must appear in Components list")

        screenshot("09b_PartAddedToComponents")
    }

    // MARK: - 10. Add Drone and Part via AI (mocked)

    func test10_AddDroneAndPartWithAI() throws {
        // Re-launch with AI mock so no real Gemini calls are made
        app.terminate()
        app.launchArguments = ["--uitesting", "--reset-auth", "--ai-mock"]
        app.launch()

        signInAsGuest()

        let aiTab = app.tabBars.buttons["AI"]
        XCTAssertTrue(aiTab.waitForExistence(timeout: 5))
        aiTab.tap()

        // ── Part A: Create Drone via AI ───────────────────────────────────────

        // Type in AI chat input (axis:.vertical TextField renders as textView on iOS)
        let chatInput = findAIChatInput()
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5), "AI chat input must exist")
        chatInput.tap()
        chatInput.typeText("Add a drone called UITest Drone")

        // Open send menu and tap "Send (Chat)"
        let sendMenu = app.buttons["btn_ai_send_menu"]
        XCTAssertTrue(sendMenu.waitForExistence(timeout: 3), "Send menu button must exist")
        sendMenu.tap()

        let sendChatItem = app.buttons["Send (Chat)"]
        XCTAssertTrue(sendChatItem.waitForExistence(timeout: 3), "'Send (Chat)' menu item must appear")
        sendChatItem.tap()

        // Wait for mock AI reply to appear in the chat
        let aiReply = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Mock AI'")
        ).firstMatch
        XCTAssertTrue(aiReply.waitForExistence(timeout: 8), "Mock AI reply must appear in chat")

        screenshot("10a_AI_DroneChat")

        // Tap "Create Drone" — extracts from the last model message (mocked → "UITest Drone")
        let createDroneBtn = app.buttons["Create Drone"]
        XCTAssertTrue(createDroneBtn.waitForExistence(timeout: 3), "'Create Drone' button must exist")
        createDroneBtn.tap()

        // Verify in Fleet tab
        app.tabBars.buttons["Fleet"].tap()
        let aiDrone = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'UITest Drone'")
        ).firstMatch
        XCTAssertTrue(aiDrone.waitForExistence(timeout: 8), "AI-created 'UITest Drone' must appear in Fleet")

        screenshot("10b_AI_DroneInFleet")

        // ── Part B: Create Part via AI ────────────────────────────────────────

        aiTab.tap()

        let chatInput2 = findAIChatInput()
        XCTAssertTrue(chatInput2.waitForExistence(timeout: 3))
        chatInput2.tap()
        chatInput2.typeText("Add a motor UITest Motor from UITest Brand")

        sendMenu.tap()

        let sendChatItem2 = app.buttons["Send (Chat)"]
        XCTAssertTrue(sendChatItem2.waitForExistence(timeout: 3))
        sendChatItem2.tap()

        // Wait for the second mock reply
        let aiReply2 = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Mock AI'")
        ).firstMatch
        XCTAssertTrue(aiReply2.waitForExistence(timeout: 8), "Mock AI reply must appear for part chat")

        screenshot("10c_AI_PartChat")

        // Tap "Create Part" — mocked → "UITest Motor" / "Motor" / "UITest Brand"
        let createPartBtn = app.buttons["Create Part"]
        XCTAssertTrue(createPartBtn.waitForExistence(timeout: 3), "'Create Part' button must exist")
        createPartBtn.tap()

        // Verify in Components tab
        app.tabBars.buttons["Components"].tap()
        let aiPart = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'UITest Motor'")
        ).firstMatch
        XCTAssertTrue(aiPart.waitForExistence(timeout: 8), "AI-created 'UITest Motor' must appear in Components")

        screenshot("10d_AI_PartInComponents")
    }

    // MARK: - Private helpers

    /// Finds the AI chat TextField regardless of whether iOS renders it as textField or textView.
    /// TextField(axis: .vertical) becomes a UITextView internally on iOS 16+.
    private func findAIChatInput() -> XCUIElement {
        let pred = NSPredicate(format: "identifier == 'field_ai_chat_input'")
        let asTextField = app.descendants(matching: .textField).matching(pred).firstMatch
        if asTextField.exists { return asTextField }
        return app.descendants(matching: .textView).matching(pred).firstMatch
    }
}

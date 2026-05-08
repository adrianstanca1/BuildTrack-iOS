import XCTest

final class BuildTrackUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    // MARK: - Auth Flow
    
    func testLoginFlowShowsDashboard() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        
        emailField.tap()
        emailField.typeText("demo@buildtrack.com")
        
        passwordField.tap()
        passwordField.typeText("DemoPass123!")
        
        signInButton.tap()
        
        // Should transition to dashboard
        let dashboardTitle = app.staticTexts["BuildTrack"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Tab Navigation
    
    func testTabBarNavigation() {
        // Login first
        loginDemoUser()
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        let tabs = ["Dashboard", "Projects", "Tasks", "Map", "Safety", "Team", "Alerts"]
        for tab in tabs {
            let button = tabBar.buttons[tab]
            if button.exists {
                button.tap()
                XCTAssertTrue(button.isSelected)
            }
        }
    }
    
    // MARK: - Project CRUD Flow
    
    func testCreateProjectFlow() {
        loginDemoUser()
        
        // Navigate to projects
        app.tabBars.buttons["Projects"].tap()
        
        // Tap add button
        let addButton = app.navigationBars.buttons["Add"]
        if addButton.exists {
            addButton.tap()
        }
        
        // Fill form
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("UI Test Project")
        }
        
        // Save
        let saveButton = app.navigationBars.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
        }
    }
    
    // MARK: - Task Completion Flow
    
    func testTaskCompletionFlow() {
        loginDemoUser()
        
        app.tabBars.buttons["Tasks"].tap()
        
        // Find first incomplete task and tap its checkbox
        let firstTask = app.cells.firstMatch
        if firstTask.waitForExistence(timeout: 5) {
            firstTask.tap()
        }
    }
    
    // MARK: - Safety Report Flow
    
    func testSafetyReportFlow() {
        loginDemoUser()
        
        app.tabBars.buttons["Safety"].tap()
        
        // Add incident
        let addButton = app.navigationBars.buttons["Add"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        }
        
        let titleField = app.textFields.firstMatch
        if titleField.waitForExistence(timeout: 3) {
            titleField.tap()
            titleField.typeText("UI Test Incident")
        }
        
        let reportButton = app.navigationBars.buttons["Report"]
        if reportButton.exists {
            reportButton.tap()
        }
    }
    
    // MARK: - Helpers
    
    private func loginDemoUser() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("demo@buildtrack.com")
            
            passwordField.tap()
            passwordField.typeText("DemoPass123!")
            
            app.buttons["Sign In"].tap()
        }
    }
}

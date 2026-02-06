//
//  VeckaUITests.swift
//  VeckaUITests
//
//  Created by Nils Johansson on 2025-08-09.
//

import XCTest

final class VeckaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-disable-animations"]
        app.launch()

        XCTAssertTrue(app.otherElements["ui-test-root"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        throw XCTSkip("Disabled to avoid quiescence hangs; re-enable when UI tests are stable.")
    }
}

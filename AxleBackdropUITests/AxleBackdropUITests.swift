//
//  AxleBackdropUITests.swift
//  AxleBackdropUITests
//
//  Created by RDcorp on 16.11.2026.
//

import XCTest

final class AxleBackdropUITests: XCTestCase {

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
    func testVehicleSelectionReachesPhotos() throws {
        let app = XCUIApplication()
        app.launch()

        if app.buttons["New Listing"].waitForExistence(timeout: 5) {
            app.buttons["New Listing"].tap()
        }
        XCTAssertTrue(app.staticTexts["Choose a vehicle"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Motorcycle'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Full left-side profile"].exists)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Photos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 of 5 photos"].exists)
        XCTAssertTrue(app.buttons["Choose from Library"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

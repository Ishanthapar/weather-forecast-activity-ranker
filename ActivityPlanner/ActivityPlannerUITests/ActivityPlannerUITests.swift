//
//  ActivityPlannerUITests.swift
//  ActivityPlannerUITests
//
//  Created by Ishan Thapar on 11/2/26.
//

import XCTest

final class ActivityPlannerUITests: XCTestCase {

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
    func testCitySearchAndForecastNavigation() throws {

        let app = XCUIApplication()

        app.launchArguments = [
            "--uitesting",
            "--ui-test-scenario=success"
        ]

        app.launch()

        // Verify the initial search screen.
        let searchField = app.textFields["citySearchField"]

        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5),
            "The city search field should be visible after launch."
        )

        // Search for Mumbai.
        searchField.tap()
        searchField.typeText("Mumbai")

        // Verify the Mumbai search result.
        let mumbaiResult = app.buttons["locationResult_1275339"]

        XCTAssertTrue(
            mumbaiResult.waitForExistence(timeout: 5),
            "The Mumbai search result should appear."
        )

        // Select Mumbai.
        mumbaiResult.tap()

        // Verify the selected destination.
        let forecastButton = app.buttons["viewForecastButton"]

        XCTAssertTrue(
            forecastButton.waitForExistence(timeout: 5),
            "The selected destination should display the forecast button."
        )

        // Navigate to the forecast screen.
        forecastButton.tap()

        // Verify that the forecast content loads.
        let forecastContent = app.descendants(matching: .any)
            .matching(identifier: "forecastContent")
            .firstMatch

        XCTAssertTrue(
            forecastContent.waitForExistence(timeout: 10),
            "The forecast content should appear after selecting Mumbai."
        )

        // Verify the seven-day forecast section.
        let forecastHeading = app.staticTexts["sevenDayForecastHeading"]

        XCTAssertTrue(
            forecastHeading.exists,
            "The seven-day forecast heading should be visible."
        )

        // Verify that at least one daily forecast row is rendered.
        let forecastDayRows = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "forecastDay_"
                )
            )

        XCTAssertTrue(
            forecastDayRows.firstMatch.waitForExistence(timeout: 5),
            "At least one daily forecast row should be displayed."
        )
    }


    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

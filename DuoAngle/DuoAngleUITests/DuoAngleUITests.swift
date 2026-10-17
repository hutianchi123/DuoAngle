//
//  DuoAngleUITests.swift
//  DuoAngleUITests
//
//  Created by 胡天驰 on 9/19/26.
//

import XCTest

final class DuoAngleUITests: XCTestCase {

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
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testBottomActionsPresentAndDismissSheets() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["设定角度"].tap()
        if !app.buttons["完成"].waitForExistence(timeout: 3) {
            app.buttons["设定角度"].tap()
        }
        XCTAssertTrue(app.staticTexts["暂无目标角度"].waitForExistence(timeout: 10))
        app.buttons["完成"].tap()

        app.buttons["支持开发"].tap()
        if !app.buttons["完成"].waitForExistence(timeout: 3) {
            app.buttons["支持开发"].tap()
        }
        XCTAssertTrue(app.staticTexts["Duo Angle 是一款专为 iPhone Duo 打造的极简角度测量工具。感谢你支持独立开发！"].waitForExistence(timeout: 10))
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["设定角度"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

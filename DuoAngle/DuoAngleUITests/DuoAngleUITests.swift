//
//  DuoAngleUITests.swift
//  DuoAngleUITests
//
//  Created by 胡天驰 on 9/19/26.
//

import XCTest

final class DuoAngleUITests: XCTestCase {

    private func isolatedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-targets")
        return app
    }

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
        let app = isolatedApp()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testBottomActionsPresentAndDismissSheets() throws {
        let app = isolatedApp()
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
        XCTAssertTrue(app.staticTexts["为热爱，创造更多可能。"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Duo Angle 诞生于一个简单的想法：\n让每一次折叠，都成为一次测量。"].exists)
        XCTAssertTrue(app.staticTexts["所有功能均可免费使用，\n支持完全出于自愿。"].exists)
        let purchaseButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "支持开发，价格")).firstMatch
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 10))
        purchaseButton.tap()
        XCTAssertTrue(app.buttons["感谢支持"].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["设定角度"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            isolatedApp().launch()
        }
    }

    @MainActor
    func testTargetManagementFlow() throws {
        let app = isolatedApp()
        app.launch()
        app.buttons["设定角度"].tap()
        XCTAssertTrue(app.staticTexts["暂无目标角度"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["点击右上角 + 添加目标角度"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", "添加角度")).count, 1)
        app.buttons["添加角度"].tap()
        XCTAssertTrue(app.staticTexts["新增角度"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["使用当前角度"].exists)
        app.buttons["保存"].tap()
        XCTAssertTrue(app.buttons["编辑 90 度"].waitForExistence(timeout: 5))
        let toggle = app.switches["启用 90 度目标角度"]
        XCTAssertTrue(toggle.exists)
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        app.buttons["编辑 90 度"].tap()
        XCTAssertTrue(app.staticTexts["编辑角度"].waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "91°")
        app.buttons["取消"].tap()
        XCTAssertTrue(app.buttons["编辑 90 度"].exists)
        app.buttons["编辑 90 度"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "91°")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.buttons["编辑 91 度"].waitForExistence(timeout: 5))
        app.cells.firstMatch.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["暂无目标角度"].waitForExistence(timeout: 5))
    }
}

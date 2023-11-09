import XCTest
import Foundation
import Starscream
@testable import TVCommanderKit

final class TVCommanderTests: XCTestCase {
    private let app = "App"
    private let ipAddress = ""
    private let authToken: String? = ""
    private var tv: TVCommander!
    private var mockDelegate: MockTVCommanderDelegate!

    override func setUpWithError() throws {
        continueAfterFailure = false
        tv = try TVCommander(tvIPAddress: ipAddress, appName: app, authToken: authToken)
        mockDelegate = .init()
        tv.delegate = mockDelegate
    }

    override func tearDown() {
        tv = nil
        mockDelegate = nil
    }

    func testIPAddressValidation() {
        XCTAssertTrue("192.168.0.1".isValidIPAddress)
        XCTAssertTrue("10.0.0.1".isValidIPAddress)
        XCTAssertFalse("256.256.256.256".isValidIPAddress)
        XCTAssertFalse("0.0".isValidIPAddress)
        XCTAssertFalse("".isValidIPAddress)
    }

    func testConnectAuthMuteUnmuteDisconnect() {
        // verify params
        XCTAssertFalse(ipAddress.isEmpty)
        // connect and auth
        let expectation1 = expectation(description: "connect and auth")
        expectation1.expectedFulfillmentCount = 2
        mockDelegate.onTVCommanderDidConnect = {
            expectation1.fulfill()
        }
        mockDelegate.onTVCommanderAuthStatusUpdate = { _ in
            expectation1.fulfill()
        }
        XCTAssertEqual(tv.authStatus, .none)
        tv.connectToTV()
        wait(for: [expectation1])
        XCTAssertEqual(tv.authStatus, .allowed)
        // mute & unmute
        let expectation2 = expectation(description: "mute and unmute")
        expectation2.expectedFulfillmentCount = 2
        mockDelegate.onTVCommanderRemoteCommand = {
            XCTAssertEqual($0.params.dataOfCmd, .mute)
            expectation2.fulfill()
        }
        tv.sendRemoteCommand(key: .mute)
        sleep(4)
        tv.sendRemoteCommand(key: .mute)
        wait(for: [expectation2])
        // disconnect
        let expectation3 = expectation(description: "disconnect")
        mockDelegate.onTVCommanderDidDisconnect = {
            expectation3.fulfill()
        }
        tv.disconnectFromTV()
        wait(for: [expectation3])
    }

    func testEnterTextOnYoutube() {
        let connectExpectation = expectation(description: "connect")
        let authExpectation = expectation(description: "auth")
        let writeExpectation = expectation(description: "write commands")
        let disconnectExpectation = expectation(description: "disconnect")
        // given
        let text = "text"
        let keyboard = TVKeyboardLayout.youtube
        writeExpectation.expectedFulfillmentCount = 17 // # of keys to enter "text"
        var written = [TVRemoteCommand.Params.ControlKey]()
        mockDelegate.onTVCommanderDidConnect = { connectExpectation.fulfill() }
        mockDelegate.onTVCommanderAuthStatusUpdate = { _ in authExpectation.fulfill() }
        mockDelegate.onTVCommanderRemoteCommand = {
            written.append($0.params.dataOfCmd)
            writeExpectation.fulfill()
        }
        mockDelegate.onTVCommanderDidDisconnect = { disconnectExpectation.fulfill() }
        // when
        tv.connectToTV()
        wait(for: [connectExpectation, authExpectation])
        // then
        XCTAssert(tv.isConnected)
        XCTAssertEqual(tv.authStatus, .allowed)
        // when
        tv.enterText(text, on: keyboard)
        wait(for: [writeExpectation])
        // then
        XCTAssertEqual(written, [
            // -> t
            .enter,
            // -> e
            .up, .up, .left, .enter,
            // -> x
            .down, .down, .down, .left, .left, .enter,
            // -> t
            .up, .right, .right, .right, .enter
        ])
        // when
        tv.disconnectFromTV()
        wait(for: [disconnectExpectation])
        // then
        XCTAssertFalse(tv.isConnected)
    }
}

private class MockTVCommanderDelegate: TVCommanderDelegate {
    var onTVCommanderDidConnect: (() -> Void)?
    var onTVCommanderDidDisconnect: (() -> Void)?
    var onTVCommanderAuthStatusUpdate: ((TVAuthStatus) -> Void)?
    var onTVCommanderRemoteCommand: ((TVRemoteCommand) -> Void)?
    var onTVCommanderError: ((Error?) -> Void)?

    func tvCommanderDidConnect(_ tvCommander: TVCommander) {
        onTVCommanderDidConnect?()
    }

    func tvCommanderDidDisconnect(_ tvCommander: TVCommander) {
        onTVCommanderDidDisconnect?()
    }

    func tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus) {
        onTVCommanderAuthStatusUpdate?(authStatus)
    }

    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand) {
        onTVCommanderRemoteCommand?(command)
    }

    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError) {
        onTVCommanderError?(error)
    }
}

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

    func testConnectAuthDisconnect() {
        let connectExpectation = expectation(description: "connect")
        let authExpectation = expectation(description: "get auth token")
        let disconnectExpectation = expectation(description: "disconnect")
        // given
        mockDelegate.onTVCommanderDidConnect = { connectExpectation.fulfill() }
        mockDelegate.onTVCommanderAuthStatusUpdate = { _ in authExpectation.fulfill() }
        mockDelegate.onTVCommanderDidDisconnect = { disconnectExpectation.fulfill() }
        // when
        tv.connectToTV()
        wait(for: [connectExpectation, authExpectation])
        // then
        XCTAssertEqual(tv.authStatus, .allowed)
        XCTAssertNotNil(tv.tvConfig.token)
        print("token - \(tv.tvConfig.token!)")
        // when
        tv.disconnectFromTV()
        wait(for: [disconnectExpectation])
        // then
        XCTAssertFalse(tv.isConnected)
    }

    func testMuteUnmute() {
        let connectExpectation = expectation(description: "connect")
        let authExpectation = expectation(description: "auth")
        let muteUnmuteExpectation = expectation(description: "mute and unmute")
        let disconnectExpectation = expectation(description: "disconnect")
        // given
        var written = [TVRemoteCommand]()
        muteUnmuteExpectation.expectedFulfillmentCount = 2 // mute then unmute
        mockDelegate.onTVCommanderDidConnect = { connectExpectation.fulfill() }
        mockDelegate.onTVCommanderAuthStatusUpdate = { _ in authExpectation.fulfill() }
        mockDelegate.onTVCommanderRemoteCommand = {
            written.append($0)
            muteUnmuteExpectation.fulfill()
        }
        mockDelegate.onTVCommanderDidDisconnect = { disconnectExpectation.fulfill() }
        // when
        XCTAssertFalse(ipAddress.isEmpty)
        XCTAssertEqual(tv.authStatus, .none)
        tv.connectToTV()
        wait(for: [connectExpectation, authExpectation])
        // then
        XCTAssert(tv.isConnected)
        XCTAssertEqual(tv.authStatus, .allowed)
        // when
        tv.sendRemoteCommand(key: .mute)
        sleep(4)
        tv.sendRemoteCommand(key: .mute)
        wait(for: [muteUnmuteExpectation])
        // then
        XCTAssertEqual(written.map(\.params.dataOfCmd), [.mute, .mute])
        // when
        tv.disconnectFromTV()
        wait(for: [disconnectExpectation])
        // then
        XCTAssertFalse(tv.isConnected)
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

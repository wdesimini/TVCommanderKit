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

    override func setUp() {
        continueAfterFailure = false
        tv = TVCommander(tvIPAddress: ipAddress, appName: app, authToken: authToken)
        mockDelegate = .init()
        tv.delegate = mockDelegate
    }

    override func tearDown() {
        tv = nil
        mockDelegate = nil
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

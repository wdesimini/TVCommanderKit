//
//  TVWebSocketHandlerTests.swift
//  
//
//  Created by Wilson Desimini on 4/17/24.
//

import XCTest
import Starscream
@testable import TVCommanderKit

final class TVWebSocketHandlerTests: XCTestCase {
    private var handler: TVWebSocketHandler!
    private var mockClient: MockWebSocketClient!
    private var delegate: MockTVWebSocketHandlerDelegate!

    override func setUp() {
        handler = TVWebSocketHandler()
        mockClient = MockWebSocketClient()
        delegate = MockTVWebSocketHandlerDelegate()
        handler.delegate = delegate
    }

    override func tearDown() {
        handler = nil
        mockClient = nil
        delegate = nil
    }

    func testWebSocketDidConnect() {
        handler.didReceive(event: .connected([:]), client: mockClient)
        XCTAssertTrue(delegate.didConnect)
    }

    func testWebSocketDidDisconnect() {
        handler.didReceive(event: .disconnected("", 0), client: mockClient)
        XCTAssertTrue(delegate.didDisconnect)
    }

    func testWebSocketCancelledTreatedAsDisconnect() {
        handler.didReceive(event: .cancelled, client: mockClient)
        XCTAssertTrue(delegate.didDisconnect)
    }

    func testReceiveTextWithValidNewAuthPacket() {
        let jsonString = """
        {"data":{"clients":[{"attributes":{"name":"VGVzdA=="},"connectTime":1713369027676,"deviceName":"VGVzdA==","id":"502e895e-251f-48ca-b786-0f83b20102c5","isHost":false}],"id":"502e895e-251f-48ca-b786-0f83b20102c5","token":"99999999"},"event":"ms.channel.connect"}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertEqual(delegate.lastAuthToken, "99999999")
        XCTAssertEqual(delegate.lastAuthStatus, .allowed)
    }

    func testReceiveTextWithValidRefreshedAuthPacket() {
        let jsonString = """
        {"data":{"clients":[{"attributes":{"name":"VGVzdA==","token":"99999999"},"connectTime":1713369027676,"deviceName":"VGVzdA==","id":"502e895e-251f-48ca-b786-0f83b20102c5","isHost":false}],"id":"502e895e-251f-48ca-b786-0f83b20102c5"},"event":"ms.channel.connect"}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertEqual(delegate.lastAuthToken, "99999999")
        XCTAssertEqual(delegate.lastAuthStatus, .allowed)
    }

    func testReceiveTextWithInvalidPacket() {
        let jsonString = "not json"
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertNotNil(delegate.lastError)
    }

    func testReceiveTextWithTimeoutPacket() {
        let jsonString = """
        {"event":"ms.channel.timeOut"}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertEqual(delegate.lastAuthStatus, TVAuthStatus.none)
    }

    func testReceiveTextWithUnauthorizedPacket() {
        let jsonString = """
        {"event":"ms.channel.unauthorized"}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertEqual(delegate.lastAuthStatus, .denied)
    }

    func testReceiveInvalidBinaryData() {
        let jsonData = Data()
        handler.didReceive(event: .binary(jsonData), client: mockClient)
        XCTAssertNotNil(delegate.lastError)
    }

    func testWebSocketError() {
        let error = NSError(domain: "Test", code: 1001, userInfo: nil)
        handler.didReceive(event: .error(error), client: mockClient)
        XCTAssertNotNil(delegate.lastError)
    }

    func testAuthResponseWithNoToken() {
        let jsonString = """
        {"event":"ms.channel.connect","data":{}}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertNotNil(delegate.lastError)
    }

    func testAuthResponseWithUnexpectedEvent() {
        let jsonString = """
        {"event":"unknownEvent"}
        """
        handler.didReceive(event: .text(jsonString), client: mockClient)
        XCTAssertNotNil(delegate.lastError)
    }
}

private class MockWebSocketClient: WebSocketClient {
    var lastSentText: String?
    var lastSentData: Data?

    func connect() {
    }

    func disconnect(closeCode: UInt16) {
    }

    func write(string: String, completion: (() -> ())?) {
        lastSentText = string
    }

    func write(stringData: Data, completion: (() -> ())?) {
        lastSentData = stringData
    }

    func write(data: Data, completion: (() -> ())?) {
        lastSentData = data
    }

    func write(ping: Data, completion: (() -> ())?) {
    }

    func write(pong: Data, completion: (() -> ())?) {
    }
}

private class MockTVWebSocketHandlerDelegate: TVWebSocketHandlerDelegate {
    var didConnect = false
    var didDisconnect = false
    var lastAuthStatus: TVAuthStatus?
    var lastAuthToken: String?
    var lastError: TVCommanderError?

    func webSocketDidConnect() {
        didConnect = true
    }

    func webSocketDidDisconnect() {
        didDisconnect = true
    }

    func webSocketDidReadAuthStatus(_ authStatus: TVAuthStatus) {
        lastAuthStatus = authStatus
    }

    func webSocketDidReadAuthToken(_ authToken: String) {
        lastAuthToken = authToken
    }

    func webSocketError(_ error: TVCommanderError) {
        lastError = error
    }
}

import XCTest
import Foundation
import Starscream
@testable import TVCommanderKit

final class TVCommanderTests: XCTestCase {
    private var engine: MockTVWebSocketEngine!
    private var tvCommander: TVCommander!
    private var delegate: MockTVCommanderDelegate!

    override func setUp() {
        continueAfterFailure = false
        engine = MockTVWebSocketEngine()
        delegate = MockTVCommanderDelegate()
        tvCommander = TVCommander(
            tvConfig: .init(
                id: "test-tv-id", app: "test-app",
                path: "/api/v2/channels/samsung.remote.control",
                ipAddress: "192.168.0.1", port: 8002,
                scheme: "wss", token: "123456"
            ),
            webSocketCreator: MockTVWebSocketCreator(engine: engine)
        )
        tvCommander.delegate = delegate
    }

    override func tearDown() {
        engine = nil
        tvCommander = nil
        delegate = nil
    }

    // MARK: Connects

    func test_connect_connected() {
        // given
        XCTAssertFalse(tvCommander.isConnected)
        XCTAssertNotNil(tvCommander.tvConfig.wssURL())
        // when
        let expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        // then
        XCTAssertTrue(tvCommander.isConnected)
    }

    func test_connect_alreadyConnected_error() {
        // given
        var expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        // when
        expectation = self.expectation(description: "error")
        var error: TVCommanderError?
        delegate.onTVCommanderError = {
            error = $0
            expectation.fulfill()
        }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        // then
        switch error {
        case .connectionAlreadyEstablished:
            break
        default:
            XCTFail()
        }
        XCTAssertTrue(tvCommander.isConnected)
    }

    // MARK: Connection Reads Packet

    func test_onPacket_valid_authStatusUpdated() {
        // given
        XCTAssertEqual(tvCommander.authStatus, .none)
        engine.mockReadPacket = #"{"data":{"clients":[{"attributes":{"name":"VGVzdA=="},"connectTime":1713369027676,"deviceName":"VGVzdA==","id":"502e895e-251f-48ca-b786-0f83b20102c5","isHost":false}],"id":"502e895e-251f-48ca-b786-0f83b20102c5","token":"99999999"},"event":"ms.channel.connect"}"#
        // when
        let expectation = expectation(description: "authorize")
        var authStatus: TVAuthStatus?
        delegate.onTVCommanderAuthStatusUpdate = {
            authStatus = $0
            expectation.fulfill()
        }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        // then
        XCTAssertEqual(tvCommander.authStatus, authStatus)
        XCTAssertEqual(authStatus, .allowed)
    }

    func test_onPacket_invalid_error() {
        // given
        engine.mockReadPacket = "asdf"
        // when
        let expectation = expectation(description: "error")
        var error: TVCommanderError?
        delegate.onTVCommanderError = {
            error = $0
            expectation.fulfill()
        }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        // then
        switch error {
        case .packetDataParsingFailed:
            break
        default:
            XCTFail()
        }
    }

    // MARK: Connection Writes Packets

    func test_sendCommand_notConnected_error() {
        // given
        XCTAssertFalse(tvCommander.isConnected)
        // when
        let expectation = expectation(description: "error")
        var error: TVCommanderError?
        delegate.onTVCommanderError = {
            error = $0
            expectation.fulfill()
        }
        tvCommander.sendRemoteCommand(key: .mute)
        wait(for: [expectation], timeout: 0.5)
        // then
        switch error {
        case .remoteCommandNotConnectedToTV:
            break
        default:
            XCTFail("wrong error received")
        }
    }

    func test_sendCommand_notAuthed_error() {
        // given
        var expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotEqual(tvCommander.authStatus, .allowed)
        // when
        expectation = self.expectation(description: "error")
        var error: TVCommanderError?
        delegate.onTVCommanderError = {
            error = $0
            expectation.fulfill()
        }
        tvCommander.sendRemoteCommand(key: .mute)
        wait(for: [expectation], timeout: 0.5)
        // then
        switch error {
        case .remoteCommandAuthenticationStatusNotAllowed:
            break
        default:
            XCTFail("wrong error received")
        }
    }

    func test_sendCommand_ideal_sent() {
        // given
        var expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        tvCommander.webSocketDidReadAuthStatus(.allowed)
        // when
        expectation = self.expectation(description: "send")
        var command: TVRemoteCommand?
        delegate.onTVCommanderRemoteCommand = {
            command = $0
            expectation.fulfill()
        }
        tvCommander.sendRemoteCommand(key: .mute)
        wait(for: [expectation], timeout: 0.5)
        // then
        XCTAssertEqual(command?.params.dataOfCmd, .mute)
    }

    func test_sendCommand_multipleCommands_sentInOrder() {
        // given
        var expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        tvCommander.webSocketDidReadAuthStatus(.allowed)
        // when
        let keys: [TVRemoteCommand.Params.ControlKey] = 
            [.menu, .up, .down, .down, .channelList, .enter, .mute]
        expectation = self.expectation(description: "sends")
        expectation.expectedFulfillmentCount = keys.count
        var keysSent = [TVRemoteCommand.Params.ControlKey]()
        delegate.onTVCommanderRemoteCommand = {
            keysSent.append($0.params.dataOfCmd)
            expectation.fulfill()
        }
        keys.forEach { tvCommander.sendRemoteCommand(key: $0) }
        wait(for: [expectation], timeout: 0.5)
        // then
        XCTAssertEqual(keys, keysSent)
    }

    // MARK: Disconnects

    func test_disconnect_connectedAuthed_disconnectedAndReset() throws {
        // given
        var expectation = expectation(description: "connect")
        delegate.onTVCommanderDidConnect = { expectation.fulfill() }
        tvCommander.connectToTV()
        wait(for: [expectation], timeout: 0.5)
        tvCommander.webSocketDidReadAuthStatus(.allowed)
        // when
        expectation = self.expectation(description: "disconnect")
        delegate.onTVCommanderDidDisconnect = { expectation.fulfill() }
        tvCommander.disconnectFromTV()
        wait(for: [expectation], timeout: 0.5)
        // then
        XCTAssertFalse(tvCommander.isConnected)
        XCTAssertEqual(tvCommander.authStatus, .none)
    }
}

// MARK: - Mock WebSocket Creator

private class MockTVWebSocketCreator: TVWebSocketCreator {
    private let engine: MockTVWebSocketEngine

    init(engine: MockTVWebSocketEngine) {
        self.engine = engine
    }

    override func createTVWebSocket(
        url: URL,
        certPinner: CertificatePinning?,
        delegate: WebSocketDelegate
    ) -> WebSocket {
        builder.setEngine(engine)
        return super.createTVWebSocket(
            url: url, certPinner: certPinner,
            delegate: delegate
        )
    }
}

// MARK: - Mock WebSocket Engine

private class MockTVWebSocketEngine: Engine {
    private weak var delegate: EngineDelegate?

    var mockReadDelay = TimeInterval(0)
    var mockReadPacket: String?
    private var mockRead: DispatchWorkItem?

    func register(delegate: EngineDelegate) {
        self.delegate = delegate
    }

    func start(request: URLRequest) {
        delegate?.didReceive(event: .connected([:]))
        guard let mockReadPacket else { return }
        mockRead?.cancel()
        let readWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.delegate?.didReceive(event: .text(mockReadPacket))
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + mockReadDelay, execute: readWorkItem)
        mockRead = readWorkItem
    }

    func stop(closeCode: UInt16) {
        mockRead?.cancel()
        delegate?.didReceive(event: .disconnected("", closeCode))
    }

    func forceStop() {
        stop(closeCode: 1006)
    }

    func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        completion?()
    }

    func write(string: String, completion: (() -> ())?) {
        completion?()
    }
}

// MARK: - Mock Delegate

private class MockTVCommanderDelegate: TVCommanderDelegate {
    var onTVCommanderDidConnect: (() -> Void)?
    var onTVCommanderDidDisconnect: (() -> Void)?
    var onTVCommanderAuthStatusUpdate: ((TVAuthStatus) -> Void)?
    var onTVCommanderRemoteCommand: ((TVRemoteCommand) -> Void)?
    var onTVCommanderError: ((TVCommanderError?) -> Void)?

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

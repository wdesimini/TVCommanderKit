//
//  TVCommander.swift
//
//
//  Created by Wilson Desimini on 9/3/23.
//

import Foundation
import Starscream

public protocol TVCommanderDelegate: AnyObject {
    func tvCommanderDidConnect(_ tvCommander: TVCommander)
    func tvCommanderDidDisconnect(_ tvCommander: TVCommander)
    func tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus)
    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand)
    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError)
}

public class TVCommander: WebSocketDelegate, CertificatePinning {
    public weak var delegate: TVCommanderDelegate?
    private(set) public var tvConfig: TVConnectionConfiguration
    private(set) public var authStatus = TVAuthStatus.none
    private(set) public var isConnected = false
    private var webSocket: WebSocket?
    private var commandQueue = [TVRemoteCommand]()

    public init(tvIPAddress: String, appName: String, authToken: TVAuthToken? = nil) throws {
        guard appName.isValidAppName else {
            throw TVCommanderError.invalidAppNameEntered
        }
        guard tvIPAddress.isValidIPAddress else {
            throw TVCommanderError.invalidIPAddressEntered
        }
        tvConfig = TVConnectionConfiguration(
            app: appName,
            path: "/api/v2/channels/samsung.remote.control",
            ipAddress: tvIPAddress,
            port: 8002,
            scheme: "wss",
            token: authToken
        )
    }

    // MARK: Establish WebSocket Connection

    public func connectToTV(certPinner: CertificatePinning? = nil) {
        guard !isConnected else {
            handleError(.connectionAlreadyEstablished)
            return
        }
        guard let url = buildTVURL() else {
            handleError(.urlConstructionFailed)
            return
        }
        setupWebSocket(with: url, certPinner: certPinner ?? self)
    }

    private func buildTVURL() -> URL? {
        var components = URLComponents()
        components.path = tvConfig.path
        components.host = tvConfig.ipAddress
        components.port = tvConfig.port
        components.scheme = tvConfig.scheme
        var queryItems = [URLQueryItem]()
        tvConfig.app.asBase64.flatMap { queryItems.append(.init(name: "name", value: $0)) }
        tvConfig.token.flatMap { queryItems.append(.init(name: "token", value: $0)) }
        components.queryItems = queryItems
        return components.url
    }

    private func setupWebSocket(with url: URL, certPinner: CertificatePinning) {
        let request = URLRequest(url: url)
        webSocket = WebSocket(request: request, certPinner: certPinner)
        webSocket?.respondToPingWithPong = true
        webSocket?.delegate = self
        webSocket?.connect()
    }

    // MARK: Interact with WebSocket

    public func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            handleWebSocketConnected()
        case .cancelled, .disconnected:
            handleWebSocketDisconnected()
        case .text(let text):
            handleWebSocketText(text)
        case .binary(let data):
            handleWebSocketBinary(data)
        case .error(let error):
            handleError(.webSocketError(error))
        default:
            break
        }
    }

    public func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        completion(.success)
    }

    private func handleWebSocketConnected() {
        isConnected = true
        delegate?.tvCommanderDidConnect(self)
    }

    private func handleWebSocketDisconnected() {
        isConnected = false
        authStatus = .none
        webSocket = nil
        delegate?.tvCommanderDidDisconnect(self)
    }

    private func handleWebSocketText(_ text: String) {
        if let packetData = text.asData {
            webSocketDidReadPacket(packetData)
        } else {
            handleError(.packetDataParsingFailed)
        }
    }

    private func handleWebSocketBinary(_ data: Data) {
        webSocketDidReadPacket(data)
    }

    private func webSocketDidReadPacket(_ packet: Data) {
        if let authResponse = parseAuthResponse(from: packet) {
            handleAuthResponse(authResponse)
        } else {
            handleError(.packetDataParsingFailed)
        }
    }

    // MARK: Receive Auth

    private func parseAuthResponse(from packet: Data) -> TVAuthResponse? {
        let decoder = JSONDecoder()
        let authResponseType = TVResponse<TVAuthResponseBody>.self
        return try? decoder.decode(authResponseType, from: packet)
    }

    private func handleAuthResponse(_ response: TVAuthResponse) {
        switch response.event {
        case .connect:
            handleAuthAllowed(response)
        case .unauthorized:
            handleAuthDenied(response)
        case .timeout:
            handleAuthCancelled(response)
        default:
            handleError(.authResponseUnexpectedChannelEvent(response))
        }
    }

    private func handleAuthAllowed(_ response: TVAuthResponse) {
        authStatus = .allowed
        delegate?.tvCommander(self, didUpdateAuthState: authStatus)
        if let newToken = response.data?.token {
            tvConfig.token = newToken
        } else if let refreshedToken = response.data?.clients.first(
            where: { $0.attributes.name == tvConfig.app.asBase64 })?.attributes.token {
            tvConfig.token = refreshedToken
        } else {
            handleError(.noTokenInAuthResponse(response))
        }
    }

    private func handleAuthDenied(_ response: TVAuthResponse) {
        authStatus = .denied
        delegate?.tvCommander(self, didUpdateAuthState: authStatus)
    }

    private func handleAuthCancelled(_ response: TVAuthResponse) {
        authStatus = .none
        delegate?.tvCommander(self, didUpdateAuthState: authStatus)
    }

    // MARK: Send Remote Control Commands

    public func sendRemoteCommand(key: TVRemoteCommand.Params.ControlKey) {
        guard isConnected else {
            handleError(.remoteCommandNotConnectedToTV)
            return
        }
        guard authStatus == .allowed else {
            handleError(.remoteCommandAuthenticationStatusNotAllowed)
            return
        }
        sendCommandOverWebSocket(createRemoteCommand(key: key))
    }

    private func createRemoteCommand(key: TVRemoteCommand.Params.ControlKey) -> TVRemoteCommand {
        let params = TVRemoteCommand.Params(cmd: .click, dataOfCmd: key, option: false, typeOfRemote: .remoteKey)
        return TVRemoteCommand(method: .control, params: params)
    }

    private func sendCommandOverWebSocket(_ command: TVRemoteCommand) {
        commandQueue.append(command)
        if commandQueue.count == 1 {
            sendNextQueuedCommandOverWebSocket()
        }
    }

    private func sendNextQueuedCommandOverWebSocket() {
        guard let command = commandQueue.first else {
            return
        }
        guard let commandStr = try? command.asString() else {
            handleError(.commandConversionToStringFailed)
            return
        }
        webSocket?.write(string: commandStr) { [weak self] in
            guard let self else { return }
            self.commandQueue.removeFirst()
            self.delegate?.tvCommander(self, didWriteRemoteCommand: command)
            self.sendNextQueuedCommandOverWebSocket()
        }
    }

    // MARK: Send Keyboard Commands

    public func enterText(_ text: String, on keyboard: TVKeyboardLayout) {
        let keys = controlKeys(toEnter: text, on: keyboard)
        keys.forEach(sendRemoteCommand(key:))
    }

    private func controlKeys(toEnter text: String, on keyboard: TVKeyboardLayout) -> [TVRemoteCommand.Params.ControlKey] {
        let chars = Array(text)
        var moves: [TVRemoteCommand.Params.ControlKey] = [.enter]
        for i in 0..<(chars.count - 1) {
            let currentChar = String(chars[i])
            let nextChar = String(chars[i + 1])
            if let movesToNext = controlKeys(toMoveFrom: currentChar, to: nextChar, on: keyboard) {
                moves.append(contentsOf: movesToNext)
                moves.append(.enter)
            } else {
                delegate?.tvCommander(self, didEncounterError: .keyboardCharNotFound(nextChar))
            }
        }
        return moves
    }

    private func controlKeys(toMoveFrom char1: String, to char2: String, on keyboard: TVKeyboardLayout) -> [TVRemoteCommand.Params.ControlKey]? {
        guard let (startRow, startCol) = coordinates(of: char1, on: keyboard),
              let (endRow, endCol) = coordinates(of: char2, on: keyboard) else {
            return nil
        }
        let rowDiff = endRow - startRow
        let colDiff = endCol - startCol
        var moves: [TVRemoteCommand.Params.ControlKey] = []
        if rowDiff > 0 {
            moves += Array(repeating: .down, count: rowDiff)
        } else if rowDiff < 0 {
            moves += Array(repeating: .up, count: abs(rowDiff))
        }
        if colDiff > 0 {
            moves += Array(repeating: .right, count: colDiff)
        } else if colDiff < 0 {
            moves += Array(repeating: .left, count: abs(colDiff))
        }
        return moves
    }

    private func coordinates(of char: String, on keyboard: TVKeyboardLayout) -> (Int, Int)? {
        for (row, rowChars) in keyboard.enumerated() {
            if let colIndex = rowChars.firstIndex(of: char) {
                return (row, colIndex)
            }
        }
        return nil
    }

    // MARK: Disconnect WebSocket Connection

    public func disconnectFromTV() {
        webSocket?.disconnect()
    }

    // MARK: Handler Errors

    private func handleError(_ error: TVCommanderError) {
        delegate?.tvCommander(self, didEncounterError: error)
    }
}

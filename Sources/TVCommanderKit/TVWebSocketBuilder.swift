//
//  TVWebSocketBuilder.swift
//  
//
//  Created by Wilson Desimini on 5/11/24.
//

import Foundation
import Starscream

class TVWebSocketBuilder {
    private var urlRequest: URLRequest?
    private var certPinner: CertificatePinning?
    private var engine: Engine?
    private var delegate: WebSocketDelegate?

    func setURLRequest(_ urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    func setCertPinner(_ certPinner: CertificatePinning) {
        self.certPinner = certPinner
    }
    
    func setEngine(_ engine: Engine) {
        self.engine = engine
    }

    func setDelegate(_ delegate: WebSocketDelegate) {
        self.delegate = delegate
    }
    
    func getWebSocket() -> WebSocket? {
        let webSocket = createWebSocket()
        resetBuilder()
        return webSocket
    }

    private func createWebSocket() -> WebSocket? {
        guard let urlRequest else { return nil }
        let webSocket: WebSocket =
            // prioritize using custom engine (for tests/mocks/etc)
            engine.flatMap { .init(request: urlRequest, engine: $0) }
            // otherwise, default to using cert pinner
            ?? .init(request: urlRequest, certPinner: certPinner)
        webSocket.delegate = delegate
        webSocket.respondToPingWithPong = true
        return webSocket
    }

    private func resetBuilder() {
        urlRequest = nil
        certPinner = nil
        engine = nil
        delegate = nil
    }
}

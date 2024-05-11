//
//  TVWebSocketCreator.swift
//  
//
//  Created by Wilson Desimini on 5/11/24.
//

import Foundation
import Starscream

class TVWebSocketCreator {
    let builder: TVWebSocketBuilder

    init(builder: TVWebSocketBuilder = .init()) {
        self.builder = builder
    }

    func createTVWebSocket(
        url: URL,
        certPinner: CertificatePinning?,
        delegate: WebSocketDelegate
    ) -> WebSocket {
        builder.setURLRequest(.init(url: url))
        builder.setCertPinner(certPinner ?? TVDefaultWebSocketCertPinner())
        builder.setDelegate(delegate)
        return builder.getWebSocket()!
    }
}

/// Default cert-pinning implementation that trusts all connections
private class TVDefaultWebSocketCertPinner: CertificatePinning {
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        completion(.success)
    }
}

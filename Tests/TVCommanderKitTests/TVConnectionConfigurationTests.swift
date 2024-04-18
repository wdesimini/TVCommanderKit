//
//  TVConnectionConfigurationTests.swift
//  
//
//  Created by Wilson Desimini on 4/17/24.
//

import XCTest
@testable import TVCommanderKit

final class TVConnectionConfigurationTests: XCTestCase {
    func testWSSURL_fromTVConnectionConfiguration() {
        // given
        let appName = "Test"
        let token = "1234567"
        let ipAddress = "192.168.0.1"
        // when
        let tvConfig = TVConnectionConfiguration(
            id: nil,
            app: appName,
            path: "/api/v2/channels/samsung.remote.control",
            ipAddress: ipAddress,
            port: 8002,
            scheme: "wss",
            token: token
        )
        // then
        XCTAssertEqual(tvConfig.wssURL(), URL(string: "wss://192.168.0.1:8002/api/v2/channels/samsung.remote.control?name=VGVzdA==&token=1234567"))
    }
}

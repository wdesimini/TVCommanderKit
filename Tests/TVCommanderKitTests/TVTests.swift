//
//  TVTests.swift
//  
//
//  Created by Wilson Desimini on 4/17/24.
//

import XCTest
@testable import TVCommanderKit

final class TVTests: XCTestCase {
    func testIPAddress_fromTVURL() {
        // given
        let httpURL = "http://192.168.0.1:8001/api/v2/"
        // when
        let tv = TV(id: "", name: "", type: "", uri: httpURL)
        // then
        XCTAssertEqual(tv.ipAddress, "192.168.0.1")
    }

    func testIPAddress_fromTVDeviceIP() {
        // given
        let device = TV.Device(ip: "192.168.0.1", tokenAuthSupport: "", wifiMac: "")
        // when
        let tv = TV(device: device, id: "", name: "", type: "", uri: "")
        // then
        XCTAssertEqual(tv.ipAddress, "192.168.0.1")
    }

    func testNoIPAddress_fromInvalidTVURL() {
        // when
        let tv = TV(id: "", name: "", type: "", uri: "")
        // then
        XCTAssertNil(tv.ipAddress)
    }
}

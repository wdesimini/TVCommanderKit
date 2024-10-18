//
//  TVCommanderKit+Extensions.swift
//  
//
//  Created by Wilson Desimini on 9/3/23.
//

import Foundation

// MARK: Data

extension Data {
    static func magicPacket(from device: TVWakeOnLANDevice) -> Data {
        var magicPacketRaw = [UInt8](repeating: 0xFF, count: 6)
        let macAddressData = device.mac.split(separator: ":").compactMap { UInt8($0, radix: 16) }
        for _ in 0..<16 { magicPacketRaw.append(contentsOf: macAddressData) }
        return Data(magicPacketRaw)
    }

    var asJSON: [String: Any]? {
        try? JSONSerialization.jsonObject(with: self) as? [String: Any]
    }

    var asString: String? {
        String(data: self, encoding: .utf8)
    }
}

// MARK: Dictionary

extension Dictionary {
    var asData: Data? {
        try? JSONSerialization.data(withJSONObject: self)
    }

    var asString: String? {
        asData?.asString
    }
}

// MARK: Encodable

extension Encodable {
    func asString(encoder: JSONEncoder = .init()) throws -> String? {
        try encoder.encode(self).asString
    }
}

// MARK: String

extension String {
    var isValidAppName: Bool {
        !isEmpty
    }

    var isValidIPAddress: Bool {
        let regex = #"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }

    var asBase64: String? {
        asData?.base64EncodedString()
    }

    var asData: Data? {
        data(using: .utf8)
    }

    var asJSON: [String: Any]? {
        asData.flatMap(\.asJSON)
    }
}

// MARK: TV

extension TV {
    var ipAddress: String? {
        if let httpURLHost = URLComponents(string: uri)?.host,
           httpURLHost.isValidIPAddress {
            return httpURLHost
        } else if let deviceIPAddress = device?.ip,
                  deviceIPAddress.isValidIPAddress {
            return deviceIPAddress
        }
        return nil
    }

    func addingDevice(_ device: TV.Device) -> TV {
        TV(
            device: device,
            id: id,
            isSupport: isSupport,
            name: name,
            remote: remote,
            type: type,
            uri: uri,
            version: version
        )
    }
}

// MARK: TVApp

extension TVApp {
    public static func allApps() -> [TVApp] {
        [
            espn(),
            hulu(),
            max(),
            netflix(),
            paramountPlus(),
            plutoTV(),
            primeVideo(),
            spotify(),
            youtube()
        ]
    }

    public static func espn() -> TVApp {
        TVApp(id: "3201708014618", name: "ESPN")
    }

    public static func hulu() -> TVApp {
        TVApp(id: "3201601007625", name: "Hulu")
    }

    public static func max() -> TVApp {
        TVApp(id: "3202301029760", name: "Max")
    }

    public static func netflix() -> TVApp {
        TVApp(id: "3201907018807", name: "Netflix")
    }

    public static func paramountPlus() -> TVApp {
        TVApp(id: "3201710014981", name: "Paramount +")
    }

    public static func plutoTV() -> TVApp {
        TVApp(id: "3201808016802", name: "Pluto TV")
    }

    public static func primeVideo() -> TVApp {
        TVApp(id: "3201910019365", name: "Prime Video")
    }

    public static func spotify() -> TVApp {
        TVApp(id: "3201606009684", name: "Spotify")
    }

    public static func youtube() -> TVApp {
        TVApp(id: "111299001912", name: "YouTube")
    }
}

// MARK: TVConnectionConfiguration

extension TVConnectionConfiguration {
    func wssURL() -> URL? {
        var components = URLComponents()
        components.path = path
        components.host = ipAddress
        components.port = port
        components.scheme = scheme
        var queryItems = [URLQueryItem]()
        app.asBase64.flatMap { queryItems.append(.init(name: "name", value: $0)) }
        token.flatMap { queryItems.append(.init(name: "token", value: $0)) }
        components.queryItems = queryItems
        return components.url?.removingPercentEncoding
    }
}

// MARK: TVKeyboardLayout

extension TVKeyboardLayout {
    public static var qwerty: Self {
        [
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["z", "x", "c", "v", "b", "n", "m"]
        ]
    }

    public static var youtube: Self {
        [
            ["a", "b", "c", "d", "e", "f", "g"],
            ["h", "i", "j", "k", "l", "m", "n"],
            ["o", "p", "q", "r", "s", "t", "u"],
            ["v", "w", "x", "y", "z", "-", "'"],
        ]
    }
}

// MARK: URL

extension URL {
    var removingPercentEncoding: URL? {
        absoluteString.removingPercentEncoding.flatMap(URL.init(string:))
    }
}


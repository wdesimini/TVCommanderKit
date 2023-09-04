//
//  TVCommanderKit+Extensions.swift
//  
//
//  Created by Wilson Desimini on 9/3/23.
//

import Foundation

// MARK: Data

extension Data {
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

// MARK: URL

extension URL {
    var removingPercentEncoding: URL? {
        absoluteString.removingPercentEncoding.flatMap(URL.init(string:))
    }
}


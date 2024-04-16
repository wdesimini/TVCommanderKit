//
//  MockURLProtocol.swift
//  
//
//  Created by Wilson Desimini on 4/16/24.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var mockURLs = [URL?: (error: Error?, data: Data?, response: HTTPURLResponse?)]()

    override class func canInit(with request: URLRequest) -> Bool {
        true // Handle all types of requests
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request // Required to be implemented here. Just return what is passed
    }

    override func startLoading() {
        if let url = request.url {
            if let (error, data, response) = Self.mockURLs[url] {
                if let responseStrong = response {
                    self.client?.urlProtocol(self, didReceive: responseStrong, cacheStoragePolicy: .notAllowed)
                }
                if let dataStrong = data {
                    self.client?.urlProtocol(self, didLoad: dataStrong)
                }
                if let errorStrong = error {
                    self.client?.urlProtocol(self, didFailWithError: errorStrong)
                }
            }
        }
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

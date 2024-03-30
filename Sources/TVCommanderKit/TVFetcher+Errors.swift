//
//  TVFetcher+Errors.swift
//  
//
//  Created by Wilson Desimini on 3/30/24.
//

import Foundation

public enum TVFetcherError: Error, Equatable {
    public static func == (lhs: TVFetcherError, rhs: TVFetcherError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.failedRequest(let error1, let response1), .failedRequest(let error2, let response2)):
            return "\(String(describing: error1)), \(String(describing: response1))" == "\(String(describing: error2)), \(String(describing: response2))"
        case (.unexpectedResponseBody(let data1), .unexpectedResponseBody(let data2)):
            return data1 == data2
        default:
            return false
        }
    }

    // invalid tv uri
    case invalidURL
    // http request failed or received failure response
    case failedRequest(Error?, HTTPURLResponse?)
    // unexpected response body returned
    case unexpectedResponseBody(Data)
}

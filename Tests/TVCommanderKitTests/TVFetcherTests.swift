//
//  TVFetcherTests.swift
//  
//
//  Created by Wilson Desimini on 3/30/24.
//

import XCTest
@testable import TVCommanderKit

final class TVFetcherTests: XCTestCase {
    private var tvFetcher: TVFetcher!
    private var tv: TV!
    private var responseData: Data!

    override func setUp() {
        super.setUp()
        tvFetcher = TVFetcher(session: .mock())
        tv = TV(
            id: "uuid:4B0307C2-919B-4613-889A-F2D52F8538BC",
            name: "Samsung Q7DAA 55 TV",
            remote: "1.0",
            type: "Samsung SmartTV",
            uri: "http://192.168.0.1:8001/api/v2/",
            version: "2.0.25"
        )
    }

    override func tearDown() {
        tvFetcher = nil
        tv = nil
        super.tearDown()
    }

    func testFetchDevice_Success() throws {
        // given
        let url = try XCTUnwrap(URL(string: tv.uri))
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let responseData = #"{"device":{"TokenAuthSupport":"true","wifiMac":"00:00:00:00:0A:AA"},"id":"uuid:4B0307C2-919B-4613-889A-F2D52F8538BC","name":"Samsung Q7DAA 55 TV","remote":"1.0","type":"Samsung SmartTV","uri":"http://192.168.0.1:8001/api/v2/","version":"2.0.25"}"#.data(using: .utf8)
        MockURLProtocol.expect(.init(data: responseData, response: response), for: url)
        // when
        let expectation = XCTestExpectation(description: "Fetch device success")
        tvFetcher.fetchDevice(for: tv) { result in
            // then
            switch result {
            case .success(let updatedTV):
                XCTAssertEqual(updatedTV.device?.tokenAuthSupport, "true")
                XCTAssertEqual(updatedTV.device?.wifiMac, "00:00:00:00:0A:AA")
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFetchDevice_InvalidURL() {
        // given
        tv = .init(id: tv.id, name: tv.name, type: tv.type, uri: "")
        // when
        let expectation = XCTestExpectation(description: "Fetch device invalid URL")
        tvFetcher.fetchDevice(for: tv) { result in
            // then
            switch result {
            case .success(_):
                XCTFail("Expected failure due to invalid URL, but got success")
            case .failure(let error):
                XCTAssertEqual(error, .invalidURL)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFetchDevice_FailedRequest() throws {
        // given
        let expectedError = NSError(domain: "SampleErrorDomain", code: 404, userInfo: nil)
        let url = try XCTUnwrap(URL(string: tv.uri))
        MockURLProtocol.expect(.init(error: expectedError), for: url)
        // when
        let expectation = XCTestExpectation(description: "Fetch device failed request")
        tvFetcher.fetchDevice(for: tv) { result in
            // then
            switch result {
            case .success(_):
                XCTFail("Expected failure due to failed request, but got success")
            case .failure(let fetchError):
                switch fetchError {
                case .failedRequest(let error, _):
                    XCTAssertEqual((error as NSError?)?.code, expectedError.code)
                    XCTAssertEqual((error as NSError?)?.domain, expectedError.domain)
                    // useInfo not compare/tested here - generated and filled in
                    // by native code somewhere between URLProtocol and URLSession handler
                default:
                    XCTFail("Expecting failed request error")
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFetchDevice_UnexpectedResponseBody() throws {
        // given
        let url = try XCTUnwrap(URL(string: tv.uri))
        let invalidResponseData = Data()
        let response = HTTPURLResponse(
            url: URL(string: tv.uri)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.expect(.init(data: invalidResponseData, response: response), for: url)
        // when
        let expectation = XCTestExpectation(description: "Fetch device unexpected response body")
        tvFetcher.fetchDevice(for: tv) { result in
            // then
            switch result {
            case .success(_):
                XCTFail("Expected failure due to unexpected response body, but got success")
            case .failure(let error):
                XCTAssertEqual(error, .unexpectedResponseBody(invalidResponseData))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

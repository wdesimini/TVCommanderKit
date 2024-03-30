//
//  TVFetcherTests.swift
//  
//
//  Created by Wilson Desimini on 3/30/24.
//

import XCTest
@testable import TVCommanderKit

private class MockURLSession: URLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    override func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let data = data
        let response = response
        let error = error
        return MockURLSessionDataTask {
            completionHandler(data, response, error)
        }
    }
}

private class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

final class TVFetcherTests: XCTestCase {
    private var tvFetcher: TVFetcher!
    private var mockSession: MockURLSession!
    private var tv: TV!
    private var responseData: Data!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        tvFetcher = TVFetcher(session: mockSession)
        tv = TV(
            id: "uuid:4B0307C2-919B-4613-889A-F2D52F8538BC",
            name: "Samsung Q7DAA 55 TV",
            remote: "1.0",
            type: "Samsung SmartTV",
            uri: "http://192.168.0.1:8001/api/v2/",
            version: "2.0.25"
        )
        responseData = """
            {
                "device": {
                    "TokenAuthSupport": "true",
                    "wifiMac": "00:00:00:00:0A:AA"
                },
                "id": "uuid:4B0307C2-919B-4613-889A-F2D52F8538BC",
                "name": "Samsung Q7DAA 55 TV",
                "remote": "1.0",
                "type": "Samsung SmartTV",
                "uri": "http://192.168.0.1:8001/api/v2/",
                "version": "2.0.25"
            }
            """.data(using: .utf8)
    }

    override func tearDown() {
        tvFetcher = nil
        mockSession = nil
        tv = nil
        responseData = nil
        super.tearDown()
    }

    func testFetchDevice_Success() {
        // given
        let expectation = XCTestExpectation(description: "Fetch device success")
        mockSession.data = responseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: tv.uri)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        // when
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
        let expectation = XCTestExpectation(description: "Fetch device invalid URL")
        tv = .init(id: tv.id, name: tv.name, type: tv.type, uri: "")
        // when
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

    func testFetchDevice_FailedRequest() {
        // given
        let expectation = XCTestExpectation(description: "Fetch device failed request")
        let error = NSError(domain: "SampleErrorDomain", code: 404, userInfo: nil)
        mockSession.error = error
        // when
        tvFetcher.fetchDevice(for: tv) { result in
            // then
            switch result {
            case .success(_):
                XCTFail("Expected failure due to failed request, but got success")
            case .failure(let fetchError):
                XCTAssertEqual(fetchError, .failedRequest(error, nil))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFetchDevice_UnexpectedResponseBody() {
        // given
        let expectation = XCTestExpectation(description: "Fetch device unexpected response body")
        let invalidResponseData = Data()
        mockSession.data = invalidResponseData
        mockSession.response = HTTPURLResponse(
            url: URL(string: tv.uri)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        // when
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

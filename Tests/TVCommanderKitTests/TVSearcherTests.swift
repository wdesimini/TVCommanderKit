//
//  TVSearcherTests.swift
//
//
//  Created by Wilson Desimini on 4/14/24.
//

import XCTest
@testable import TVCommanderKit

final class TVSearcherTests: XCTestCase {
    private var service: TVSearching!
    private var mockRemote: MockTVSearchRemoteInterface!
    private var mockObserver: MockTVSearchObserver!

    override func setUp() {
        mockRemote = MockTVSearchRemoteInterface()
        mockObserver = MockTVSearchObserver()
        service = TVSearcher(remote: mockRemote)
        service.addSearchObserver(mockObserver)
    }

    override func tearDown() {
        service.removeAllSearchObservers()
        service = nil
        mockRemote = nil
        mockObserver = nil
    }

    private func mockTV() -> TV {
        .init(
            id: "uuid:\(UUID().uuidString)",
            name: "Samsung TV",
            type: "Type of Samsung TV",
            uri: "http://192.168.0.1:8001/api/v2/"
        )
    }

    func testStartSearch_notifiesObserver() {
        service.startSearch()
        XCTAssertTrue(mockObserver.didStartSearch)
    }

    func testStopSearch_notifiesObserver() {
        service.stopSearch()
        XCTAssertTrue(mockObserver.didStopSearch)
    }

    func testFindTV_notifiesObserver() {
        let expectedTV = mockTV()
        mockRemote.findTV = expectedTV
        mockObserver.expectTV = expectedTV
        service.startSearch()
        XCTAssertTrue(mockObserver.didFindTV)
        XCTAssertEqual(mockObserver.foundTV?.id, expectedTV.id)
    }

    func testLoseTV_notifiesObserver() {
        let expectedTV = mockTV()
        mockRemote.loseTV = expectedTV
        mockObserver.expectTV = expectedTV
        service.startSearch()
        XCTAssertTrue(mockObserver.didLoseTV)
        XCTAssertEqual(mockObserver.lostTV?.id, expectedTV.id)
    }

    func testConfigureTargetAndFindTV_notifiesObserverAndStopsSearch() {
        let expectedTV = mockTV()
        mockRemote.findTV = expectedTV
        service.configureTargetTVId(expectedTV.id)
        service.startSearch()
        XCTAssertTrue(mockObserver.didStartSearch)
        XCTAssertTrue(mockObserver.didStopSearch)
    }

    func testConfigureTargetAndFindOtherTV_notifiesObserverAndContinuesSearch() {
        let targetTV = mockTV()
        let otherTV = mockTV()
        mockRemote.findTV = otherTV
        service.configureTargetTVId(targetTV.id)
        service.startSearch()
        XCTAssertTrue(mockObserver.didStartSearch)
        XCTAssertFalse(mockObserver.didStopSearch)
    }

    func testMultipleObservers_notified() {
        let anotherObserver = MockTVSearchObserver()
        service.addSearchObserver(anotherObserver)
        service.startSearch()
        XCTAssertTrue(mockObserver.didStartSearch)
        XCTAssertTrue(anotherObserver.didStartSearch)
        service.stopSearch()
        XCTAssertTrue(mockObserver.didStopSearch)
        XCTAssertTrue(anotherObserver.didStopSearch)
        service.removeSearchObserver(anotherObserver)
    }

    func testRemoveObserver_notNotified() {
        service.removeSearchObserver(mockObserver)
        service.startSearch()
        XCTAssertFalse(mockObserver.didStartSearch)
    }
}

private class MockTVSearchRemoteInterface: TVSearchRemoteInterfacing {
    private weak var delegate: TVSearchObserving!
    var findTV: TV?
    var loseTV: TV?

    func setDelegate(_ observer: any TVSearchObserving) {
        self.delegate = observer
    }

    func startSearch() {
        delegate.tvSearchDidStart()
        findTV.flatMap { delegate.tvSearchDidFindTV($0) }
        loseTV.flatMap { delegate.tvSearchDidLoseTV($0) }
    }

    func stopSearch() {
        delegate.tvSearchDidStop()
    }
}

private class MockTVSearchObserver: TVSearchObserving {
    var didStartSearch = false
    var didStopSearch = false
    var didFindTV = false
    var didLoseTV = false
    var foundTV: TV?
    var lostTV: TV?
    var expectTV: TV?

    func tvSearchDidStart() {
        didStartSearch = true
    }

    func tvSearchDidStop() {
        didStopSearch = true
    }

    func tvSearchDidFindTV(_ tv: TV) {
        if let expectTV, expectTV.id == tv.id {
            foundTV = tv
            didFindTV = true
        }
    }

    func tvSearchDidLoseTV(_ tv: TV) {
        if let expectTV, expectTV.id == tv.id {
            lostTV = tv
            didLoseTV = true
        }
    }
}

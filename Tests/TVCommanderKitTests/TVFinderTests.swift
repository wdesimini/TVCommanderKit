//
//  TVFinderTests.swift
//  
//
//  Created by Wilson Desimini on 1/12/24.
//

import XCTest
import SmartView
import Starscream
@testable import TVCommanderKit

final class TVFinderTests: XCTestCase {
    private var finder: TVFinder!
    private var delegate: TVFinderDelegateMock!

    override func setUp() {
        continueAfterFailure = false
        delegate = TVFinderDelegateMock()
        finder = TVFinder(delegate: delegate)
    }

    override func tearDown() {
        delegate = nil
        finder = nil
    }

    func testFindTVs() throws {
        // when
        let expectation = expectation(description: "find tvs")
        delegate.onSearchEnded = { expectation.fulfill() }
        finder.findTVs()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.finder.stopFindingTVs()
        }
        wait(for: [expectation])
        // then
        XCTAssertFalse(delegate.tvsFound.isEmpty)
    }

    func testFindSpecificTV() {
        // given
        let id = ""
        XCTAssertFalse(id.isEmpty)
        // when
        let expectation = expectation(description: "find my tv")
        delegate.onSearchEnded = { expectation.fulfill() }
        finder.findTVs(id: id)
        wait(for: [expectation], timeout: 10)
        // then
        XCTAssertFalse(finder.isSearching)
        XCTAssertNil(finder.tvIdToFind)
        XCTAssertEqual(delegate.tvsFound.count, 1)
        XCTAssertEqual(delegate.tvsFound[0].id, id)
    }
}

class TVFinderDelegateMock: TVFinderDelegate {
    private(set) var tvsFound = [TV]()
    var onSearchEnded: (() -> Void)?

    func tvFinder(_ tvFinder: TVFinder, searchStateDidUpdate isSearching: Bool) {
        if !isSearching { onSearchEnded?() }
    }

    func tvFinder(_ tvFinder: TVFinder, didFind tvs: [TV]) {
        tvsFound = tvs
    }
}

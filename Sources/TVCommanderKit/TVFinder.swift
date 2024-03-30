//
//  TVFinder.swift
//
//
//  Created by Wilson Desimini on 1/12/24.
//

import Foundation
import SmartView

public protocol TVFinderDelegate: AnyObject {
    func tvFinder(_ tvFinder: TVFinder, searchStateDidUpdate isSearching: Bool)
    func tvFinder(_ tvFinder: TVFinder, didFind tvs: [TV])
}

public class TVFinder {
    private var search: TVSearcher!
    private unowned let delegate: TVFinderDelegate
    public private(set) var isSearching = false
    public private(set) var tvIdToFind: String?

    public init(delegate: TVFinderDelegate) {
        self.delegate = delegate
        self.search = TVSearcher(
            onSearchingStateUpdate: { [weak self] in
                self?.onSearchState($0)
            },
            onFoundServicesUpdate: { [weak self] in
                self?.onServicesFound($0)
            }
        )
    }

    // MARK: Find TVs

    public func findTVs(id: String? = nil) {
        guard !isSearching else { return }
        tvIdToFind = id
        search.search.start()
    }

    public func stopFindingTVs() {
        tvIdToFind = nil
        search.search.stop()
    }

    // MARK: Handle Search Updates

    private func onSearchState(_ isSearching: Bool) {
        self.isSearching = isSearching
        delegate.tvFinder(self, searchStateDidUpdate: isSearching)
    }

    private func onServicesFound(_ services: [Service]) {
        // convert services found
        let tvs: [TV] = services.map {
            TV(id: $0.id, name: $0.name, type: $0.type, uri: $0.uri)
        }
        delegate.tvFinder(self, didFind: tvs)
        // stop search if tv to find was found
        if let tvIdToFind, tvs.contains(where: { $0.id == tvIdToFind }) {
            stopFindingTVs()
        }
    }
}

fileprivate class TVSearcher: ServiceSearchDelegate {
    let search: ServiceSearch
    let onSearchingStateUpdate: (Bool) -> Void
    let onFoundServicesUpdate: ([Service]) -> Void

    init(
        onSearchingStateUpdate: @escaping (Bool) -> Void,
        onFoundServicesUpdate: @escaping ([Service]) -> Void
    ) {
        self.search = Service.search()
        self.onSearchingStateUpdate = onSearchingStateUpdate
        self.onFoundServicesUpdate = onFoundServicesUpdate
        self.search.delegate = self
    }

    func onStart() {
        onSearchingStateUpdate(true)
    }

    func onStop() {
        onSearchingStateUpdate(false)
    }

    func onServiceFound(_ service: Service) {
        onFoundServicesUpdate(search.getServices())
    }

    func onServiceLost(_ service: Service) {
        onFoundServicesUpdate(search.getServices())
    }
}

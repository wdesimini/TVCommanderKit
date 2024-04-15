//
//  TVSearcher.swift
//
//
//  Created by Wilson Desimini on 4/14/24.
//

import Foundation
import SmartView

public protocol TVSearching: AnyObject {
    func addSearchObserver(_ observer: any TVSearchObserving)
    func removeSearchObserver(_ observer: any TVSearchObserving)
    func removeAllSearchObservers()
    func configureTargetTVId(_ targetTVId: TV.ID?)
    func startSearch()
    func stopSearch()
}

public protocol TVSearchRemoteInterfacing: AnyObject {
    func setDelegate(_ observer: TVSearchObserving)
    func startSearch()
    func stopSearch()
}

public protocol TVSearchObserving: AnyObject {
    func tvSearchDidStart()
    func tvSearchDidStop()
    func tvSearchDidFindTV(_ tv: TV)
    func tvSearchDidLoseTV(_ tv: TV)
}

public class TVSearcher: TVSearching, TVSearchObserving {
    private let remote: TVSearchRemoteInterfacing
    private var observers = [TVSearchObserving]()
    private var targetTVId: TV.ID?

    public init(remote: TVSearchRemoteInterfacing? = nil) {
        self.remote = remote ?? TVSearchAdaptor()
        self.remote.setDelegate(self)
    }

    // MARK: Add / Remove Observers

    public func addSearchObserver(_ observer: any TVSearchObserving) {
        observers.append(observer)
    }

    public func removeSearchObserver(_ observer: any TVSearchObserving) {
        observers.removeAll { $0 === observer }
    }

    public func removeAllSearchObservers() {
        observers.removeAll()
    }

    // MARK: Search for TVs

    public func configureTargetTVId(_ targetTVId: TV.ID?) {
        self.targetTVId = targetTVId
    }

    public func startSearch() {
        remote.startSearch()
    }

    public func stopSearch() {
        remote.stopSearch()
    }

    public func tvSearchDidStart() {
        observers.forEach {
            $0.tvSearchDidStart()
        }
    }

    public func tvSearchDidStop() {
        observers.forEach {
            $0.tvSearchDidStop()
        }
    }

    public func tvSearchDidFindTV(_ tv: TV) {
        observers.forEach {
            $0.tvSearchDidFindTV(tv)
        }
        if tv.id == targetTVId {
            stopSearch()
        }
    }

    public func tvSearchDidLoseTV(_ tv: TV) {
        observers.forEach {
            $0.tvSearchDidLoseTV(tv)
        }
    }
}

class TVSearchAdaptor: TVSearchRemoteInterfacing, ServiceSearchDelegate {
    private let search: ServiceSearch
    private weak var delegate: TVSearchObserving?

    init() {
        self.search = Service.search()
        self.search.delegate = self
    }

    func setDelegate(_ observer: any TVSearchObserving) {
        self.delegate = observer
    }

    func startSearch() {
        search.start()
    }

    func stopSearch() {
        search.stop()
    }

    func onStart() {
        delegate?.tvSearchDidStart()
    }

    func onStop() {
        delegate?.tvSearchDidStop()
    }

    func onServiceFound(_ service: Service) {
        delegate?.tvSearchDidFindTV(.init(service: service))
    }

    func onServiceLost(_ service: Service) {
        delegate?.tvSearchDidLoseTV(.init(service: service))
    }
}

extension TV {
    init(service: Service) {
        self.init(
            id: service.id,
            name: service.name,
            type: service.type,
            uri: service.uri
        )
    }
}

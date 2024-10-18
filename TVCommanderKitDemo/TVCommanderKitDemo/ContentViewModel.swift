//
//  ContentViewModel.swift
//  TVCommanderKitDemo
//
//  Created by Wilson Desimini on 10/24/23.
//

import Foundation
import TVCommanderKit

@Observable
class ContentViewModel: TVCommanderDelegate, TVSearchObserving {

    // MARK: State

    var appName = "sample_app"
    var tvIPAddress = ""
    var tvAuthToken: TVAuthToken?
    var tvWakeOnLANDevice = TVWakeOnLANDevice(mac: "")
    var remoteCommandKeySelected = TVRemoteCommand.Params.ControlKey.mute
    var keyboardSelected = "qwerty"
    var keyboardEntry = ""
    var tvApp: TVApp = .netflix()
    var tvAppStatus: TVAppStatus?
    private(set) var tvIsConnecting = false
    private(set) var tvIsConnected = false
    private(set) var tvIsDisconnecting = false
    private(set) var tvIsWakingOnLAN = false
    private(set) var isSearchingForTVs = false
    private(set) var tvsFoundInSearch = [TV]()
    private(set) var tvAuthStatus = TVAuthStatus.none
    private(set) var tvError: Error?
    private var tvCommander: TVCommander?
    private let tvAppManager: TVAppManaging
    private let tvSearcher: TVSearcher

    init() {
        tvAppManager = TVAppManager()
        tvSearcher = TVSearcher()
        tvSearcher.addSearchObserver(self)
    }

    var connectEnabled: Bool {
        !tvIsConnecting && !tvIsConnected
    }

    var authTokenEntryDisabled: Bool {
        tvCommander != nil
        || tvIsConnecting
        || tvIsConnected
        || tvIsDisconnecting
    }

    var controlsEnabled: Bool {
        tvIsConnected && tvAuthStatus == .allowed
    }

    var keyboardSendEnabled: Bool {
        controlsEnabled && !keyboardEntry.isEmpty
    }

    var disconnectEnabled: Bool {
        tvIsConnected
    }

    var wakeOnLANEnabled: Bool {
        !tvIsWakingOnLAN
    }

    var keyboards: [String] { ["qwerty", "youtube"] }

    var remoteCommandKeys: [TVRemoteCommand.Params.ControlKey] {
        [
            .powerOff,
            .up,
            .down,
            .left,
            .right,
            .enter,
            .returnKey,
            .channelList,
            .menu,
            .source,
            .guide,
            .tools,
            .info,
            .colorRed,
            .colorGreen,
            .colorYellow,
            .colorBlue,
            .key3D,
            .volumeUp,
            .volumeDown,
            .mute,
            .number0,
            .number1,
            .number2,
            .number3,
            .number4,
            .number5,
            .number6,
            .number7,
            .number8,
            .number9,
            .sourceTV,
            .sourceHDMI,
            .contents,
        ]
    }

    var tvApps: [TVApp] {
        TVApp.allApps()
    }

    // MARK: User Actions

    func userTappedConnect() {
        setupTVCommander()
        guard let tvCommander else { return }
        tvIsConnecting = true
        tvCommander.connectToTV()
    }

    func userTappedDismissError() {
        tvError = nil
    }

    func userTappedSend() {
        tvCommander?.sendRemoteCommand(key: remoteCommandKeySelected)
    }

    func userTappedKeyboardSend() {
        switch keyboardSelected {
        case "youtube":
            tvCommander?.enterText(keyboardEntry, on: .youtube)
        case "qwerty":
            tvCommander?.enterText(keyboardEntry, on: .qwerty)
        default:
            fatalError()
        }
    }

    func userTappedDisconnect() {
        tvIsDisconnecting = true
        tvCommander?.disconnectFromTV()
    }

    func userTappedWakeOnLAN() {
        tvIsWakingOnLAN = true
        TVCommander.wakeOnLAN(device: tvWakeOnLANDevice, queue: .main) {
            [weak self] error in
            self?.tvIsWakingOnLAN = false
            self?.tvError = error
        }
    }

    func userTappedSearchForTVs() {
        if isSearchingForTVs {
            tvSearcher.stopSearch()
        } else {
            tvSearcher.startSearch()
        }
    }

    func userTappedAppStatus() {
        Task {
            await fetchAppStatus()
        }
    }

    func userTappedLaunchApp() {
        Task {
            await launchApp()
        }
    }

    // MARK: Lifecycle

    private func setupTVCommander() {
        guard tvCommander == nil else { return }
        do {
            tvCommander = try TVCommander(
                tvIPAddress: tvIPAddress,
                appName: appName,
                authToken: tvAuthToken
            )
            tvCommander?.delegate = self
        } catch {
            tvError = error
        }
    }

    private func removeTVCommander() {
        tvCommander = nil
    }

    private func fetchAppStatus() async {
        do {
            tvAppStatus = try await tvAppManager.fetchStatus(for: tvApp, tvIPAddress: tvIPAddress)
        } catch {
            tvError = error
        }
    }

    private func launchApp() async {
        do {
            try await tvAppManager.launch(tvApp: tvApp, tvIPAddress: tvIPAddress)
        } catch {
            tvError = error
        }
    }

    // MARK: TVCommanderDelegate

    func tvCommanderDidConnect(_ tvCommander: TVCommander) {
        tvIsConnecting = false
        tvIsConnected = true
    }

    func tvCommanderDidDisconnect(_ tvCommander: TVCommander) {
        tvIsDisconnecting = false
        tvIsConnected = false
        removeTVCommander()
    }

    func tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus) {
        tvAuthStatus = authStatus
        tvAuthToken = tvCommander.tvConfig.token
    }

    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand) {
    }

    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError) {
        tvError = error
    }

    // MARK: TVSearchObserving

    func tvSearchDidStart() {
        isSearchingForTVs = true
    }

    func tvSearchDidStop() {
        tvsFoundInSearch.removeAll()
        isSearchingForTVs = false
    }

    func tvSearchDidFindTV(_ tv: TV) {
        if !tvsFoundInSearch.contains(tv) {
            tvsFoundInSearch.append(tv)
        }
    }

    func tvSearchDidLoseTV(_ tv: TV) {
        tvsFoundInSearch.removeAll { $0.id == tv.id }
    }
}

@Observable
class TVViewModel {
    private let tvFetcher = TVFetcher()
    private(set) var tv: TV

    init(tv: TV) {
        self.tv = tv
    }

    func fetchTVDevice() {
        tvFetcher.fetchDevice(for: tv) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let tvFetched):
                    self.tv = tvFetched
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    func cancelFetch() {
        tvFetcher.cancelFetch()
    }
}

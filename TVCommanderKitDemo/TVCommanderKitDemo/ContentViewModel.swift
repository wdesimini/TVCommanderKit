//
//  ContentViewModel.swift
//  TVCommanderKitDemo
//
//  Created by Wilson Desimini on 10/24/23.
//

import Foundation
import TVCommanderKit

class ContentViewModel: ObservableObject, TVCommanderDelegate {

    // MARK: State

    @Published var appName = "sample_app"
    @Published var tvIPAddress = ""
    @Published private(set) var tvIsConnecting = false
    @Published private(set) var tvIsConnected = false
    @Published private(set) var tvIsDisconnecting = false
    @Published private(set) var tvAuthStatus = TVAuthStatus.none
    @Published private(set) var tvError: Error?
    private var tvCommander: TVCommander?

    var connectEnabled: Bool {
        !tvIsConnecting && !tvIsConnected
    }

    var controlsEnabled: Bool {
        tvIsConnected && tvAuthStatus == .allowed
    }

    var disconnectEnabled: Bool {
        tvIsConnected
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

    func userTappedMute() {
        tvCommander?.sendRemoteCommand(key: .mute)
    }

    func userTappedDisconnect() {
        tvIsDisconnecting = true
        tvCommander?.disconnectFromTV()
    }

    // MARK: Lifecycle

    private func setupTVCommander() {
        guard tvCommander == nil else { return }
        do {
            tvCommander = try TVCommander(tvIPAddress: tvIPAddress, appName: appName)
            tvCommander?.delegate = self
        } catch {
            tvError = error
        }
    }

    private func removeTVCommander() {
        tvCommander = nil
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
    }

    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand) {
    }

    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError) {
        tvError = error
    }
}

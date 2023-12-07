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
    @Published var tvWakeOnLANDevice = TVWakeOnLANDevice(mac: "")
    @Published var remoteCommandKeySelected = TVRemoteCommand.Params.ControlKey.mute
    @Published var keyboardSelected = "qwerty"
    @Published var keyboardEntry = ""
    @Published private(set) var tvIsConnecting = false
    @Published private(set) var tvIsConnected = false
    @Published private(set) var tvIsDisconnecting = false
    @Published private(set) var tvIsWakingOnLAN = false
    @Published private(set) var tvAuthStatus = TVAuthStatus.none
    @Published private(set) var tvError: Error?
    private var tvCommander: TVCommander?

    var connectEnabled: Bool {
        !tvIsConnecting && !tvIsConnected
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

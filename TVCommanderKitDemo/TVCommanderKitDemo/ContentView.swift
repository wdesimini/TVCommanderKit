//
//  ContentView.swift
//  TVCommanderKitDemo
//
//  Created by Wilson Desimini on 10/24/23.
//

import SwiftUI
import TVCommanderKit

struct ContentView: View {
    @StateObject var contentViewModel = ContentViewModel()
    @State private var isPresentingError = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TV Settings")) {
                    TextField("App Name", text: $contentViewModel.appName)
                    TextField("TV IP Address", text: $contentViewModel.tvIPAddress)
                }
                Section(header: Text("Connection Status")) {
                    HStack {
                        Text("Connected:")
                        Spacer()
                        Text(contentViewModel.tvIsConnected ? "Yes" : "No")
                    }
                    HStack {
                        Text("Connecting:")
                        Spacer()
                        Text(contentViewModel.tvIsConnecting ? "Yes" : "No")
                    }
                    HStack {
                        Text("Disconnecting:")
                        Spacer()
                        Text(contentViewModel.tvIsDisconnecting ? "Yes" : "No")
                    }
                    HStack {
                        Text("Auth Status")
                        Spacer()
                        Text(authStatusAsText(contentViewModel.tvAuthStatus))
                    }
                    HStack {
                        Text("Waking On LAN")
                        Spacer()
                        Text(contentViewModel.tvIsWakingOnLAN ? "Yes" : "No")
                    }
                }
                Section(header: Text("Actions")) {
                    Button("Connect") {
                        contentViewModel.userTappedConnect()
                    }
                    .disabled(!contentViewModel.connectEnabled)
                    Button("Mute") {
                        contentViewModel.userTappedMute()
                    }
                    .disabled(!contentViewModel.controlsEnabled)
                    Button("Disconnect") {
                        contentViewModel.userTappedDisconnect()
                    }
                    .disabled(!contentViewModel.disconnectEnabled)
                }
                Section("Wake On LAN") {
                    TextField("TV MAC Address", text: $contentViewModel.tvWakeOnLANDevice.mac)
                    TextField("TV Broadcast Address", text: $contentViewModel.tvWakeOnLANDevice.broadcast)
                    TextField("TV Port", value: $contentViewModel.tvWakeOnLANDevice.port, formatter: NumberFormatter())
                    Button("Wake On LAN") {
                        contentViewModel.userTappedWakeOnLAN()
                    }
                    .disabled(!contentViewModel.wakeOnLANEnabled)
                }
            }
            .navigationBarTitle("TV Controller")
            .alert(isPresented: $isPresentingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(contentViewModel.tvError!.localizedDescription),
                    dismissButton: .default(Text("Dismiss")) {
                        contentViewModel.userTappedDismissError()
                    }
                )
            }
            .onReceive(contentViewModel.$tvError) { newError in
                if newError != nil {
                    isPresentingError = true
                }
            }
        }
    }

    private func authStatusAsText(_ authStatus: TVAuthStatus) -> String {
        switch authStatus {
        case .none: return "None"
        case .allowed: return "Allowed"
        case .denied: return "Denied"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

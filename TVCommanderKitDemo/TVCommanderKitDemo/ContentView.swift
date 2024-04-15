//
//  ContentView.swift
//  TVCommanderKitDemo
//
//  Created by Wilson Desimini on 10/24/23.
//

import SwiftUI
import TVCommanderKit

struct ContentView: View {
    enum Route: Hashable {
        case tv(TV)

        func hash(into hasher: inout Hasher) {
            switch self {
            case .tv(let tv):
                hasher.combine(tv.id)
            }
        }
    }

    @StateObject var contentViewModel = ContentViewModel()
    @State private var isPresentingError = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("Connect / Disconnect TV") {
                    TextField("App Name", text: $contentViewModel.appName)
                    TextField("TV IP Address", text: $contentViewModel.tvIPAddress)
                    if contentViewModel.tvIsConnected {
                        Button("Disconnect", action: contentViewModel.userTappedDisconnect)
                            .disabled(!contentViewModel.disconnectEnabled)
                    } else {
                        Button("Connect", action: contentViewModel.userTappedConnect)
                            .disabled(!contentViewModel.connectEnabled)
                    }
                }
                Section("TV Auth Status") {
                    Text(authStatusAsText(contentViewModel.tvAuthStatus))
                }
                Section("Send TV Key Commands") {
                    Picker("Key Command", selection: $contentViewModel.remoteCommandKeySelected) {
                        ForEach(contentViewModel.remoteCommandKeys, id: \.rawValue) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Button("Send", action: contentViewModel.userTappedSend)
                        .disabled(!contentViewModel.controlsEnabled)
                }
                Section("Enter Text On Keyboard") {
                    Picker(selection: $contentViewModel.keyboardSelected) {
                        ForEach(contentViewModel.keyboards, id: \.self) {
                            Text($0).tag($0)
                        }
                    } label: {
                        TextField("Text", text: $contentViewModel.keyboardEntry)
                    }
                    Button("Send", action: contentViewModel.userTappedKeyboardSend)
                        .disabled(!contentViewModel.keyboardSendEnabled)
                }
                Section("Wake TV On LAN") {
                    TextField("TV MAC Address", text: $contentViewModel.tvWakeOnLANDevice.mac)
                    TextField("TV Broadcast Address", text: $contentViewModel.tvWakeOnLANDevice.broadcast)
                    TextField("TV Port", value: $contentViewModel.tvWakeOnLANDevice.port, formatter: NumberFormatter())
                    Button("Wake On LAN", action: contentViewModel.userTappedWakeOnLAN)
                        .disabled(!contentViewModel.wakeOnLANEnabled)
                }
                Section("Search for TVs") {
                    Button(contentViewModel.isSearchingForTVs ? "Stop" : "Start", action: contentViewModel.userTappedSearchForTVs)
                    List(contentViewModel.tvsFoundInSearch) { tv in
                        Button {
                            path.append(Route.tv(tv))
                        } label: {
                            VStack(alignment: .leading) {
                                Text(tv.name)
                                Text(tv.uri)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("TV Controller")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .tv(let tv):
                    TVView(tv: tv)
                }
            }
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

struct TVView: View {
    @StateObject private var viewModel: TVViewModel

    init(tv: TV) {
        _viewModel = .init(wrappedValue: .init(tv: tv))
    }

    var body: some View {
        Form {
            Section("TV") {
                Text("id: \(viewModel.tv.id)")
                Text("type: \(viewModel.tv.type)")
                Text("uri: \(viewModel.tv.uri)")
            }
            Section("Device") {
                Button("Fetch Device") {
                    viewModel.fetchTVDevice()
                }
                Button("Cancel Fetch") {
                    viewModel.cancelFetch()
                }
                if let device = viewModel.tv.device {
                    Text("powerState: \(device.powerState ?? "")")
                    Text("tokenAuthSupport: \(device.tokenAuthSupport)")
                    Text("wifiMac: \(device.wifiMac)")
                }
            }
        }
        .navigationTitle(viewModel.tv.name)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

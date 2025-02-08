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

    @State private var contentViewModel = ContentViewModel()
    @State private var isPresentingError = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("Connect / Disconnect TV") {
                    TextField("App Name", text: $contentViewModel.appName)
                    TextField("TV IP Address", text: $contentViewModel.tvIPAddress)
                    if let tvAuthTokenBinding = tvAuthTokenBinding {
                        HStack {
                            TextField("Auth Token", text: tvAuthTokenBinding)
                            Button("Remove") {
                                contentViewModel.tvAuthToken = nil
                            }
                        }
                        .disabled(contentViewModel.authTokenEntryDisabled)
                    } else {
                        Button("Add Auth Token") {
                            contentViewModel.tvAuthToken = ""
                        }
                        .disabled(contentViewModel.authTokenEntryDisabled)
                    }
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
                Section("Send Text") {
                    TextField("Text", text: $contentViewModel.keyboardEntry)
                    Button("Send via Direct Input", action: contentViewModel.userTappedSendTextInput)
                        .disabled(!contentViewModel.keyboardSendEnabled)
                    Picker(selection: $contentViewModel.keyboardSelected) {
                        ForEach(contentViewModel.keyboards, id: \.self) {
                            Text($0).tag($0)
                        }
                    } label: {
                        Button("Send via Keyboard Entry", action: contentViewModel.userTappedKeyboardSend)
                            .disabled(!contentViewModel.keyboardSendEnabled)
                    }
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
                Section("Installed Apps") {
                    Picker("Selected TV App", selection: $contentViewModel.tvApp) {
                        ForEach(contentViewModel.tvApps) { app in
                            Text(app.name).tag(app)
                        }
                    }
                    Button("Status") {
                        contentViewModel.userTappedAppStatus()
                    }
                    Button("Launch") {
                        contentViewModel.userTappedLaunchApp()
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
            .sheet(
                item: $contentViewModel.tvAppStatus,
                content: TVAppStatusView.init
            )
            .alert(isPresented: $isPresentingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(contentViewModel.tvError!.localizedDescription),
                    dismissButton: .default(Text("Dismiss")) {
                        contentViewModel.userTappedDismissError()
                    }
                )
            }
            .onReceive(contentViewModel.tvError.publisher) { _ in
                isPresentingError = true
            }
        }
    }

    private var tvAuthTokenBinding: Binding<TVAuthToken>? {
        guard let tvAuthToken = contentViewModel.tvAuthToken else {
            return nil
        }
        return Binding(
            get: { tvAuthToken },
            set: { contentViewModel.tvAuthToken = $0 }
        )
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
    @State private var viewModel: TVViewModel

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

struct TVAppStatusView: View {
    let status: TVAppStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Text("ID: \(status.id)")
                Text("Running: \(status.running ? "Yes" : "No")")
                Text("Version: \(status.version)")
                Text("Visible: \(status.visible ? "Yes" : "No")")
            }
            .navigationTitle(status.name)
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

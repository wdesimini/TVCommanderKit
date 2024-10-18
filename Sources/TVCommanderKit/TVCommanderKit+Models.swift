//
//  TVCommanderKit+Models.swift
//  
//
//  Created by Wilson Desimini on 9/3/23.
//

import Foundation

/// Represents a TV discovered in a search
public struct TV: Codable, Identifiable, Equatable {
    /// Represents detailed device information for a TV
    public struct Device: Codable, Equatable {
        public let countryCode: String?
        public let deviceDescription: String?
        public let developerIp: String?
        public let developerMode: String?
        public let duid: String?
        public let firmwareVersion: String?
        public let frameTvSupport: String?
        public let gamePadSupport: String?
        /// Unique identifier for the device, often the same as the TV id
        public let id: String?
        public let imeSyncedSupport: String?
        /// IP address of the TV on the network
        public let ip: String?
        public let language: String?
        public let model: String?
        public let modelName: String?
        public let name: String?
        public let networkType: String?
        public let os: String?
        /// Current power state of the TV, e.g., "on", "off", "standby"
        public let powerState: String?
        public let resolution: String?
        public let smartHubAgreement: String?
        public let ssid: String?
        /// Indicates whether the TV supports token-based authorization
        public let tokenAuthSupport: String
        public let type: String?
        public let udn: String?
        public let voiceSupport: String?
        public let wallScreenRatio: String?
        public let wallService: String?
        /// MAC address of the TV's Wi-Fi connection
        public let wifiMac: String

        public init(
            countryCode: String? = nil,
            deviceDescription: String? = nil,
            developerIp: String? = nil,
            developerMode: String? = nil,
            duid: String? = nil,
            firmwareVersion: String? = nil,
            frameTvSupport: String? = nil,
            gamePadSupport: String? = nil,
            id: String? = nil,
            imeSyncedSupport: String? = nil,
            ip: String? = nil,
            language: String? = nil,
            model: String? = nil,
            modelName: String? = nil,
            name: String? = nil,
            networkType: String? = nil,
            os: String? = nil,
            powerState: String? = nil,
            resolution: String? = nil,
            smartHubAgreement: String? = nil,
            ssid: String? = nil,
            tokenAuthSupport: String,
            type: String? = nil,
            udn: String? = nil,
            voiceSupport: String? = nil,
            wallScreenRatio: String? = nil,
            wallService: String? = nil,
            wifiMac: String
        ) {
            self.countryCode = countryCode
            self.deviceDescription = deviceDescription
            self.developerIp = developerIp
            self.developerMode = developerMode
            self.duid = duid
            self.firmwareVersion = firmwareVersion
            self.frameTvSupport = frameTvSupport
            self.gamePadSupport = gamePadSupport
            self.id = id
            self.imeSyncedSupport = imeSyncedSupport
            self.ip = ip
            self.language = language
            self.model = model
            self.modelName = modelName
            self.name = name
            self.networkType = networkType
            self.os = os
            self.powerState = powerState
            self.resolution = resolution
            self.smartHubAgreement = smartHubAgreement
            self.ssid = ssid
            self.tokenAuthSupport = tokenAuthSupport
            self.type = type
            self.udn = udn
            self.voiceSupport = voiceSupport
            self.wallScreenRatio = wallScreenRatio
            self.wallService = wallService
            self.wifiMac = wifiMac
        }

        enum CodingKeys: String, CodingKey {
            case countryCode
            case deviceDescription = "description"
            case developerIp = "developerIP"
            case developerMode
            case duid
            case firmwareVersion
            case frameTvSupport = "FrameTVSupport"
            case gamePadSupport = "GamePadSupport"
            case id
            case imeSyncedSupport = "ImeSyncedSupport"
            case ip
            case language = "Language"
            case model
            case modelName
            case name
            case networkType
            case os = "OS"
            case powerState = "PowerState"
            case resolution
            case smartHubAgreement
            case ssid
            case tokenAuthSupport = "TokenAuthSupport"
            case type
            case udn
            case voiceSupport = "VoiceSupport"
            case wallScreenRatio = "WallScreenRatio"
            case wallService = "WallService"
            case wifiMac
        }
    }

    /// Detailed information about the TV
    public let device: Device?
    /// Unique identifier for the TV
    public let id: String
    public let isSupport: String?
    /// User-friendly name of the TV
    public let name: String
    public let remote: String?
    public let type: String
    /// URI used to query the TV via HTTP
    public let uri: String
    public let version: String?

    public init(
        device: Device? = nil,
        id: String,
        isSupport: String? = nil,
        name: String,
        remote: String? = nil,
        type: String,
        uri: String,
        version: String? = nil
    ) {
        self.device = device
        self.id = id
        self.isSupport = isSupport
        self.name = name
        self.remote = remote
        self.type = type
        self.uri = uri
        self.version = version
    }
}

public enum TVAuthStatus {
    /// Client hasn't completed authorization with TV
    case none
    /// Client is authorized to command TV
    case allowed
    /// Client is denied authorization to command TV
    case denied
}

public typealias TVAuthToken = String

public struct TVConnectionConfiguration {
    public let id: String?
    public let app: String
    public let path: String
    public let ipAddress: String
    public let port: Int
    public let scheme: String
    public var token: TVAuthToken?

    public init(id: String?, app: String, path: String, ipAddress: String, port: Int, scheme: String, token: TVAuthToken?) {
        self.id = id
        self.app = app
        self.path = path
        self.ipAddress = ipAddress
        self.port = port
        self.scheme = scheme
        self.token = token
    }
}

/// Defines the overall command to be sent to the TV
public struct TVRemoteCommand: Codable {
    public enum Method: String, Codable {
        case control = "ms.remote.control"
    }

    /// Contains the specific parameters for a remote command
    public struct Params: Codable {
        public enum Command: String, Codable {
            case click = "Click"
        }

        /// Enum representing the keys on a TV's remote control
        public enum ControlKey: String, Codable {
            case powerOff = "KEY_POWEROFF"
            case up = "KEY_UP"
            case down = "KEY_DOWN"
            case left = "KEY_LEFT"
            case right = "KEY_RIGHT"
            case enter = "KEY_ENTER"
            case returnKey = "KEY_RETURN"
            case channelList = "KEY_CH_LIST"
            case menu = "KEY_MENU"
            case source = "KEY_SOURCE"
            case guide = "KEY_GUIDE"
            case tools = "KEY_TOOLS"
            case info = "KEY_INFO"
            case colorRed = "KEY_RED"
            case colorGreen = "KEY_GREEN"
            case colorYellow = "KEY_YELLOW"
            case colorBlue = "KEY_BLUE"
            case key3D = "KEY_PANNEL_CHDOWN"
            case volumeUp = "KEY_VOLUP"
            case volumeDown = "KEY_VOLDOWN"
            case mute = "KEY_MUTE"
            case number0 = "KEY_0"
            case number1 = "KEY_1"
            case number2 = "KEY_2"
            case number3 = "KEY_3"
            case number4 = "KEY_4"
            case number5 = "KEY_5"
            case number6 = "KEY_6"
            case number7 = "KEY_7"
            case number8 = "KEY_8"
            case number9 = "KEY_9"
            case sourceTV = "KEY_DTV"
            case sourceHDMI = "KEY_HDMI"
            case contents = "KEY_CONTENTS"
        }

        public enum ControlType: String, Codable {
            case inputEnd = "SendInputEnd"
            case inputString = "SendInputString"
            case mouseDevice = "ProcessMouseDevice"
            case remoteKey = "SendRemoteKey"
        }

        /// Command to be executed, e.g., "Click"
        public let cmd: Command
        /// Specific key data associated with the command
        public let dataOfCmd: ControlKey
        /// Additional option that may modify the command's execution
        public let option: Bool
        /// Type of the remote control that the command applies to, e.g., "SendRemoteKey"
        public let typeOfRemote: ControlType

        enum CodingKeys: String, CodingKey {
            case cmd = "Cmd"
            case dataOfCmd = "DataOfCmd"
            case option = "Option"
            case typeOfRemote = "TypeOfRemote"
        }

        public init(cmd: Command, dataOfCmd: ControlKey, option: Bool, typeOfRemote: ControlType) {
            self.cmd = cmd
            self.dataOfCmd = dataOfCmd
            self.option = option
            self.typeOfRemote = typeOfRemote
        }
    }

    /// The type of method performed via the WebSocket
    public let method: Method
    /// An object containing parameters needed to execute the command
    public let params: Params

    public init(method: Method, params: Params) {
        self.method = method
        self.params = params
    }
}

public struct TVResponse<Body: Codable>: Codable {
    public let data: Body?
    public let event: TVChannelEvent
}

public typealias TVAuthResponse = TVResponse<TVAuthResponseBody>

/// Data payload associated with a TVAuthResponse
public struct TVAuthResponseBody: Codable {
    /// List of clients connected to the TV
    public let clients: [TVClient]
    /// Identifier associated with an authorized connection
    public let id: String
    /// New token passed back with an authorized connection
    public let token: TVAuthToken?
}

public enum TVChannelEvent: String, Codable {
    case connect = "ms.channel.connect"
    case disconnect = "ms.channel.disconnect"
    case clientConnect = "ms.channel.clientConnect"
    case clientDisconnect = "ms.channel.clientDisconnect"
    case data = "ms.channel.data"
    case error = "ms.channel.error"
    case message = "ms.channel.message"
    case ping = "ms.channel.ping"
    case ready = "ms.channel.ready"
    case timeout = "ms.channel.timeOut"
    case unauthorized = "ms.channel.unauthorized"
}

/// Represents a client connected to the TV
public struct TVClient: Codable, Identifiable {
    /// Attributes of a client connected to the TV
    public struct Attributes: Codable {
        /// Name of the client (encoded in Base64)
        public let name: String?
        /// Refreshed token associated with the client
        public let token: TVAuthToken?

        public init(name: String?, token: TVAuthToken?) {
            self.name = name
            self.token = token
        }
    }

    /// Attributes of the client
    public let attributes: Attributes
    /// Timestamp when the client connected
    public let connectTime: Int
    /// Name of the device (encoded in Base64)
    public let deviceName: String
    /// Unique identifier of the client's authorized connection
    public let id: String
    /// Indicates whether the client is the host or not
    public let isHost: Bool

    public init(attributes: Attributes, connectTime: Int, deviceName: String, id: String, isHost: Bool) {
        self.attributes = attributes
        self.connectTime = connectTime
        self.deviceName = deviceName
        self.id = id
        self.isHost = isHost
    }
}

public typealias TVKeyboardLayout = [[String]]

public struct TVWakeOnLANDevice {
    public var mac: String
    public var broadcast: String
    public var port: UInt16

    public init(mac: String, broadcast: String = "255.255.255.255", port: UInt16 = 9) {
        self.mac = mac
        self.broadcast = broadcast
        self.port = port
    }

    public init(device: TV.Device, broadcast: String = "255.255.255.255", port: UInt16 = 9) {
        self.init(mac: device.wifiMac, broadcast: broadcast, port: port)
    }
}

public struct TVApp: Identifiable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TVAppStatus: Codable, Identifiable {
    public let id: String
    public let name: String
    public let running: Bool
    public let version: String
    public let visible: Bool

    public init(id: String, name: String, running: Bool, version: String, visible: Bool) {
        self.id = id
        self.name = name
        self.running = running
        self.version = version
        self.visible = visible
    }
}

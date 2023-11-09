//
//  TVCommanderKit+Models.swift
//  
//
//  Created by Wilson Desimini on 9/3/23.
//

import Foundation

public enum TVAuthStatus {
    case none, allowed, denied
}

public typealias TVAuthToken = String

public struct TVConnectionConfiguration {
    public let app: String
    public let path: String
    public let ipAddress: String
    public let port: Int
    public let scheme: String
    public var token: TVAuthToken?

    public init(app: String, path: String, ipAddress: String, port: Int, scheme: String, token: TVAuthToken?) {
        self.app = app
        self.path = path
        self.ipAddress = ipAddress
        self.port = port
        self.scheme = scheme
        self.token = token
    }
}

public struct TVRemoteCommand: Codable {
    public enum Method: String, Codable {
        case control = "ms.remote.control"
    }

    public struct Params: Codable {
        public enum Command: String, Codable {
            case click = "Click"
        }

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

        public let cmd: Command
        public let dataOfCmd: ControlKey
        public let option: Bool
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

    public let method: Method
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

public struct TVAuthResponseBody: Codable {
    public let clients: [TVClient]
    public let id: String
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

public struct TVClient: Codable, Identifiable {
    public struct Attributes: Codable {
        public let name: String?
        public let token: TVAuthToken?

        public init(name: String?, token: TVAuthToken?) {
            self.name = name
            self.token = token
        }
    }

    public let attributes: Attributes
    public let connectTime: Int
    public let deviceName: String
    public let id: String
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

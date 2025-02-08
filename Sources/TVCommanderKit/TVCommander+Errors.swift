//
//  TVCommander+Errors.swift
//  
//
//  Created by Wilson Desimini on 9/4/23.
//

import Foundation

public enum TVCommanderError: LocalizedError {
    // invalid app name
    case invalidAppNameEntered
    // invalid ip address
    case invalidIPAddressEntered
    // trying to connect, but the connection is already established.
    case connectionAlreadyEstablished
    // the URL could not be constructed.
    case urlConstructionFailed
    // WebSocket receives an error.
    case webSocketError(Error?)
    // parsing for packet data fails.
    case packetDataParsingFailed
    // response for authentication contains unexpected event
    case authResponseUnexpectedChannelEvent(TVAuthResponse)
    // no token is found inside an allowed authentication response.
    case noTokenInAuthResponse(TVAuthResponse)
    // trying to send a command without being connected to a TV
    case remoteCommandNotConnectedToTV
    // trying to send a command when authentication status is not allowed.
    case remoteCommandAuthenticationStatusNotAllowed
    // command conversion to a string fails.
    case commandConversionToStringFailed
    // invalid input to keyboard navigation
    case keyboardCharNotFound(String)
    // wake on LAN connection error
    case wakeOnLANConnectionError(Error)
    // wake on LAN content processing error
    case wakeOnLANProcessingError(Error)
    // an unknown error occurs.
    case unknownError(Error?)

    public var errorDescription: String? {
        switch self {
        case .invalidAppNameEntered:
            "Invalid App Name Entered"
        case .invalidIPAddressEntered:
            "Invalid IP Address Entered"
        case .connectionAlreadyEstablished:
            "Connection Already Established"
        case .urlConstructionFailed:
            "URL Construction Failed"
        case .webSocketError(let error):
            "WebSocket Error: \(String(describing: error))"
        case .packetDataParsingFailed:
            "Packet Data Parsing Failed"
        case .authResponseUnexpectedChannelEvent(let authResponse):
            "Auth Response Unexpected Channel Event: \(authResponse)"
        case .noTokenInAuthResponse(let authResponse):
            "No Token In Auth Response: \(authResponse)"
        case .remoteCommandNotConnectedToTV:
            "Remote Command Not Connected To TV"
        case .remoteCommandAuthenticationStatusNotAllowed:
            "Remote Command Authentication Status Not Allowed"
        case .commandConversionToStringFailed:
            "Command Conversion To String Failed"
        case .keyboardCharNotFound(let char):
            "Keyboard Char Not Found: \(char)"
        case .wakeOnLANConnectionError(let error):
            "Wake On LAN Connection Error: \(error.localizedDescription)"
        case .wakeOnLANProcessingError(let error):
            "Wake On LAN Processing Error: \(error.localizedDescription)"
        case .unknownError(let error):
            "Unknown Error: \(error?.localizedDescription ?? "")"
        }
    }
}

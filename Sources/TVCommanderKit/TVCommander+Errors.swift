//
//  TVCommander+Errors.swift
//  
//
//  Created by Wilson Desimini on 9/4/23.
//

import Foundation

public enum TVCommanderError: Error {
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
}

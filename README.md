# TVCommanderKit

**TVCommanderKit** is a Swift SDK for controlling Samsung Smart TVs over a WebSocket connection. It provides a simple and convenient way to interact with your TV and send remote control commands from your iOS application. This README.md file will guide you through using the TVCommanderKit SDK in your project.

## Table of Contents
- [Usage](#usage)
- [Delegate Methods](#delegate-methods)
- [Establishing Connection](#establishing-connection)
- [Authorizing Application with TV](#authorizing-application-with-tv)
- [Sending Remote Control Commands](#sending-remote-control-commands)
- [Disconnecting from TV](#disconnecting-from-tv)
- [Error Handling](#error-handling)

## Usage

1. Import the TVCommanderKit module:

```swift
import TVCommanderKit
```

2. Initialize a `TVCommander` object with your TV's IP address and application name:

```swift
let tvCommander = TVCommander(tvIPAddress: "your_tv_ip_address", appName: "your_app_name")
```

3. Implement the necessary delegate methods to receive updates and handle events (see [Delegate Methods](#delegate-methods)), then set your delegate to receive updates and events from the TVCommander:

```swift
tvCommander.delegate = self
```

4. Connect to your TV (see [Establishing Connection](#establishing-connection) for further details):

```swift
tvCommander.connectToTV()
```

5. Handle incoming authorization steps to authorize your app to send remote controls (see [Authorizing Application with TV](#authorizing-application-with-tv)).

6. Send remote control commands (see [Sending Remote Control Commands](#sending-remote-control-commands)).

7. Disconnect from your TV when done:

```swift
tvCommander.disconnectFromTV()
```

## Delegate Methods

The TVCommanderDelegate protocol provides methods to receive updates and events from the TVCommander SDK:

- `tvCommanderDidConnect(_ tvCommander: TVCommander)`: Called when the TVCommander successfully connects to the TV.

- `tvCommanderDidDisconnect(_ tvCommander: TVCommander)`: Called when the TVCommander disconnects from the TV.

- `tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus)`: Called when the authorization status is updated.

- `tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand)`: Called when a remote control command is sent to the TV.

- `tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError)`: Called when the TVCommander encounters an error.

## Establishing Connection

To establish a connection to your TV, use the `connectToTV()` method. This method will create a WebSocket connection to your TV with the provided IP address and application name. If a connection is already established, it will handle the error gracefully.

```swift
tvCommander.connectToTV()
```

## Authorizing Application with TV

After establishing a connection to the TV, you'll need to authorize your app for sending remote controls. If your TV hasn't already handled your application's authorization, a prompt should appear on your TV for you to choose an authorization option.

## Sending Remote Control Commands

You can send remote control commands to your TV using the `sendRemoteCommand(key:)` method. Ensure that you are connected to the TV and the authorization status is allowed before sending commands.

```swift
tvCommander.sendRemoteCommand(key: .enter)
```

## Disconnecting from TV

When you're done with the TVCommander, disconnect from your TV using the `disconnectFromTV()` method:

```swift
tvCommander.disconnectFromTV()
```

## Error Handling

The TVCommander SDK includes error handling for various scenarios, and errors are reported through the delegate method `tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError)`. You should implement this method to handle errors appropriately.

---

Feel free to contribute to this SDK, report issues, or provide feedback. I hope you find TVCommanderKit useful in building your Samsung Smart TV applications!

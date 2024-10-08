// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TVCommanderKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TVCommanderKit",
            targets: ["TVCommanderKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/daltoniam/Starscream.git", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TVCommanderKit",
            dependencies: ["SmartView", "Starscream"]),
        .binaryTarget(
            name: "SmartView",
            path: "SmartView.xcframework"),
        .testTarget(
            name: "TVCommanderKitTests",
            dependencies: ["TVCommanderKit"]),
    ]
)

// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PusherChatkit",
    platforms: [.iOS(.v10)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PusherChatkit",
            targets: ["PusherChatkit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/jjatie/pusher-platform-swift", from: "0.7.2"),
        .package(url: "https://github.com/jjatie/push-notifications-swift", from: "2.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PusherChatkit",
            dependencies: ["PusherPlatform", "PushNotifications"],
            path: "Sources"),
//        .testTarget(
//            name: "PusherChatkitTests",
//            dependencies: ["PusherChatkit"],
//            path: "Tests"),
    ]
)

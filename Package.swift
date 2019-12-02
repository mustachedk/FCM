// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FCM",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        //Vapor client for Firebase Cloud Messaging
        .library(name: "FCM", targets: ["FCM"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0-alpha.1.3"),
    ],
    targets: [
        .target(name: "FCM", dependencies: ["Vapor", "JWTKit"]),
        //.testTarget(name: "FCMTests", dependencies: ["FCM"]),
    ]
)

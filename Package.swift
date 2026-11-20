// swift-tools-version: 5.9
//
// VoiceTel Swift SDK
// Copyright (c) 2026 VoiceTel Communications
//
// The official Swift client for the VoiceTel REST API v2.2.21.

import PackageDescription

let package = Package(
    name: "VoiceTel",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "VoiceTel",
            targets: ["VoiceTel"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VoiceTel",
            dependencies: [],
            path: "Sources/VoiceTel"
        ),
        .testTarget(
            name: "VoiceTelTests",
            dependencies: ["VoiceTel"],
            path: "Tests/VoiceTelTests"
        )
    ]
)

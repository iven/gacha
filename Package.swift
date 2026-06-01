// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Gacha",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(
      name: "Gacha",
      targets: ["Gacha"]
    ),
    .executable(
      name: "gacha-cli",
      targets: ["GachaCLI"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.10.0"),
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
    .package(url: "https://github.com/MrKai77/DynamicNotchKit.git", from: "1.1.0"),
    .package(
      url: "https://github.com/open-spaced-repetition/swift-fsrs.git",
      revision: "4fbaf20184d62f82a9f44f343337c61a2c5483e9"
    ),
    .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.1"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
  ],
  targets: [
    .executableTarget(
      name: "Gacha",
      dependencies: [
        .product(name: "DynamicNotchKit", package: "DynamicNotchKit"),
        .product(name: "FSRS", package: "swift-fsrs"),
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "MCP", package: "swift-sdk"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        "Yams",
      ],
      path: "Sources/Gacha",
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "GachaTests",
      dependencies: [
        "Gacha",
        .product(name: "GRDB", package: "GRDB.swift"),
      ],
      path: "Tests/GachaTests"
    ),
    .executableTarget(
      name: "GachaCLI",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      path: "Sources/GachaCLI",
      resources: [
        .process("Resources")
      ]
    ),
  ]
)

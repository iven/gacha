// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Gacha",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "Gacha",
      targets: ["Gacha"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.10.0"),
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "Gacha",
      dependencies: [
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "Markdown", package: "swift-markdown"),
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
  ]
)

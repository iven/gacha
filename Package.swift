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
  targets: [
    .executableTarget(
      name: "Gacha",
      path: "Sources/Gacha",
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "GachaTests",
      dependencies: ["Gacha"],
      path: "Tests/GachaTests"
    ),
  ]
)

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
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1")
  ],
  targets: [
    .executableTarget(
      name: "Gacha",
      dependencies: ["Yams"],
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

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftUIFX",
    platforms: [.macOS(.v11)],
    products: [.library(name: "SwiftUIFX", type: .dynamic, targets: ["SwiftUIFX"])],
    targets: [.target(name: "SwiftUIFX")]
)

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HelloWorld",
    platforms: [.macOS(.v13)],
    products: [.library(name: "HelloWorld", type: .dynamic, targets: ["HelloWorld"])],
    dependencies: [.package(url: "https://github.com/finnvoor/SwiftUIFX.git", branch: "main")],
    targets: [.target(name: "HelloWorld", dependencies: [.product(name: "SwiftUIFX", package: "SwiftUIFX")])]
)

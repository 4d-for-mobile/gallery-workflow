// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gallery-workflow",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .executable(name: "gallery-workflow", targets: ["gallery-workflow"]),
        .library(name: "GalleryWorkflowKit", targets: ["GalleryWorkflowKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/nvzqz/FileKit.git", from: "6.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/Carthage/Commandant.git", .upToNextMinor(from: "0.16.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMinor(from: "2.0.0")),
        .package(url: "https://github.com/weichsel/ZIPFoundation/", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: "GalleryWorkflowKit",
            dependencies: ["FileKit", "SwiftyJSON", "Commandant", "Yams", "ZIPFoundation"]),
        .target(
            name: "gallery-workflow",
            dependencies: ["GalleryWorkflowKit"])
    ]
)

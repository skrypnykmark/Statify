// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Statify",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Statify",
            path: "Sources/Statify"
        )
    ]
)

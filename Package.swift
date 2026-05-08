// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "yomp3",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "yomp3",
            path: "Sources/yomp3"
        ),
    ]
)

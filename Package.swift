// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AudioPilote",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AudioPilote",
            path: "Sources/AudioPilote"
        )
    ]
)

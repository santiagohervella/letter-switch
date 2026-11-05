// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LetterSwitch",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "LetterSwitch",
            path: "Sources/LetterSwitch",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

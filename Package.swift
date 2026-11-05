// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LetterSwitch",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "LetterSwitch",
            dependencies: ["Yams"],
            path: "Sources/LetterSwitch",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.unsafeFlags(["-F/System/Library/PrivateFrameworks", "-framework", "SkyLight"])]
        ),
    ]
)

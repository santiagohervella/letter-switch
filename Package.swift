// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LetterSwitch",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "LetterSwitch",
            dependencies: ["TOMLKit"],
            path: "Sources/LetterSwitch",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.unsafeFlags(["-F/System/Library/PrivateFrameworks", "-framework", "SkyLight"])]
        ),
    ]
)

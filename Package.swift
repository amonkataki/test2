// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnDeviceAI",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/ggerganov/llama.cpp", exact: "4878")
    ],
    targets: [
        .executableTarget(
            name: "OnDeviceAI",
            dependencies: [
                .product(name: "llama", package: "llama.cpp")
            ],
            path: "OnDeviceAI"
        )
    ]
)

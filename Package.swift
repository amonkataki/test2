// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalLLM",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        // llama.cpp Swift bindings
        .package(url: "https://github.com/ggerganov/llama.cpp", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "LocalLLM",
            dependencies: [
                .product(name: "llama", package: "llama.cpp")
            ],
            path: "LocalLLM"
        )
    ]
)

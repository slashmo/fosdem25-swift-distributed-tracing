// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "recommendation",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "recommendationctl", targets: ["CTL"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.3"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.7.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.2.0"),
        .package(url: "https://github.com/swift-otel/swift-otel.git", branch: "main"),
        .package(url: "https://github.com/slashmo/async-http-client.git", branch: "feature/tracing"),
    ],
    targets: [
        .executableTarget(
            name: "CTL",
            dependencies: [
                .target(name: "API"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Instrumentation", package: "swift-distributed-tracing"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OTLPGRPC", package: "swift-otel"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .target(
            name: "API",
            dependencies: [
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

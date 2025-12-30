// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "HTTPClient",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "HTTPClient",
            targets: ["HTTPClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "HTTPClient",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
            ]
        ),
        .testTarget(
            name: "HTTPClientTests",
            dependencies: ["HTTPClient"]
        ),
    ]
)

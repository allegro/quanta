// swift-tools-version:4.2

import PackageDescription

let package = Package(
        name: "quanta",

        products: [
            .executable(name: "quanta", targets: ["Run"]),
            .library(name: "CMozJpeg", type: .static, targets: ["CMozJpeg"]),
            .library(name: "Quanta", targets: ["Quanta"]),
        ],
        dependencies: [
            .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
            .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
            .package(url: "https://github.com/allegro/swiftbox", from: "1.0.0"),
            .package(url: "https://github.com/allegro/swift-junit.git", from: "1.0.0"),
        ],

        targets: [
            .target(
                    name: "CMozJpeg",
                    path: "./Sources/CMozJpeg/",
                    sources: ["."],
                    publicHeadersPath: "./includes"
            ),

            .target(name: "Quanta",
                    dependencies: [
                        "CMozJpeg",
                        "Vapor",
                        "Leaf",
                        "SwiftBoxLogging",
                        "SwiftBoxMetrics",
                        "SwiftBoxConfig"
                    ],
                    exclude: [
                        "Config",
                        "Database",
                        "Public",
                        "Resources",
                    ]
            ),
            .target(
                    name: "Run",
                    dependencies: ["Quanta"]
            ),

            .testTarget(
                    name: "QuantaTests",
                    dependencies: [
                        "Quanta",
                        "SwiftTestReporter",
                    ]
            ),
        ]
)

// swift-tools-version:5.9

import PackageDescription

#if os(macOS)
let mozjpegLibPath = "/opt/homebrew/opt/mozjpeg/lib"
let mozjpegIncludePath = "/opt/homebrew/opt/mozjpeg/include"
#else
let mozjpegLibPath = "/opt/mozjpeg/lib64"
let mozjpegIncludePath = "/opt/mozjpeg/include"
#endif

let package = Package(
    name: "quanta",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "quanta", targets: ["Run"]),
        .library(name: "CMozJpeg", type: .static, targets: ["CMozJpeg"]),
        .library(name: "Quanta", targets: ["Quanta"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.5.0"),
        .package(url: "https://github.com/allegro/swiftbox", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "CMozJpeg",
            path: "./Sources/CMozJpeg/",
            sources: [".", "includes"],
            publicHeadersPath: "./includes",
            cSettings: [
                .define("NDEBUG"),
                .headerSearchPath("includes"),
                .unsafeFlags([
                    "-I\(mozjpegIncludePath)",
                    "-Wno-implicit-function-declaration",
                    "-Wno-incompatible-pointer-types-discards-qualifiers",
                    "-Wno-return-type",
                ]),
            ]
        ),

        .target(
            name: "Quanta",
            dependencies: [
                "CMozJpeg",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "SwiftBoxLogging", package: "swiftbox"),
                .product(name: "SwiftBoxMetrics", package: "swiftbox"),
                .product(name: "SwiftBoxConfig", package: "swiftbox"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("jpeg"),
                .linkedLibrary("turbojpeg"),
                .unsafeFlags(["-L\(mozjpegLibPath)"]),
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: ["Quanta"]
        ),

        .testTarget(
            name: "QuantaTests",
            dependencies: [
                "Quanta",
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)

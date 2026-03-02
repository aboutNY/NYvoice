// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "NYvoice",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NYvoiceApp", targets: ["NYvoiceApp"])
    ],
    targets: [
        .executableTarget(
            name: "NYvoiceApp",
            path: "app/NYvoiceApp",
            exclude: ["Resources/Info.plist"],
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "NYvoiceAppTests",
            dependencies: ["NYvoiceApp"],
            path: "tests"
        )
    ]
)

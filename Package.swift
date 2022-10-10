// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "checked",
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "CheckedScanner"
        ),
        .target(
            name: "parser",
            dependencies: [
                "CheckedScanner",
            ]
        ),
        .executableTarget(
            name: "checked",
            dependencies: [
                "CheckedScanner",
                "parser",
            ]
        ),
    ]
)
